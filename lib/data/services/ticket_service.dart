import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../features/check_in/domain/check_in_form_data.dart';
import '../local/db/app_database.dart';
import 'ticket_sync_payload.dart';

/// `tickets` + `sync_queue` persistence and best-effort REST.
class TicketService {
  TicketService(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  static const _uuid = Uuid();

  /// Inserts a `status = draft` row (no sync queue) so the sequential id is known
  /// before the guest completes check-in. [finalizeDraftTicket] or [deleteDraftTicket].
  Future<String> createDraftTicket({
    required String shiftId,
    required String userId,
    required String branchId,
  }) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final id = await generateTicketId(shiftId);
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.tickets).insert(
          TicketsCompanion.insert(
            id: id,
            shiftId: shiftId,
            userId: userId,
            branchId: bid,
            plateNumber: '',
            vehicleBrand: '',
            vehicleColor: '',
            vehicleType: '',
            cellphoneNumber: '',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: 'draft',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
    return id;
  }

  /// Removes a draft row created by [createDraftTicket] (e.g. cancel check-in).
  Future<void> deleteDraftTicket(String ticketId) async {
    final t = ticketId.trim();
    if (t.isEmpty) return;
    final row = await ticketById(t);
    if (row == null || row.status != 'draft') return;
    await (_db.delete(_db.tickets)..where((r) => r.id.equals(t))).go();
  }

  /// Promotes a draft row to `active` and enqueues sync (same as [createTicket]).
  Future<Ticket> finalizeDraftTicket({
    required String ticketId,
    required CheckInFormData data,
    required String shiftId,
    required String userId,
    required String branchId,
  }) async {
    final existing = await ticketById(ticketId.trim());
    if (existing == null || existing.status != 'draft') {
      throw StateError('No draft ticket for id $ticketId');
    }
    if (existing.shiftId != shiftId || existing.userId != userId) {
      throw StateError('Draft ticket shift/user mismatch');
    }
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final now = DateTime.now().toIso8601String();

    await _db.transaction(() async {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId.trim())))
          .write(
        TicketsCompanion(
          branchId: Value(bid),
          plateNumber: Value(data.plateNumber),
          vehicleBrand: Value(data.vehicleBrand),
          vehicleColor: Value(data.vehicleColor),
          vehicleType: Value(data.vehicleType),
          cellphoneNumber: Value(data.cellphoneNumber),
          damageMarkers: Value(data.damageMarkersJson),
          personalBelongings: Value(data.personalBelongingsJson),
          checkInAt: Value(now),
          status: const Value('active'),
          syncStatus: const Value('pending'),
        ),
      );
      final inserted = await (_db.select(_db.tickets)
            ..where((t) => t.id.equals(ticketId.trim())))
          .getSingle();
      final payload = jsonEncode(ticketSyncPayload(inserted));
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'create',
              queueTableName: 'tickets',
              recordId: inserted.id,
              payload: payload,
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
    });

    unawaited(_postTicketCreate(ticketId.trim()));
    return (_db.select(_db.tickets)..where((t) => t.id.equals(ticketId.trim())))
        .getSingle();
  }

  /// Per-shift sequence `TKT-0001` … (4-digit zero-padded).
  Future<String> generateTicketId(String shiftId) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM tickets WHERE shift_id = ?',
      variables: [Variable<String>(shiftId)],
    ).getSingle();
    final n = (row.data['c'] as num?)?.toInt() ?? 0;
    final next = n + 1;
    return 'TKT-${next.toString().padLeft(4, '0')}';
  }

  Future<Ticket> createTicket({
    required CheckInFormData data,
    required String shiftId,
    required String userId,
    required String branchId,
  }) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final id = await generateTicketId(shiftId);
    final now = DateTime.now().toIso8601String();

    await _db.transaction(() async {
      await _db.into(_db.tickets).insert(
            TicketsCompanion.insert(
              id: id,
              shiftId: shiftId,
              userId: userId,
              branchId: bid,
              plateNumber: data.plateNumber,
              vehicleBrand: data.vehicleBrand,
              vehicleColor: data.vehicleColor,
              vehicleType: data.vehicleType,
              cellphoneNumber: data.cellphoneNumber,
              damageMarkers: data.damageMarkersJson,
              personalBelongings: data.personalBelongingsJson,
              checkInAt: now,
              status: 'active',
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
      final inserted =
          await (_db.select(_db.tickets)..where((t) => t.id.equals(id)))
              .getSingle();
      final payload = jsonEncode(ticketSyncPayload(inserted));
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'create',
              queueTableName: 'tickets',
              recordId: id,
              payload: payload,
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
    });

    unawaited(_postTicketCreate(id));
    return (_db.select(_db.tickets)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Open row by id (exact ticket code, e.g. `TKT-0001`).
  Future<Ticket?> activeTicketByTicketNumber(String ticket) async {
    final t = ticket.trim();
    if (t.isEmpty) return null;
    return (_db.select(_db.tickets)
          ..where((r) => r.id.equals(t) & r.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Most recent open ticket for [plate] (spaces ignored, case-insensitive).
  Future<Ticket?> activeTicketByPlate(String plate) async {
    final normalized =
        plate.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (normalized.isEmpty) return null;
    final row = await _db.customSelect(
      '''
SELECT id FROM tickets
WHERE status = 'active'
  AND REPLACE(UPPER(plate_number), ' ', '') = ?
ORDER BY check_in_at DESC
LIMIT 1
''',
      variables: <Variable<Object>>[Variable.withString(normalized)],
      readsFrom: {_db.tickets},
    ).getSingleOrNull();
    if (row == null) return null;
    final tid = row.read<String>('id');
    return ticketById(tid);
  }

  /// Completes checkout + `sync_queue` (`operation: update`).
  Future<void> completeTicketCheckout({
    required String ticketId,
    required String checkOutAtIso,
    required double totalFee,
    required String damageMarkersJson,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.transaction(() async {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId))).write(
            TicketsCompanion(
              checkOutAt: Value(checkOutAtIso),
              fee: Value(totalFee),
              status: const Value('completed'),
              damageMarkers: Value(damageMarkersJson),
              syncStatus: const Value('pending'),
            ),
          );
      final updated = await (_db.select(_db.tickets)
            ..where((t) => t.id.equals(ticketId)))
          .getSingleOrNull();
      if (updated == null) return;
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: _uuid.v4(),
              operation: 'update',
              queueTableName: 'tickets',
              recordId: ticketId,
              payload: jsonEncode(ticketSyncPayload(updated)),
              syncStatus: 'pending',
              createdAt: now,
            ),
          );
    });
    unawaited(_patchTicketCheckout(ticketId));
  }

  Future<int> countActiveTicketsForShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'active'
''',
      variables: <Variable<Object>>[Variable.withString(sid)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Check-ins on the shift with `check_in_at` ≥ [sinceIso8601].
  Future<int> countCheckInsOnShiftSince({
    required String shiftId,
    required String sinceIso8601,
  }) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ?
  AND check_in_at >= ?
  AND status != 'draft'
''',
      variables: <Variable<Object>>[
        Variable.withString(sid),
        Variable.withString(sinceIso8601),
      ],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> countCompletedCheckoutsForShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
      variables: <Variable<Object>>[Variable.withString(sid)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<double> sumFeesForCompletedShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db.customSelect(
      '''
SELECT COALESCE(SUM(fee), 0) AS s FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
      variables: <Variable<Object>>[Variable.withString(sid)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['s'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Ticket>> activeTicketsForShiftOrdered({
    required String shiftId,
    int limit = 20,
  }) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where((t) => t.shiftId.equals(sid) & t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)])
          ..limit(limit))
        .get();
  }

  /// All tickets attributed to [shiftId] (any status), newest check-in first.
  Future<List<Ticket>> ticketsForShift(String shiftId) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where((t) => t.shiftId.equals(sid))
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)]))
        .get();
  }

  /// Tickets whose `check_in_at` falls in \[ [start], [end) \) (ISO8601 strings).
  Future<List<Ticket>> ticketsWithCheckInInRange({
    required DateTime start,
    required DateTime end,
    int limit = 2000,
  }) {
    final from = start.toIso8601String();
    final to = end.toIso8601String();
    return (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.checkInAt.isBiggerOrEqualValue(from) &
                t.checkInAt.isSmallerThanValue(to),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)])
          ..limit(limit))
        .get();
  }

  /// Recent tickets for dashboard: same shift, mixed status, cap [limit].
  Future<List<Ticket>> recentTicketsForShift(
    String shiftId, {
    int limit = 10,
  }) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where((t) => t.shiftId.equals(sid) & t.status.equals('draft').not())
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)])
          ..limit(limit))
        .get();
  }

  Future<Ticket?> ticketById(String id) {
    return (_db.select(_db.tickets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> _postTicketCreate(String ticketId) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      final row =
          await (_db.select(_db.tickets)..where((t) => t.id.equals(ticketId)))
              .getSingle();
      await _dio.post<dynamic>(
        AppConfig.ticketCreate,
        data: ticketSyncPayload(row),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
    } catch (e, st) {
      ValetLog.error('TicketService', 'POST tickets failed (queued)', e, st);
    }
  }

  Future<void> _patchTicketCheckout(String ticketId) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      final row = await (_db.select(_db.tickets)
            ..where((t) => t.id.equals(ticketId)))
          .getSingleOrNull();
      if (row == null) return;
      await _dio.patch<dynamic>(
        AppConfig.ticketCheckout(ticketId),
        data: ticketSyncPayload(row),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (c) => c != null && c < 500,
        ),
      );
    } catch (e, st) {
      ValetLog.error(
        'TicketService',
        'PATCH ticket checkout failed (queued)',
        e,
        st,
      );
    }
  }

  Future<String?> _activeBearer() async {
    final s = await (_db.select(_db.sessions)
          ..where((x) => x.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    final t = s?.authToken;
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
