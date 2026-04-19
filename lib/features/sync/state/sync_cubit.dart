import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/valet_log.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_sync_payload.dart';
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
  })  : _db = database,
        _dio = dio,
        _auth = authRepository,
        super(const SyncIdle());

  final AppDatabase _db;
  final Dio _dio;
  final AuthRepository _auth;

  Future<int> pendingCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'pending'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> failedCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'failed'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> retryFailed() async {
    await _db.customStatement(
      "UPDATE sync_queue SET sync_status = 'pending', retry_count = 0 "
      "WHERE sync_status = 'failed'",
    );
    await flush();
  }

  Future<void> flush() async {
    emit(const SyncInProgress());
    var syncedThisRun = 0;
    try {
      final pending = await (_db.select(_db.syncQueue)
            ..where((q) => q.syncStatus.equals('pending'))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

      if (pending.isEmpty) {
        emit(SyncComplete(
          synced: 0,
          failed: await failedCount(),
          pending: 0,
        ));
        return;
      }

      if (AppConfig.useStubApi) {
        for (final row in pending) {
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
          for (final row in pending) {
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
              continue;
            }
            final payloadMap = _asPayloadMap(rawPayload);
            if (payloadMap == null) {
              ValetLog.error(
                'SyncCubit.flush',
                'payload is not a JSON object queueId=${row.id}',
                StateError('SYNC_PAYLOAD'),
              );
              await _markQueueFailed(row);
              continue;
            }

            final hops = _syncHopsForRow(row, payloadMap);
            if (hops == null) {
              ValetLog.error(
                'SyncCubit.flush',
                'unknown route table=${row.queueTableName} op=${row.operation} '
                    'id=${row.id} recordId=${row.recordId} payload=${row.payload}',
                StateError('SYNC_ROUTE'),
              );
              await _markQueueFailed(row);
              continue;
            }
            if (hops.isEmpty) {
              ValetLog.error(
                'SyncCubit.flush',
                'cannot sync ticket ${row.operation} queueId=${row.id}: missing server_ticket_id '
                    '(server transaction must exist first)',
                StateError('SYNC_TICKET_NO_SERVER_ID'),
              );
              await _markQueueFailed(row);
              continue;
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
                syncedThisRun++;
              }
            } on DioException catch (e, st) {
              final status = e.response?.statusCode;
              if (status != null && status >= 400 && status < 500) {
                ValetLog.error(
                  'SyncCubit.flush',
                  'client error $status $method $url body=$body',
                  e,
                  st,
                );
                await _markQueueFailed(row);
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
        }
      }

      emit(SyncComplete(
        synced: syncedThisRun,
        failed: await failedCount(),
        pending: await pendingCount(),
      ));
    } catch (e, st) {
      ValetLog.error('SyncCubit.flush', 'unexpected', e, st);
      emit(SyncError(e.toString()));
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
      return [
        _SyncHop(
          'POST',
          AppConfig.cashSessionsStart,
          <String, dynamic>{
            'opening_balance': balance,
            'notes': null,
          },
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
          <String, dynamic>{
            'shift_id': row.recordId,
            'actual_cash': cash,
            'notes': null,
          },
        ),
      ];
    }

    if (table == 'tickets' && op == 'create') {
      final sid = body['server_ticket_id']?.toString().trim();
      if (sid == null || sid.isEmpty) {
        return const [];
      }
      return [
        _SyncHop(
          'PATCH',
          AppConfig.ticketById(sid),
          transactionCheckInPatchFromSyncPayload(body),
        ),
      ];
    }

    if (table == 'tickets' && op == 'update') {
      final sid = body['server_ticket_id']?.toString().trim();
      if (sid == null || sid.isEmpty) {
        return const [];
      }
      final damages = _decodeJsonListField(body['damage_markers']);
      final hops = <_SyncHop>[
        _SyncHop(
          'PATCH',
          AppConfig.ticketById(sid),
          <String, dynamic>{
            'condition_checkout': damages,
            'status': 'active',
          },
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

  Object _decodeJsonListField(dynamic raw) {
    if (raw == null) return const <dynamic>[];
    if (raw is List) return raw;
    if (raw is String) {
      if (raw.trim().isEmpty) return const <dynamic>[];
      try {
        final v = jsonDecode(raw);
        return v is List ? v : const <dynamic>[];
      } catch (_) {
        return const <dynamic>[];
      }
    }
    return const <dynamic>[];
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
