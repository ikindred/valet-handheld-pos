import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/sync/local_sync_notifier.dart';
import '../local/db/app_database.dart';
import '../remote/api_error_message.dart';
import 'cash_session_close_payload.dart';
import 'cash_session_http.dart';
import 'cash_session_start_payload.dart';
import 'ticket_service.dart';

/// Thrown when online `POST /cash-sessions/start` fails after local shift row exists.
class CashSessionStartException implements Exception {
  CashSessionStartException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when online `POST /cash-sessions/close-cash` fails during close cash.
class CashSessionCloseException implements Exception {
  CashSessionCloseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Local `shifts` + `sync_queue` lifecycle with best-effort REST sync.
class ShiftService {
  ShiftService(
    this._db,
    this._dio, {
    required TicketService ticketService,
    this.onShiftMutated,
    LocalSyncNotifier? localSyncNotifier,
  })  : _tickets = ticketService,
        _localSyncNotifier = localSyncNotifier;

  final AppDatabase _db;
  final Dio _dio;
  final TicketService _tickets;
  final void Function()? onShiftMutated;
  final LocalSyncNotifier? _localSyncNotifier;

  void _notifyLocalSyncQueueChanged() {
    _localSyncNotifier?.notifyLocalQueueChanged();
  }

  static const _uuid = Uuid();

