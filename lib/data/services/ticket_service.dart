import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/connectivity/internet_reachability.dart';
import '../../core/logging/valet_log.dart';
import '../../features/check_in/domain/check_in_form_data.dart';
import '../local/db/app_database.dart';
import '../remote/transactions_api.dart';
import 'ticket_sync_payload.dart';

Object _decodeTicketJsonField(String raw, Object fallback) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return fallback;
  }
}

Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

String? _normalizedDriverName(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

/// `tickets` + `sync_queue` persistence and best-effort REST.
class TicketService {
  TicketService(this._db, this._dio, this._transactionsApi);

  final AppDatabase _db;
  final Dio _dio;
  final TransactionsApi _transactionsApi;

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

  /// Hard-delete all `draft` rows for [shiftId]. No sync queue (same as [deleteDraftTicket]).
  Future<void> purgeOrphanedDrafts(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return;
    await (_db.delete(_db.tickets)
          ..where((t) => t.shiftId.equals(sid) & t.status.equals('draft')))
        .go();
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
          driverIn: Value(_normalizedDriverName(data.driverIn)),
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
              driverIn: Value(_normalizedDriverName(data.driverIn)),
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
    String? driverOut,
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
              driverOut: Value(_normalizedDriverName(driverOut)),
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

  /// GET server transaction by UUID; upserts local [tickets] row (no sync_queue).
  ///
  /// Schema v5 has no `local_uuid` / `last_modified_at` columns; persistence uses
  /// existing [Ticket] fields only.
  Future<Ticket> getTransactionById(String serverId) async {
    final token = await _activeBearer();
    if (token == null || token.isEmpty) {
      throw TransactionsApiException('No active bearer token.');
    }
    final map = await _transactionsApi.getTransactionById(
      token: token,
      id: serverId,
    );
    return _upsertFromServerTransactionJson(map);
  }

  /// GET server transaction by local ticket number (`TKT-…`); upserts local row.
  Future<Ticket> getTransactionByTicketNumber(String ticketNumber) async {
    final token = await _activeBearer();
    if (token == null || token.isEmpty) {
      throw TransactionsApiException('No active bearer token.');
    }
    final map = await _transactionsApi.getTransactionByTicketNumber(
      token: token,
      ticketNumber: ticketNumber,
    );
    return _upsertFromServerTransactionJson(map);
  }

  /// POST lost ticket (live only). Updates local row [status] and [fee] from response.
  Future<Ticket> markTicketLost(String serverId, {String? notes}) async {
    if (AppConfig.useStubApi) {
      throw TransactionsApiException(
        'Stub API: configure API_BASE_URL to mark a ticket lost.',
      );
    }
    if (!await InternetReachability.hasInternet()) {
      throw TransactionsApiException(
        'Device is offline. Lost ticket requires a connection.',
      );
    }
    final token = await _activeBearer();
    if (token == null || token.isEmpty) {
      throw TransactionsApiException('No active bearer token.');
    }
    final row = await _ticketByServerId(serverId.trim());
    if (row == null) {
      throw TransactionsApiException(
        'No local ticket with server_ticket_id matching this transaction.',
      );
    }
    final map = await _transactionsApi.markTicketLost(
      token: token,
      ticketId: serverId,
      notes: notes,
    );
    final fee = _feeFromLostResponse(map);
    final lostStatus =
        _normalizeTicketStatus(map['status']?.toString() ?? 'lost');
    await (_db.update(_db.tickets)..where((t) => t.id.equals(row.id))).write(
      TicketsCompanion(
        status: Value(lostStatus),
        fee: Value(fee),
        syncStatus: const Value('synced'),
      ),
    );
    return (await ticketById(row.id))!;
  }

  Future<Ticket?> _ticketByServerId(String serverUuid) async {
    final u = serverUuid.trim();
    if (u.isEmpty) return null;
    return (_db.select(_db.tickets)..where((t) => t.serverTicketId.equals(u)))
        .getSingleOrNull();
  }

  Future<({String shiftId, String userId, String branchId})?>
      _ticketUpsertContext() async {
    final session = await (_db.select(_db.sessions)
          ..where((x) => x.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (session == null) return null;
    final account = await (_db.select(_db.offlineAccounts)
          ..where((a) => a.id.equals(session.userId))
          ..limit(1))
        .getSingleOrNull();
    if (account == null) return null;
    final userIdStr = account.serverUserId.toString();
    final shift = await (_db.select(_db.shifts)
          ..where((s) => s.userId.equals(userIdStr) & s.status.equals('open'))
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (shift == null) return null;
    return (
      shiftId: shift.id,
      userId: userIdStr,
      branchId: shift.branchId,
    );
  }

  Future<Ticket> _upsertFromServerTransactionJson(Map<String, dynamic> json) async {
    final serverUuid = json['id']?.toString().trim() ?? '';
    if (serverUuid.isEmpty) {
      throw TransactionsApiException('Server response missing id.');
    }
    final ticketNum = json['ticket_number']?.toString().trim() ??
        json['ticketNumber']?.toString().trim() ??
        '';
    if (ticketNum.isEmpty) {
      throw TransactionsApiException('Server response missing ticket_number.');
    }
    final checkIn = _parseCheckInTime(json);
    final vm = _vehicleMap(json);
    final plate =
        vm['plate_number']?.toString() ?? vm['plateNumber']?.toString() ?? '';
    final brand = vm['brand']?.toString() ?? '';
    final color = vm['color']?.toString() ?? '';
    final vtype = vm['type']?.toString() ?? '';
    final status = _normalizeTicketStatus(json['status']?.toString() ?? 'active');

    final existing =
        await _ticketByServerId(serverUuid) ?? await ticketById(ticketNum);
    if (existing != null) {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(existing.id)))
          .write(
        TicketsCompanion(
          serverTicketId: Value(serverUuid),
          plateNumber: Value(plate),
          vehicleBrand: Value(brand),
          vehicleColor: Value(color),
          vehicleType: Value(vtype),
          checkInAt: Value(checkIn),
          status: Value(status),
          syncStatus: const Value('synced'),
        ),
      );
      final out = await ticketById(existing.id);
      if (out == null) {
        throw TransactionsApiException('Upsert failed after update.');
      }
      return out;
    }

    final ctx = await _ticketUpsertContext();
    if (ctx == null) {
      throw TransactionsApiException(
        'Open a cash shift before saving a ticket from the server.',
      );
    }
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.tickets).insert(
          TicketsCompanion.insert(
            id: ticketNum,
            shiftId: ctx.shiftId,
            userId: ctx.userId,
            branchId: ctx.branchId,
            plateNumber: plate,
            vehicleBrand: brand,
            vehicleColor: color,
            vehicleType: vtype,
            cellphoneNumber: '',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: checkIn,
            status: status,
            syncStatus: 'synced',
            createdAt: now,
            serverTicketId: Value(serverUuid),
          ),
        );
    final out = await ticketById(ticketNum);
    if (out == null) {
      throw TransactionsApiException('Upsert failed after insert.');
    }
    return out;
  }

  static Map<String, dynamic> _vehicleMap(Map<String, dynamic> json) {
    final vehicle = json['vehicle'];
    if (vehicle is Map<String, dynamic>) return vehicle;
    if (vehicle is Map) return Map<String, dynamic>.from(vehicle);
    return const <String, dynamic>{};
  }

  static String _parseCheckInTime(Map<String, dynamic> json) {
    final raw = json['check_in_time'] ??
        json['checkInTime'] ??
        json['check_in_at'] ??
        json['checkInAt'];
    if (raw == null) return DateTime.now().toIso8601String();
    final s = raw.toString().trim();
    if (s.isEmpty) return DateTime.now().toIso8601String();
    final dt = DateTime.tryParse(s);
    return dt?.toIso8601String() ?? DateTime.now().toIso8601String();
  }

  static String _normalizeTicketStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'lost') return 'lost';
    if (s == 'completed' || s == 'complete') return 'completed';
    if (s == 'draft') return 'draft';
    return 'active';
  }

  static double? _feeFromLostResponse(Map<String, dynamic> m) {
    final f = m['fee'];
    if (f is num) return f.toDouble();
    if (f != null) return double.tryParse(f.toString());
    return null;
  }

  Map<String, dynamic> _checkInPatchBody(Ticket row) {
    return <String, dynamic>{
      'driver_in': row.driverIn,
      'vehicle': <String, dynamic>{
        'plate_number': row.plateNumber,
        'brand': row.vehicleBrand,
        'color': row.vehicleColor,
        'type': row.vehicleType,
        'model': '',
        'year': null,
      },
      'parking': <String, dynamic>{
        'level': null,
        'slot': null,
      },
      'belongings':
          _decodeTicketJsonField(row.personalBelongings, const <dynamic>[]),
      'condition': <String, dynamic>{
        'damages': _decodeTicketJsonField(row.damageMarkers, const <dynamic>[]),
        'signature': row.signaturePng,
      },
    };
  }

  Future<void> _postTicketCreate(String ticketId) async {
    if (AppConfig.useStubApi) return;
    final token = await _activeBearer();
    if (token == null) return;
    try {
      var row =
          await (_db.select(_db.tickets)..where((t) => t.id.equals(ticketId)))
              .getSingle();

      final opts = Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (c) => c != null && c < 500,
      );

      var serverId = row.serverTicketId?.trim();
      if (serverId == null || serverId.isEmpty) {
        final createRes = await _dio.post<dynamic>(
          AppConfig.ticketsRest,
          data: <String, dynamic>{
            'customer_name': null,
            'contact_number': row.cellphoneNumber.trim().isEmpty
                ? null
                : row.cellphoneNumber,
            'valet_type': 'standard_valet',
            'notes': null,
          },
          options: opts,
        );
        if (createRes.statusCode != 201) return;
        final m = _asStringKeyedMap(createRes.data);
        serverId = m?['id']?.toString().trim();
        if (serverId == null || serverId.isEmpty) {
          ValetLog.warning(
            'TicketService',
            'create transaction: missing id in response for local $ticketId',
          );
          return;
        }
        final remoteNum = m?['ticket_number'] ?? m?['ticketNumber'];
        if (remoteNum != null) {
          final r = remoteNum.toString().trim();
          if (r.isNotEmpty && r != row.id) {
            ValetLog.warning(
              'TicketService',
              'server ticket_number $r != local id ${row.id} — keeping local id',
            );
          }
        }
        await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId)))
            .write(TicketsCompanion(serverTicketId: Value(serverId)));
        row =
            await (_db.select(_db.tickets)..where((t) => t.id.equals(ticketId)))
                .getSingle();
      }

      await _dio.patch<dynamic>(
        AppConfig.ticketById(serverId),
        data: _checkInPatchBody(row),
        options: opts,
      );
    } catch (e, st) {
      ValetLog.error(
        'TicketService',
        'transaction check-in sync failed (queued)',
        e,
        st,
      );
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
      final serverId = row.serverTicketId?.trim() ?? '';
      if (serverId.isEmpty) {
        ValetLog.warning(
          'TicketService',
          'checkout sync skipped: missing server_ticket_id for $ticketId',
        );
        return;
      }

      final opts = Options(
        headers: {'Authorization': 'Bearer $token'},
        validateStatus: (c) => c != null && c < 500,
      );

      await _dio.patch<dynamic>(
        AppConfig.ticketById(serverId),
        data: checkoutPatchBodyFromTicket(row),
        options: opts,
      );

      final fee = row.fee ?? 0;
      if (fee > 0) {
        final payRes = await _dio.post<dynamic>(
          AppConfig.transactionPayUrl(serverId),
          data: <String, dynamic>{
            'method': 'cash',
            'amount_paid': fee,
          },
          options: opts,
        );
        if (payRes.statusCode == 200) {
          final d = payRes.data;
          final m = _asStringKeyedMap(d);
          final change = m?['change'];
          if (change != null) {
            ValetLog.debug('TicketService', 'pay change: $change');
          }
        }
      }
    } catch (e, st) {
      ValetLog.error(
        'TicketService',
        'transaction checkout sync failed (queued)',
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
