import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/config/app_config.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/sync/local_sync_notifier.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/cash_session_close_payload.dart';
import '../../../data/services/cash_session_http.dart';
import '../../../data/services/cash_session_start_payload.dart';
import '../../../data/services/ticket_service.dart';
import '../../../data/services/ticket_sync_payload.dart';
import '../domain/pending_sync_item.dart';
import 'sync_state.dart';

class _SyncHop {
  const _SyncHop(this.method, this.url, this.body);
  final String method;
  final String url;
  final Object? body;
}

class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required AppDatabase database,
    required Dio dio,
    required AuthRepository authRepository,
    required TicketService ticketService,
    LocalSyncNotifier? localSyncNotifier,
  })  : _db = database,
        _dio = dio,
        _auth = authRepository,
        _ticketService = ticketService,
        _localSyncNotifier = localSyncNotifier,
        super(const SyncIdle());

  final AppDatabase _db;
  final Dio _dio;
  final AuthRepository _auth;
  final TicketService _ticketService;
  final LocalSyncNotifier? _localSyncNotifier;

  void _notifyLocalSyncQueueChanged() {
    _localSyncNotifier?.notifyLocalQueueChanged();
  }

  Future<int> pendingCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'pending'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    final queuePending = (row.data['c'] as num?)?.toInt() ?? 0;
    final orphans = await _ticketService.countOrphanPendingTickets();
    return queuePending + orphans;
  }

  Future<int> failedCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'failed'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Pending + failed queue rows and orphan tickets for the settings unsynced list.
  Future<List<PendingSyncItem>> listUnsyncedItems() async {
    final rows = await (_db.select(_db.syncQueue)
          ..where((q) => q.syncStatus.isIn(['pending', 'failed']))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();

    final items = <PendingSyncItem>[];
    for (final row in rows) {
      Ticket? ticket;
      Shift? shift;
      if (row.queueTableName == 'tickets') {
        ticket = await (_db.select(_db.tickets)
              ..where((t) => t.id.equals(row.recordId)))
            .getSingleOrNull();
      } else if (row.queueTableName == 'shifts') {
        shift = await (_db.select(_db.shifts)
              ..where((s) => s.id.equals(row.recordId)))
            .getSingleOrNull();
      }
      items.add(
        PendingSyncItem.fromQueueRow(row, ticket: ticket, shift: shift),
      );
    }

    final orphanRows = await _db.customSelect(
      '''
SELECT t.id FROM tickets t
WHERE t.sync_status = 'pending'
  AND t.status != 'draft'
  AND t.id NOT IN (
    SELECT q.record_id FROM sync_queue q
    WHERE q.table_name = 'tickets'
      AND q.sync_status IN ('pending', 'failed')
  )
ORDER BY t.check_in_at ASC
''',
      readsFrom: {_db.tickets, _db.syncQueue},
    ).get();

    for (final row in orphanRows) {
      final tid = row.read<String>('id');
      final ticket = await (_db.select(_db.tickets)
            ..where((t) => t.id.equals(tid)))
          .getSingleOrNull();
      if (ticket != null) {
        items.add(PendingSyncItem.fromOrphanTicket(ticket));
      }
    }

    return items;
  }

  Future<void> retryFailed() async {
    await _db.customStatement(
      "UPDATE sync_queue SET sync_status = 'pending', retry_count = 0 "
      "WHERE sync_status = 'failed'",
    );
    await flush();
  }

  /// Marks queue rows `synced` when their shift/ticket entity is already synced
  /// (e.g. direct HTTP path updated the entity but left the queue row pending).
  /// Checkout uploads are excluded — a synced check-in does not mean checkout
  /// reached the server.
  Future<void> _reconcileOrphanQueueEntries() async {
    await _db.customStatement(
      '''
UPDATE sync_queue
SET sync_status = 'synced'
WHERE sync_status IN ('pending', 'failed')
  AND operation != 'checkout/finalize'
  AND (
    (table_name = 'tickets' AND record_id IN (
      SELECT id FROM tickets WHERE sync_status = 'synced'
    ))
    OR (table_name = 'shifts' AND record_id IN (
      SELECT id FROM shifts WHERE sync_status = 'synced'
    ))
  )
''',
    );
    await _reconcileResumedShiftCreates();
  }

  /// Stub-only: marks pending tickets with `server_ticket_id` without HTTP.
  Future<void> _reconcileServerBackedTicketsStub() async {
    await _db.customStatement(
      '''
UPDATE tickets
SET sync_status = 'synced'
WHERE sync_status = 'pending'
  AND server_ticket_id IS NOT NULL
  AND TRIM(server_ticket_id) != ''
''',
    );
  }

  /// Clears stale shift-create queue rows after cache clear + login resume
  /// (`applyServerOpenCashFlag` used opening_float = 0 before [resumeServerSession]).
  Future<void> _reconcileResumedShiftCreates() async {
    await _db.customStatement(
      '''
UPDATE shifts
SET sync_status = 'synced'
WHERE status = 'open'
  AND opening_float = 0
  AND sync_status = 'pending'
  AND id IN (
    SELECT record_id FROM sync_queue
    WHERE table_name = 'shifts'
      AND operation = 'create'
      AND sync_status IN ('pending', 'failed')
  )
''',
    );
    await _db.customStatement(
      '''
UPDATE sync_queue
SET sync_status = 'synced'
WHERE table_name = 'shifts'
  AND operation = 'create'
  AND sync_status IN ('pending', 'failed')
  AND record_id IN (
    SELECT id FROM shifts
    WHERE status = 'open' AND opening_float = 0 AND sync_status = 'synced'
  )
''',
    );
  }

  /// Clears phantom pending counts when the queue is empty but local tickets
  /// still show `pending` after a successful server upload.
  Future<void> _reconcileIdlePendingState({String? token}) async {
    if (AppConfig.useStubApi) {
      await _reconcileServerBackedTicketsStub();
      await _reconcileOrphanQueueEntries();
      return;
    }

    final clearedActive =
        await _ticketService.reconcileActiveServerBackedOrphans();
    if (clearedActive > 0) {
      ValetLog.debug(
        'SyncCubit.flush',
        'cleared $clearedActive active server-backed orphan(s)',
      );
    }

    final tok = token ?? (await _auth.getActiveSession())?.authToken;
    if (tok != null && tok.isNotEmpty) {
      final verified =
          await _ticketService.reconcilePendingServerBackedTickets(tok);
      if (verified > 0) {
        ValetLog.debug(
          'SyncCubit.flush',
          'verified $verified server-backed ticket(s)',
        );
      }
    }

    await _reconcileOrphanQueueEntries();
  }

  Future<void>? _flushFuture;

  Future<void> flush() {
    return _flushFuture ??= _flushBody().whenComplete(() {
      _flushFuture = null;
    });
  }

  Future<void> _flushBody() async {
    emit(const SyncInProgress());
    try {
      if (!AppConfig.useStubApi && !await InternetReachability.hasInternet()) {
        ValetLog.debug('SyncCubit.flush', 'skip — offline');
        emit(SyncComplete(
          synced: 0,
          failed: await failedCount(),
          pending: await pendingCount(),
        ));
        return;
      }
      var syncedThisRun = 0;
      if (AppConfig.useStubApi) {
        await _reconcileServerBackedTicketsStub();
      }
      await _reconcileOrphanQueueEntries();
      final reEnqueued = await _ticketService.reconcileOrphanPendingTickets();
      if (reEnqueued > 0) {
        ValetLog.debug(
          'SyncCubit.flush',
          're-enqueued $reEnqueued orphan pending ticket(s)',
        );
      }
      await _reconcileIdlePendingState();
      var queuePending = await (_db.select(_db.syncQueue)
            ..where((q) => q.syncStatus.equals('pending'))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

      if (queuePending.isEmpty) {
        emit(SyncComplete(
          synced: 0,
          failed: await failedCount(),
          pending: await pendingCount(),
        ));
        return;
      }

      if (AppConfig.useStubApi) {
        for (final row in queuePending) {
          await _markQueueSynced(row);
          await _markEntitySynced(row);
          syncedThisRun++;
        }
      } else {
        final session = await _auth.getActiveSession();
        final token = session?.authToken;
        if (token == null || token.isEmpty) {
          ValetLog.debug('SyncCubit.flush', 'skip HTTP — no bearer token');
        } else {
          final reopened = await _ticketService.reconcileStaleCheckoutUploads(
            token,
          );
          if (reopened > 0) {
            ValetLog.debug(
              'SyncCubit.flush',
              'reopened $reopened stale checkout upload(s)',
            );
            queuePending = await (_db.select(_db.syncQueue)
                  ..where((q) => q.syncStatus.equals('pending'))
                  ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
                .get();
          }

          final verified =
              await _ticketService.reconcilePendingServerBackedTickets(token);
          if (verified > 0) {
            ValetLog.debug(
              'SyncCubit.flush',
              'verified $verified server-backed ticket(s)',
            );
            await _reconcileOrphanQueueEntries();
          }

          final checkInRows = queuePending
              .where(
                (r) =>
                    r.queueTableName == 'tickets' && r.operation == 'checkin',
              )
              .toList();
          final checkOutRows = queuePending
              .where(
                (r) =>
                    r.queueTableName == 'tickets' &&
                    r.operation == 'checkout/finalize',
              )
              .toList();
          final otherRows = queuePending
              .where(
                (r) =>
                    r.queueTableName != 'tickets' ||
                    (r.operation != 'checkin' &&
                        r.operation != 'checkout/finalize'),
              )
              .toList();

          if (checkInRows.isNotEmpty) {
            try {
              syncedThisRun += await _ticketService.syncPendingCheckInsBatch(
                checkInRows,
                token,
              );
            } on DioException catch (e, st) {
              if (e.type == DioExceptionType.connectionError ||
                  e.error is SocketException) {
                ValetLog.debug(
                  'SyncCubit.flush',
                  'batch check-in skipped — network',
                );
              } else {
                ValetLog.error(
                  'SyncCubit.flush',
                  'batch check-in request failed',
                  e,
                  st,
                );
                for (final row in checkInRows) {
                  await _markQueueFailed(row);
                }
              }
            } catch (e, st) {
              ValetLog.error(
                'SyncCubit.flush',
                'batch check-in failed',
                e,
                st,
              );
              for (final row in checkInRows) {
                await _markQueueFailed(row);
              }
            }
          }

          if (checkOutRows.isNotEmpty) {
            try {
              syncedThisRun += await _ticketService.syncPendingCheckoutsBatch(
                checkOutRows,
                token,
              );
            } on DioException catch (e, st) {
              if (e.type == DioExceptionType.connectionError ||
                  e.error is SocketException) {
                ValetLog.debug(
                  'SyncCubit.flush',
                  'batch checkout skipped — network',
                );
              } else {
                ValetLog.error(
                  'SyncCubit.flush',
                  'batch checkout request failed',
                  e,
                  st,
                );
                for (final row in checkOutRows) {
                  await _markQueueFailed(row);
                }
              }
            } catch (e, st) {
              ValetLog.error(
                'SyncCubit.flush',
                'batch checkout failed',
                e,
                st,
              );
              for (final row in checkOutRows) {
                await _markQueueFailed(row);
              }
            }
          }

          for (final row in otherRows) {
            try {
              await _syncQueueRow(
                row: row,
                token: token,
                onSynced: () => syncedThisRun++,
              );
            } catch (e, st) {
              ValetLog.error(
                'SyncCubit.flush',
                'unexpected row error queueId=${row.id} recordId=${row.recordId}',
                e,
                st,
              );
              await _markQueueFailed(row);
            }
          }

          await _reconcileIdlePendingState(token: token);
        }
      }

      emit(SyncComplete(
        synced: syncedThisRun,
        failed: await failedCount(),
        pending: await pendingCount(),
      ));
    } catch (e, st) {
      ValetLog.error('SyncCubit.flush', 'unexpected', e, st);
      emit(SyncComplete(
        synced: 0,
        failed: await failedCount(),
        pending: await pendingCount(),
      ));
    } finally {
      _notifyLocalSyncQueueChanged();
    }
  }

  Future<void> _syncQueueRow({
    required SyncQueueData row,
    required String token,
    required void Function() onSynced,
  }) async {
    Object? rawPayload;
    try {
      rawPayload = jsonDecode(row.payload);
    } catch (e, st) {
      ValetLog.error(
        'SyncCubit.flush',
        'invalid JSON payload queueId=${row.id}',
        e,
        st,
      );
      await _markQueueFailed(row);
      return;
    }
    final payloadMap = _asPayloadMap(rawPayload);
    if (payloadMap == null) {
      ValetLog.error(
        'SyncCubit.flush',
        'payload is not a JSON object queueId=${row.id}',
        StateError('SYNC_PAYLOAD'),
      );
      await _markQueueFailed(row);
      return;
    }

    if (row.queueTableName == 'tickets' && row.operation == 'checkin') {
      try {
        await _ticketService.syncQueuedCheckIn(payloadMap, token);
        await _markQueueSynced(row);
        onSynced();
      } on DioException catch (e, st) {
        final status = e.response?.statusCode;
        if (status != null && status >= 400 && status < 500) {
          ValetLog.error(
            'SyncCubit.flush',
            'check-in client error $status recordId=${row.recordId}',
            e,
            st,
          );
          await _markQueueFailed(row);
        } else {
          ValetLog.error(
            'SyncCubit.flush',
            'check-in retry recordId=${row.recordId}',
            e,
            st,
          );
          await _incrementRetry(row);
        }
      } catch (e, st) {
        ValetLog.error(
          'SyncCubit.flush',
          'check-in failed recordId=${row.recordId}',
          e,
          st,
        );
        await _markQueueFailed(row);
      }
      return;
    }

    // checkout/finalize rows are flushed via syncPendingCheckoutsBatch in flush().

    final hops = _syncHopsForRow(row, payloadMap);
    if (hops == null) {
      ValetLog.error(
        'SyncCubit.flush',
        'unknown route table=${row.queueTableName} op=${row.operation} '
            'id=${row.id} recordId=${row.recordId} payload=${row.payload}',
        StateError('SYNC_ROUTE'),
      );
      await _markQueueFailed(row);
      return;
    }
    if (hops.isEmpty) {
      ValetLog.error(
        'SyncCubit.flush',
        'cannot sync ticket ${row.operation} queueId=${row.id}: missing server_ticket_id '
            '(server transaction must exist first)',
        StateError('SYNC_TICKET_NO_SERVER_ID'),
      );
      await _markQueueFailed(row);
      return;
    }

    var method = '';
    var url = '';
    Object? body;
    try {
      var allOk = true;
      for (final h in hops) {
        method = h.method;
        url = h.url;
        body = h.body;
        final response = await _send(
          method: h.method,
          url: h.url,
          token: token,
          body: h.body,
        );
        final code = response.statusCode ?? 0;
        if (code == 200 || code == 201) {
          continue;
        }
        if (code >= 400 && code < 500) {
          if (row.queueTableName == 'shifts' &&
              row.operation == 'create' &&
              isCashSessionAlreadyOpenResponse(code, response.data)) {
            await _markQueueSynced(row);
            await _markEntitySynced(row);
            onSynced();
            allOk = false;
            break;
          }
          ValetLog.error(
            'SyncCubit.flush',
            'client error $code ${h.method} ${h.url} body=${h.body}',
            StateError('HTTP_$code'),
          );
          await _markQueueFailed(row);
          allOk = false;
          break;
        }
        await _incrementRetry(row);
        allOk = false;
        break;
      }
      if (allOk) {
        await _markQueueSynced(row);
        await _markEntitySynced(row);
        onSynced();
      }
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        if (row.queueTableName == 'shifts' &&
            row.operation == 'create' &&
            isCashSessionAlreadyOpenResponse(status, e.response?.data)) {
          await _markQueueSynced(row);
          await _markEntitySynced(row);
          onSynced();
        } else {
          ValetLog.error(
            'SyncCubit.flush',
            'client error $status $method $url body=$body',
            e,
            st,
          );
          await _markQueueFailed(row);
        }
      } else {
        ValetLog.error(
          'SyncCubit.flush',
          'retry $method $url',
          e,
          st,
        );
        await _incrementRetry(row);
      }
    }
  }

  Map<String, dynamic>? _asPayloadMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// `null` = unknown table/op; empty = ticket create without `server_ticket_id`.
  List<_SyncHop>? _syncHopsForRow(
    SyncQueueData row,
    Map<String, dynamic> body,
  ) {
    final table = row.queueTableName;
    final op = row.operation;

    if (table == 'shifts' && op == 'create') {
      final opening = body['opening_float'];
      final balance = opening is num
          ? opening.toDouble()
          : double.tryParse('$opening') ?? 0.0;
      final notes = body['notes']?.toString();
      return [
        _SyncHop(
          'POST',
          AppConfig.cashSessionsStart,
          buildCashSessionStartBody(
            openingBalance: balance,
            timestampUtcIso: cashSessionStartTimestamp(
              openedAtIso: body['opened_at']?.toString(),
            ),
            notes: notes,
          ),
        ),
      ];
    }

    if (table == 'shifts' && op == 'update') {
      final closing = body['closing_cash'];
      final cash = closing is num
          ? closing.toDouble()
          : double.tryParse('$closing') ?? 0.0;
      return [
        _SyncHop(
          'POST',
          AppConfig.cashSessionsClose,
          buildCashSessionCloseBody(
            actualCash: cash,
            timestampUtcIso: cashSessionStartTimestamp(
              openedAtIso: body['closed_at']?.toString(),
            ),
          ),
        ),
      ];
    }

    if (table == 'tickets' && op == 'update') {
      final sid = body['server_ticket_id']?.toString().trim();
      if (sid == null || sid.isEmpty) {
        return const [];
      }
      final hops = <_SyncHop>[
        _SyncHop(
          'PATCH',
          AppConfig.ticketById(sid),
          checkoutPatchBodyFromTicket(ticketFromSyncQueuePayload(body)),
        ),
      ];
      final fee = body['fee'];
      final feeVal =
          fee is num ? fee.toDouble() : double.tryParse('$fee') ?? 0.0;
      if (feeVal > 0) {
        hops.add(
          _SyncHop(
            'POST',
            AppConfig.transactionPayUrl(sid),
            <String, dynamic>{
              'method': 'cash',
              'amount_paid': feeVal,
            },
          ),
        );
      }
      return hops;
    }

    return null;
  }

  Future<Response<dynamic>> _send({
    required String method,
    required String url,
    required String token,
    required Object? body,
  }) async {
    final opts = Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    switch (method) {
      case 'POST':
        return _dio.post<dynamic>(url, data: body, options: opts);
      case 'PATCH':
        return _dio.patch<dynamic>(url, data: body, options: opts);
      default:
        throw StateError('Unsupported method $method');
    }
  }

  Future<void> _markQueueSynced(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          const SyncQueueCompanion(syncStatus: Value('synced')),
        );
  }

  Future<void> _markQueueFailed(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          const SyncQueueCompanion(syncStatus: Value('failed')),
        );
  }

  Future<void> _incrementRetry(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          SyncQueueCompanion(retryCount: Value(row.retryCount + 1)),
        );
  }

  Future<void> _markEntitySynced(SyncQueueData row) async {
    switch (row.queueTableName) {
      case 'shifts':
        await (_db.update(_db.shifts)..where((s) => s.id.equals(row.recordId)))
            .write(
          const ShiftsCompanion(syncStatus: Value('synced')),
        );
        break;
      case 'tickets':
        await (_db.update(_db.tickets)..where((t) => t.id.equals(row.recordId)))
            .write(
          const TicketsCompanion(syncStatus: Value('synced')),
        );
        break;
    }
  }
}
