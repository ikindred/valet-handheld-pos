import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../local/db/app_database.dart';

/// Local `shifts` + `sync_queue` lifecycle with best-effort REST sync.
class ShiftService {
  ShiftService(
    this._db,
    this._dio, {
    this.onShiftMutated,
  });

  final AppDatabase _db;
  final Dio _dio;
  final void Function()? onShiftMutated;

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
  Future<Shift> createShift({
    required String userId,
    required String branchId,
    required double openingFloat,
  }) async {
    final existing = await getActiveShift(userId);
    if (existing != null) {
      throw StateError('SHIFT_ALREADY_OPEN');
    }
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.transaction(() async {
      await _db.into(_db.shifts).insert(
            ShiftsCompanion.insert(
              id: id,
              userId: userId,
              branchId: bid,
              openedAt: now,
              openingFloat: openingFloat,
              status: 'open',
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
      final inserted =
          await (_db.select(_db.shifts)..where((s) => s.id.equals(id)))
              .getSingle();
      final payload = jsonEncode(shiftRowToJson(inserted));
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'create',
              queueTableName: 'shifts',
              recordId: id,
              payload: payload,
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
    });

    onShiftMutated?.call();
    unawaited(_postShiftCreate(id));
    return (_db.select(_db.shifts)..where((s) => s.id.equals(id))).getSingle();
  }

  /// Closes a shift + enqueue update; best-effort PATCH.
  Future<Shift> closeShift({
    required String shiftId,
    required double closingCash,
  }) async {
    final now = DateTime.now().toIso8601String();
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
    unawaited(_patchShift(shiftId));
    return (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
        .getSingle();
  }

  /// Closes the active shift for [localUserId], if any (no-op when none).
  Future<void> closeActiveShiftForLocalUser(
    int localUserId,
    double closingCash,
  ) async {
    final uid = await shiftUserIdForLocalAccount(localUserId);
    final open = await getActiveShift(uid);
    if (open == null) return;
    await closeShift(shiftId: open.id, closingCash: closingCash);
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

  Future<void> _postShiftCreate(String shiftId) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      final row =
          await (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
              .getSingle();
      await _dio.post<dynamic>(
        AppConfig.shiftsRest,
        data: shiftRowToJson(row),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
    } catch (e, st) {
      ValetLog.error('ShiftService', 'POST shifts failed (queued)', e, st);
    }
  }

  Future<void> _patchShift(String shiftId) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      final row =
          await (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
              .getSingle();
      await _dio.patch<dynamic>(
        AppConfig.shiftById(shiftId),
        data: shiftRowToJson(row),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
    } catch (e, st) {
      ValetLog.error('ShiftService', 'PATCH shift failed (queued)', e, st);
    }
  }
}