  /// Stable string id for [Shifts.userId] (server user id when available).
  Future<String> shiftUserIdForLocalAccount(int localUserId) async {
    final row = await (_db.select(_db.offlineAccounts)
          ..where((a) => a.id.equals(localUserId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return localUserId.toString();
    return row.serverUserId.toString();
  }

  /// Open shift for [userId], newest first.
  Future<Shift?> getActiveShift(String userId) {
    return (_db.select(_db.shifts)
          ..where((s) => s.userId.equals(userId) & s.status.equals('open'))
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Creates a shift row + outbound queue; best-effort POST. Throws if one is already open.
  ///
  /// When [resumeServerSession] is true (login after cache clear with server
  /// `is_open_cash`), the local row mirrors an existing server session — no
  /// `sync_queue` row and no POST `/cash-sessions/start`.
  Future<Shift> createShift({
    required String userId,
    required String branchId,
    required double openingFloat,
    String? notes,
    bool awaitRemoteStart = false,
    bool resumeServerSession = false,
    bool isExpressCashier = false,
  }) async {
    final existing = await getActiveShift(userId);
    if (existing != null) {
      throw StateError('SHIFT_ALREADY_OPEN');
    }
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final id = _uuid.v4();
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final trimmedNotes = notes?.trim();

    await _db.transaction(() async {
      await _db.into(_db.shifts).insert(
            ShiftsCompanion.insert(
              id: id,
              userId: userId,
              branchId: bid,
              openedAt: nowUtc,
              openingFloat: openingFloat,
              status: 'open',
              syncStatus: resumeServerSession ? 'synced' : 'pending',
              createdAt: nowUtc,
              isExpressCashier: Value(isExpressCashier),
            ),
          );
      if (resumeServerSession) return;
      final inserted =
          await (_db.select(_db.shifts)..where((s) => s.id.equals(id)))
              .getSingle();
      final payloadMap = shiftRowToJson(inserted);
      if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
        payloadMap['notes'] = trimmedNotes;
      }
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'create',
              queueTableName: 'shifts',
              recordId: id,
              payload: jsonEncode(payloadMap),
              syncStatus: 'pending',
              createdAt: nowUtc,
            ),
          );
    });

    onShiftMutated?.call();
    if (!resumeServerSession) {
      _notifyLocalSyncQueueChanged();
    }
    if (resumeServerSession) {
      return (_db.select(_db.shifts)..where((s) => s.id.equals(id))).getSingle();
    }
    final remote = _postShiftCreate(
      shiftId: id,
      openingBalance: openingFloat,
      timestampUtcIso: nowUtc,
      notes: trimmedNotes,
      throwOnFailure: awaitRemoteStart,
    );
    if (awaitRemoteStart) {
      await remote;
    } else {
      unawaited(remote);
    }
    unawaited(
      _tickets.purgeOrphanedDrafts(id).catchError((_, __) {}),
    );
    return (_db.select(_db.shifts)..where((s) => s.id.equals(id))).getSingle();
  }

  /// Closes a shift + enqueue update; best-effort POST cash-session close.
  Future<Shift> closeShift({
    required String shiftId,
    required double closingCash,
    bool awaitRemoteClose = false,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db.transaction(() async {
      await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
            ShiftsCompanion(
              closedAt: Value(now),
              closingCash: Value(closingCash),
              status: const Value('closed'),
              syncStatus: const Value('pending'),
            ),
          );
      final updated =
          await (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
              .getSingle();
      final payload = jsonEncode(shiftRowToJson(updated));
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'update',
              queueTableName: 'shifts',
              recordId: shiftId,
              payload: payload,
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
    });
    onShiftMutated?.call();
    _notifyLocalSyncQueueChanged();
    final remote = _postShiftClose(
      shiftId: shiftId,
      actualCash: closingCash,
      timestampUtcIso: now,
      throwOnFailure: awaitRemoteClose,
    );
    if (awaitRemoteClose) {
      await remote;
    } else {
      unawaited(remote);
    }
    return (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
        .getSingle();
  }

  /// Closes the active shift for [localUserId], if any (no-op when none).
  Future<void> closeActiveShiftForLocalUser(
    int localUserId,
    double closingCash, {
    bool awaitRemoteClose = false,
  }) async {
    final uid = await shiftUserIdForLocalAccount(localUserId);
    final open = await getActiveShift(uid);
    if (open == null) return;
    await closeShift(
      shiftId: open.id,
      closingCash: closingCash,
      awaitRemoteClose: awaitRemoteClose,
    );
  }

  static Map<String, dynamic> shiftRowToJson(Shift s) => <String, dynamic>{
        'id': s.id,
        'user_id': s.userId,
        'branch_id': s.branchId,
        'opened_at': s.openedAt,
        'closed_at': s.closedAt,
        'opening_float': s.openingFloat,
        'closing_cash': s.closingCash,
        'status': s.status,
        'sync_status': s.syncStatus,
        'created_at': s.createdAt,
      };

  Future<String?> _activeBearer() async {
    final s = await (_db.select(_db.sessions)
          ..where((x) => x.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    final t = s?.authToken;
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<void> _postShiftCreate({
    required String shiftId,
    required double openingBalance,
    required String timestampUtcIso,
    String? notes,
    bool throwOnFailure = false,
  }) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.cashSessionsStart,
        data: buildCashSessionStartBody(
          openingBalance: openingBalance,
          timestampUtcIso: timestampUtcIso,
          notes: notes,
        ),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
      if (res.statusCode == 201) {
        await _markShiftCreateSynced(
          shiftId,
          openedAt: _openedAtFromStartResponse(res.data),
        );
        return;
      }
      if (isCashSessionAlreadyOpenResponse(res.statusCode, res.data)) {
        await _markShiftCreateSynced(shiftId);
        return;
      }
      final msg = messageFromResponseData(res.data) ??
          'Could not start shift (HTTP ${res.statusCode ?? 0}).';
      if (throwOnFailure) throw CashSessionStartException(msg);
      ValetLog.warning('ShiftService', 'POST cash-sessions/start: $msg');
    } on CashSessionStartException {
      rethrow;
    } on DioException catch (e, st) {
      ValetLog.error(
        'ShiftService',
        'POST cash-sessions/start failed',
        e,
        st,
      );
      if (throwOnFailure) {
        throw CashSessionStartException(
          parseApiErrorUserMessage(e) ??
              'Could not start shift. Check your connection and try again.',
        );
      }
    } catch (e, st) {
      ValetLog.error(
        'ShiftService',
        'POST cash-sessions/start failed (queued)',
        e,
        st,
      );
    }
  }

  Future<void> _markShiftCreateSynced(
    String shiftId, {
    String? openedAt,
  }) async {
    await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
      ShiftsCompanion(
        syncStatus: const Value('synced'),
        openedAt: openedAt != null ? Value(openedAt) : const Value.absent(),
      ),
    );
    await (_db.update(_db.syncQueue)
          ..where(
            (q) =>
                q.queueTableName.equals('shifts') &
                q.operation.equals('create') &
                q.recordId.equals(shiftId),
          ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
  }

  static String? _openedAtFromStartResponse(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final raw = map['opened_at'] ?? map['openedAt'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _postShiftClose({
    required String shiftId,
    required double actualCash,
    required String timestampUtcIso,
    String? notes,
    bool throwOnFailure = false,
  }) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) {
      if (throwOnFailure) {
        throw CashSessionCloseException(
          'Session expired. Sign in again and retry close cash.',
        );
      }
      return;
    }
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.cashSessionsClose,
        data: buildCashSessionCloseBody(
          actualCash: actualCash,
          timestampUtcIso: timestampUtcIso,
          notes: notes,
        ),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
      final code = res.statusCode ?? 0;
      if (code == 200 || code == 201) {
        await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId)))
            .write(const ShiftsCompanion(syncStatus: Value('synced')));
        return;
      }
      final msg = messageFromResponseData(res.data) ??
          'Could not close cash session (HTTP $code).';
      if (throwOnFailure) throw CashSessionCloseException(msg);
      ValetLog.warning('ShiftService', 'POST cash-sessions/close-cash: $msg');
    } on CashSessionCloseException {
      rethrow;
    } on DioException catch (e, st) {
      ValetLog.error(
        'ShiftService',
        'POST cash-sessions/close-cash failed',
        e,
        st,
      );
      if (throwOnFailure) {
        throw CashSessionCloseException(
          parseApiErrorUserMessage(e) ??
              'Could not close cash. Check your connection and try again.',
        );
      }
    } catch (e, st) {
      ValetLog.error(
        'ShiftService',
        'POST cash-sessions/close-cash failed (queued)',
        e,
        st,
      );
      if (throwOnFailure) {
        throw CashSessionCloseException(
          'Could not close cash. Check your connection and try again.',
        );
      }
    }
  }
}
