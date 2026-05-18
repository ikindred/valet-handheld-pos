import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/services/device_id_service.dart';
import '../../core/time/philippine_time.dart';
import '../../features/check_out/domain/checkout_ticket_display.dart';
import '../../features/check_out/models/check_out_response.dart';
import '../../features/dashboard/domain/ticket_parking_info.dart';
import '../../features/check_in/models/check_in_response.dart';
import '../../core/connectivity/internet_reachability.dart';
import '../../core/logging/valet_log.dart';
import '../../features/check_in/domain/check_in_form_data.dart';
import '../local/db/app_database.dart';
import '../remote/transactions_api.dart';

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

/// JSON blob stored in [Tickets.driverOut] between check-in and checkout finalize.
String? _encodeCheckoutMetaDriverOut({
  String? customerName,
  String? valetType,
  String? parkingLevel,
  String? parkingSlot,
}) {
  final map = <String, dynamic>{};
  final name = customerName?.trim();
  final valet = valetType?.trim();
  final level = parkingLevel?.trim();
  final slot = parkingSlot?.trim();
  if (name != null && name.isNotEmpty) map['customer_name'] = name;
  if (valet != null && valet.isNotEmpty) map['valet_type'] = valet;
  if (level != null && level.isNotEmpty) map['parking_level'] = level;
  if (slot != null && slot.isNotEmpty) map['parking_slot'] = slot;
  if (map.isEmpty) return null;
  return jsonEncode(map);
}

CheckoutTicketDisplay? _checkoutDisplayFromDriverOutMeta(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty || !t.startsWith('{')) return null;
  try {
    final body = jsonDecode(t);
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final name = map['customer_name']?.toString().trim();
    final level = map['parking_level']?.toString().trim() ?? '';
    final slot = map['parking_slot']?.toString().trim() ?? '';
    final parkingParts = <String>[
      if (level.isNotEmpty) level,
      if (slot.isNotEmpty) slot,
    ];
    final valetRaw = map['valet_type']?.toString().trim() ?? '';
    return CheckoutTicketDisplay(
      customerName: (name == null || name.isEmpty) ? null : name,
      parkingLine: parkingParts.isEmpty ? null : parkingParts.join(' · '),
      valetTypeLabel: valetRaw.isEmpty ? null : TicketService._prettyValetType(valetRaw),
    );
  } catch (_) {
    return null;
  }
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
    final now = PhilippineTime.iso8601Now();
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
    final now = PhilippineTime.iso8601Now();

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
    });

    return (_db.select(_db.tickets)..where((t) => t.id.equals(ticketId.trim())))
        .getSingle();
  }

  /// `TKT-{YYMMDD}-{DEVICE}-{HHmmss}` — PH wall date/time, last 4 of [android_id_hash].
  ///
  /// [shiftId] is unused; kept for call-site compatibility.
  Future<String> generateTicketId(String shiftId) async {
    final device = await _deviceTicketSuffix();
    final ph = PhilippineTime.now();
    final yymmdd =
        '${(ph.year % 100).toString().padLeft(2, '0')}'
        '${ph.month.toString().padLeft(2, '0')}'
        '${ph.day.toString().padLeft(2, '0')}';
    final hhmmss =
        '${ph.hour.toString().padLeft(2, '0')}'
        '${ph.minute.toString().padLeft(2, '0')}'
        '${ph.second.toString().padLeft(2, '0')}';
    return 'TKT-$yymmdd-$device-$hhmmss';
  }

  /// Last 4 chars of stored `android_id_hash` (uppercase hex), else `0000`.
  Future<String> _deviceTicketSuffix() async {
    final identity = await (_db.select(_db.deviceIdentity)..limit(1))
        .getSingleOrNull();
    var hash = identity?.androidIdHash.trim() ?? '';
    if (hash.isEmpty) {
      hash = await DeviceIdService.sha256RawAndroidId();
    }
    final normalized = hash.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (normalized.length >= 4) {
      return normalized.substring(normalized.length - 4);
    }
    return '0000';
  }

  Future<Ticket> createTicket({
    required CheckInFormData data,
    required String shiftId,
    required String userId,
    required String branchId,
  }) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final id = await generateTicketId(shiftId);
    final now = PhilippineTime.iso8601Now();

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
    });

    return (_db.select(_db.tickets)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Writes PNG bytes under app documents and returns the file.
  Future<File> saveSignatureToFile(Uint8List bytes, String ticketNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    final sigDir = Directory('${dir.path}/signatures');
    if (!await sigDir.exists()) await sigDir.create(recursive: true);
    final safeId = ticketNumber.trim().replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${sigDir.path}/${safeId}_signature.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Promotes draft → `active` with full check-in fields (offline-first).
  Future<Ticket> persistCheckInLocally({
    required String ticketId,
    required String signaturePath,
    required String shiftId,
    required String userId,
    required String branchId,
    required String plateNumber,
    required String vehicleBrand,
    required String vehicleColor,
    required String vehicleType,
    required String cellphoneNumber,
    required String damageMarkersJson,
    required String personalBelongingsJson,
    String? driverIn,
    String? customerName,
    String? valetType,
    String? parkingLevel,
    String? parkingSlot,
    String? slotId,
  }) async {
    final tid = ticketId.trim();
    final existing = await ticketById(tid);
    if (existing == null) {
      throw StateError('No ticket for id $tid');
    }
    if (existing.shiftId != shiftId || existing.userId != userId) {
      throw StateError('Ticket shift/user mismatch');
    }
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final now = PhilippineTime.iso8601Now();
    final metaDriverOut = _encodeCheckoutMetaDriverOut(
      customerName: customerName,
      valetType: valetType,
      parkingLevel: parkingLevel,
      parkingSlot: parkingSlot,
    );
    final parkingJson = TicketService._encodeParkingInfoColumn(
      level: parkingLevel,
      slot: parkingSlot,
    );
    final slotUuid = slotId?.trim() ?? '';

    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        branchId: Value(bid),
        plateNumber: Value(plateNumber),
        vehicleBrand: Value(vehicleBrand),
        vehicleColor: Value(vehicleColor),
        vehicleType: Value(vehicleType),
        cellphoneNumber: Value(cellphoneNumber),
        damageMarkers: Value(damageMarkersJson),
        personalBelongings: Value(personalBelongingsJson),
        signaturePng: Value(signaturePath),
        checkInAt: Value(now),
        status: const Value('active'),
        syncStatus: const Value('pending'),
        driverIn: Value(_normalizedDriverName(driverIn)),
        parkingInfo: Value(parkingJson),
        driverOut: Value(metaDriverOut),
        slotId: slotUuid.isNotEmpty ? Value(slotUuid) : const Value.absent(),
      ),
    );

    return (_db.select(_db.tickets)..where((t) => t.id.equals(tid))).getSingle();
  }

  Future<void> updateServerTicketId(String localTicketId, String serverId) async {
    final tid = localTicketId.trim();
    final sid = serverId.trim();
    if (tid.isEmpty || sid.isEmpty) return;
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        serverTicketId: Value(sid),
        syncStatus: const Value('synced'),
      ),
    );
  }

  /// Enqueues multipart check-in for [SyncCubit] when offline.
  Future<void> enqueueCheckInSync({
    required String localTicketId,
    required Map<String, dynamic> payload,
  }) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        id: _uuid.v4(),
        operation: 'checkin',
        queueTableName: 'tickets',
        recordId: tid,
        payload: jsonEncode(payload),
        syncStatus: 'pending',
        createdAt: now,
      ),
    );
  }

  /// Processes a queued check-in row via `POST /transactions/check-in`.
  Future<CheckInResponse> syncQueuedCheckIn(
    Map<String, dynamic> body,
    String token,
  ) async {
    final path = body['signature_path']?.toString().trim() ?? '';
    if (path.isEmpty) {
      throw StateError('Queued check-in missing signature_path');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Signature file missing: $path');
    }

    final vehicle = _mapField(body['vehicle']);
    final belongings = _stringListField(body['belongings']);
    final damages = _damageListField(body['damages']);

    final localId =
        body['local_ticket_id']?.toString().trim() ??
        body['ticket_id']?.toString().trim() ??
        '';

    final slotId = body['slot_id']?.toString().trim() ?? '';
    if (slotId.isEmpty) {
      throw StateError('Queued check-in missing slot_id');
    }

    final response = await _transactionsApi.submitCheckIn(
      token: token,
      ticketNumber: localId,
      slotId: slotId,
      contactNumber: body['contact_number']?.toString() ?? '',
      valetType: body['valet_type']?.toString() ?? 'standard_valet',
      signatureFile: file,
      vehicle: vehicle,
      belongings: belongings,
      damages: damages,
      customerName: body['customer_name']?.toString(),
      driverIn: body['driver_in']?.toString(),
      notes: body['notes']?.toString(),
    );

    if (localId.isNotEmpty) {
      await updateServerTicketId(localId, response.id);
      final queuedSlotId = body['slot_id']?.toString().trim() ?? '';
      if (queuedSlotId.isNotEmpty) {
        final row = await ticketById(localId);
        if (row != null && (row.slotId?.trim().isEmpty ?? true)) {
          await (_db.update(_db.tickets)..where((t) => t.id.equals(localId)))
              .write(TicketsCompanion(slotId: Value(queuedSlotId)));
        }
      }
    }
    return response;
  }

  static String? _encodeParkingInfoColumn({
    String? area,
    String? level,
    String? slot,
  }) {
    final info = TicketParkingInfo(area: area, level: level, slot: slot);
    return info.toJsonString();
  }

  static TicketParkingInfo? _parkingFromTransactionJson(
    Map<String, dynamic> json,
  ) {
    final parking = _mapField(json['parking']);
    if (parking.isEmpty) return null;
    final info = TicketParkingInfo.fromParkingMap(parking);
    return info.hasAny ? info : null;
  }

  static TicketParkingInfo? _parkingFromTicketRow(Ticket ticket) {
    final stored = ticket.parkingInfo?.trim() ?? '';
    if (stored.isNotEmpty) {
      final info = TicketParkingInfo.fromJsonString(stored);
      if (info.hasAny) return info;
    }
    final meta = TicketParkingInfo.fromDriverOutMeta(ticket.driverOut);
    if (meta.hasAny) return meta;
    return null;
  }

  static Map<String, dynamic> _mapField(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final v = jsonDecode(raw);
        if (v is Map) return Map<String, dynamic>.from(v);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  static List<String> _stringListField(dynamic raw) {
    if (raw is List) {
      return [
        for (final e in raw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final v = jsonDecode(raw);
        if (v is List) return _stringListField(v);
      } catch (_) {}
    }
    return const [];
  }

  static List<Map<String, dynamic>> _damageListField(dynamic raw) {
    if (raw is List) {
      return [
        for (final e in raw)
          if (e is Map<String, dynamic>) e
          else if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final v = jsonDecode(raw);
        if (v is List) return _damageListField(v);
      } catch (_) {}
    }
    return const [];
  }

  /// Guest name, parking, and valet type from [Tickets.driverOut] JSON or sync queue.
  Future<CheckoutTicketDisplay?> checkoutDisplayForTicket(String ticketId) async {
    final id = ticketId.trim();
    if (id.isEmpty) return null;

    final ticket = await ticketById(id);
    if (ticket != null) {
      final fromMeta = _checkoutDisplayFromDriverOutMeta(ticket.driverOut);
      if (fromMeta != null) return fromMeta;
    }

    final row = await (_db.select(_db.syncQueue)
          ..where(
            (q) =>
                q.recordId.equals(id) &
                q.queueTableName.equals('tickets'),
          )
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final body = jsonDecode(row.payload);
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      final name = map['customer_name']?.toString().trim();
      final parking = _mapField(map['parking']);
      final level = parking['level']?.toString().trim() ?? '';
      final zone = parking['zone']?.toString().trim() ?? '';
      final slot = parking['slot']?.toString().trim() ?? '';
      final parkingParts = <String>[
        if (level.isNotEmpty) level,
        if (zone.isNotEmpty) zone,
        if (slot.isNotEmpty) slot,
      ];
      final valetRaw = map['valet_type']?.toString().trim() ?? '';
      return CheckoutTicketDisplay(
        customerName: (name == null || name.isEmpty) ? null : name,
        parkingLine: parkingParts.isEmpty ? null : parkingParts.join(' · '),
        valetTypeLabel: valetRaw.isEmpty ? null : _prettyValetType(valetRaw),
      );
    } catch (_) {
      return null;
    }
  }

  static String _prettyValetType(String raw) {
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((s) => s.isNotEmpty)
        .map(
          (w) =>
              '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
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

  /// Completes checkout locally (Drift). Server finalize is via POST check-out.
  Future<void> completeTicketCheckout({
    required String ticketId,
    required String checkOutAtIso,
    required double totalFee,
    required String damageMarkersJson,
    String? driverOut,
    String status = 'completed',
  }) async {
    ValetLog.info(
      'TicketService.completeTicketCheckout',
      'ticketId=$ticketId fee=$totalFee (local)',
    );
    await _db.transaction(() async {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId))).write(
            TicketsCompanion(
              checkOutAt: Value(checkOutAtIso),
              fee: Value(totalFee),
              status: Value(status),
              damageMarkers: Value(damageMarkersJson),
              syncStatus: const Value('pending'),
              driverOut: Value(_normalizedDriverName(driverOut)),
            ),
          );
    });
  }

  /// Queues unified check-out for offline finalize (`operation: checkout/finalize`).
  Future<void> enqueueCheckoutFinalize({
    required String ticketId,
    required String? serverTicketId,
    required double amount,
    required String timeOut,
    required bool isOvernight,
    required bool ticketLost,
    required Map<String, dynamic> preview,
    required List<Map<String, dynamic>> conditionCheckout,
    String? driverOut,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final payload = jsonEncode(<String, dynamic>{
      'ticket_number': tid,
      'server_ticket_id': serverTicketId?.trim(),
      'amount': amount,
      'time_out': timeOut,
      'is_overnight': isOvernight,
      'ticket_lost': ticketLost,
      'preview': preview,
      'condition_checkout': conditionCheckout,
      if (driverOut != null && driverOut.trim().isNotEmpty)
        'driver_out': driverOut.trim(),
    });
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: _uuid.v4(),
            operation: 'checkout/finalize',
            queueTableName: 'tickets',
            recordId: tid,
            payload: payload,
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
    ValetLog.info(
      'TicketService.enqueueCheckoutFinalize',
      'queued ticket=$tid',
    );
  }

  /// Processes a queued checkout/finalize row via `POST /transactions/{id}/check-out`.
  Future<CheckOutResponse> syncQueuedCheckoutFinalize(
    Map<String, dynamic> body,
    String token,
  ) async {
    final serverId = body['server_ticket_id']?.toString().trim() ?? '';
    if (serverId.isEmpty) {
      throw StateError('Queued checkout/finalize missing server_ticket_id');
    }

    final amountRaw = body['amount'] ?? body['amount_paid'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse('$amountRaw') ?? 0.0;

    final timeOut = body['time_out']?.toString().trim() ?? '';
    if (timeOut.isEmpty) {
      throw StateError('Queued checkout/finalize missing time_out');
    }

    final previewRaw = body['preview'];
    if (previewRaw is! Map) {
      throw StateError('Queued checkout/finalize missing preview');
    }
    final preview = Map<String, dynamic>.from(previewRaw);

    final isOvernight = body['is_overnight'] == true;
    final ticketLost = body['ticket_lost'] == true;

    final condition = body['condition_checkout'];
    final conditionList = condition is List
        ? [
            for (final e in condition)
              if (e is Map) Map<String, dynamic>.from(e),
          ]
        : <Map<String, dynamic>>[];

    final driverOut = body['driver_out']?.toString();

    return _transactionsApi.submitCheckOut(
      token: token,
      ticketId: serverId,
      amount: amount,
      timeOut: timeOut,
      isOvernight: isOvernight,
      ticketLost: ticketLost,
      preview: preview,
      driverOut: driverOut,
      conditionCheckout: conditionList,
    );
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

  /// Recent-transaction detail: `GET /transactions/{id}` when online, else local Drift.
  ///
  /// [idOrTicketNumber] is the server UUID or `TKT-XXXX` from the dashboard list.
  Future<TicketDetailSnapshot?> loadTicketForDetail(
    String idOrTicketNumber,
  ) async {
    final key = idOrTicketNumber.trim();
    if (key.isEmpty) return null;

    if (!AppConfig.useStubApi &&
        await InternetReachability.hasInternet()) {
      final token = await _activeBearer();
      if (token != null && token.isNotEmpty) {
        try {
          final map = await _transactionsApi.getTransactionById(
            token: token,
            id: key,
          );
          final parking = TicketService._parkingFromTransactionJson(map);
          final ticket = await _upsertFromServerTransactionJson(map);
          return TicketDetailSnapshot(
            ticket: ticket,
            parking: parking ?? TicketService._parkingFromTicketRow(ticket),
          );
        } on TransactionsApiException catch (e, st) {
          ValetLog.error(
            'TicketService.loadTicketForDetail',
            'GET /transactions/$key failed — local fallback',
            e,
            st,
          );
        } catch (e, st) {
          ValetLog.error(
            'TicketService.loadTicketForDetail',
            'GET /transactions/$key failed — local fallback',
            e,
            st,
          );
        }
      }
    }

    return _localDetailSnapshot(key);
  }

  Future<TicketDetailSnapshot?> _localDetailSnapshot(String key) async {
    final ticket = await _localTicketByKey(key);
    if (ticket == null) return null;
    var parking = TicketService._parkingFromTicketRow(ticket);
    parking ??= await _parkingFromSyncQueue(ticket.id);
    return TicketDetailSnapshot(ticket: ticket, parking: parking);
  }

  Future<TicketParkingInfo?> _parkingFromSyncQueue(String ticketId) async {
    final row = await (_db.select(_db.syncQueue)
          ..where(
            (q) =>
                q.recordId.equals(ticketId.trim()) &
                q.queueTableName.equals('tickets'),
          )
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final body = jsonDecode(row.payload);
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      final parking = _mapField(map['parking']);
      if (parking.isEmpty) return null;
      final info = TicketParkingInfo.fromParkingMap(parking);
      return info.hasAny ? info : null;
    } catch (_) {
      return null;
    }
  }

  Future<Ticket?> _localTicketByKey(String key) async {
    final byId = await ticketById(key);
    if (byId != null) return byId;
    return _ticketByServerId(key);
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
    ValetLog.debug('TicketService.getTransactionById', 'id=$serverId');
    final map = await _transactionsApi.getTransactionById(
      token: token,
      id: serverId,
    );
    final out = await _upsertFromServerTransactionJson(map);
    ValetLog.info(
      'TicketService.getTransactionById',
      'ok localId=${out.id} serverId=$serverId status=${out.status}',
    );
    return out;
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
        json['qr_code']?.toString().trim() ??
        '';
    if (ticketNum.isEmpty) {
      throw TransactionsApiException('Server response missing ticket_number.');
    }

    final fields = _fieldsFromServerTransactionJson(json);

    final existing =
        await _ticketByServerId(serverUuid) ?? await ticketById(ticketNum);
    if (existing != null) {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(existing.id)))
          .write(
        TicketsCompanion(
          serverTicketId: Value(serverUuid),
          plateNumber: Value(fields.plateNumber),
          vehicleBrand: Value(fields.vehicleBrand),
          vehicleColor: Value(fields.vehicleColor),
          vehicleType: Value(fields.vehicleType),
          cellphoneNumber: Value(fields.cellphoneNumber),
          damageMarkers: Value(fields.damageMarkers),
          personalBelongings: Value(fields.personalBelongings),
          signaturePng: Value(fields.signaturePng),
          checkInAt: Value(fields.checkInAt),
          checkOutAt: Value(fields.checkOutAt),
          fee: Value(fields.fee),
          status: Value(fields.status),
          driverIn: Value(fields.driverIn),
          driverOut: Value(fields.driverOut),
          parkingInfo: Value(fields.parkingInfo),
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
            plateNumber: fields.plateNumber,
            vehicleBrand: fields.vehicleBrand,
            vehicleColor: fields.vehicleColor,
            vehicleType: fields.vehicleType,
            cellphoneNumber: fields.cellphoneNumber,
            damageMarkers: fields.damageMarkers,
            personalBelongings: fields.personalBelongings,
            signaturePng: Value(fields.signaturePng),
            checkInAt: fields.checkInAt,
            checkOutAt: Value(fields.checkOutAt),
            fee: Value(fields.fee),
            status: fields.status,
            syncStatus: 'synced',
            createdAt: now,
            serverTicketId: Value(serverUuid),
            driverIn: Value(fields.driverIn),
            driverOut: Value(fields.driverOut),
            parkingInfo: Value(fields.parkingInfo),
          ),
        );
    final out = await ticketById(ticketNum);
    if (out == null) {
      throw TransactionsApiException('Upsert failed after insert.');
    }
    return out;
  }

  static _ServerTicketFields _fieldsFromServerTransactionJson(
    Map<String, dynamic> json,
  ) {
    final vm = _vehicleMap(json);
    final plate =
        vm['plate_number']?.toString() ?? vm['plateNumber']?.toString() ?? '';
    final brandRaw = vm['brand']?.toString().trim() ?? '';
    final model = vm['model']?.toString().trim() ?? '';
    final brand = model.isEmpty ? brandRaw : '$brandRaw $model'.trim();
    final color = vm['color']?.toString() ?? '';
    final vtype = vm['type']?.toString() ?? '';
    final customer = _asStringKeyedMap(json['customer']) ?? const {};
    final phone = _scalarString(
          customer['contact_number'] ?? customer['contactNumber'],
        ) ??
        '';
    final checkOutAt = _parseCheckOutTime(json);
    var status = _normalizeTicketStatus(json['status']?.toString() ?? 'active');
    if (checkOutAt != null && status == 'active') {
      status = 'completed';
    }

    final parkingMap = _mapField(json['parking']);
    final parkingJson =
        TicketParkingInfo.fromParkingMap(parkingMap).toJsonString();

    return _ServerTicketFields(
      plateNumber: plate,
      vehicleBrand: brand,
      vehicleColor: color,
      vehicleType: vtype,
      cellphoneNumber: phone,
      damageMarkers: _encodeCheckInDamages(json),
      personalBelongings: _encodeBelongings(json),
      signaturePng: _checkInSignature(json),
      checkInAt: _parseCheckInTime(json),
      checkOutAt: checkOutAt,
      fee: _feeFromTransaction(json),
      status: status,
      driverIn: _normalizedDriverName(_scalarString(json['driver_in'])),
      driverOut: _normalizedDriverName(_scalarString(json['driver_out'])),
      parkingInfo: parkingJson,
    );
  }

  static Map<String, dynamic> _vehicleMap(Map<String, dynamic> json) {
    final vehicle = json['vehicle'];
    if (vehicle is Map<String, dynamic>) return vehicle;
    if (vehicle is Map) return Map<String, dynamic>.from(vehicle);
    return const <String, dynamic>{};
  }

  static String _parseCheckInTime(Map<String, dynamic> json) {
    final raw = json['time_in'] ??
        json['check_in_time'] ??
        json['checkInTime'] ??
        json['check_in_at'] ??
        json['checkInAt'] ??
        json['created_at'] ??
        json['createdAt'];
    return _parseIsoTime(raw) ?? DateTime.now().toIso8601String();
  }

  static String? _parseCheckOutTime(Map<String, dynamic> json) {
    final raw = json['time_out'] ?? json['timeOut'] ?? json['check_out_at'];
    return _parseIsoTime(raw);
  }

  static String? _parseIsoTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    return dt?.toIso8601String();
  }

  static String? _scalarString(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _feeFromTransaction(Map<String, dynamic> json) {
    for (final key in const ['amount', 'amount_paid', 'amountPaid', 'fee']) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is Map && raw.isEmpty) continue;
      if (raw != null) {
        final parsed = double.tryParse(raw.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String _encodeBelongings(Map<String, dynamic> json) {
    final raw = json['belongings'];
    if (raw is List) {
      return jsonEncode([
        for (final e in raw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ]);
    }
    return '[]';
  }

  static String _encodeCheckInDamages(Map<String, dynamic> json) {
    final cond = _asStringKeyedMap(json['condition_checkin']) ??
        _asStringKeyedMap(json['conditionCheckin']);
    if (cond == null) return '[]';
    final damages = cond['damages'];
    if (damages is! List) return '[]';
    final out = <Map<String, dynamic>>[];
    for (final item in damages) {
      final m = _asStringKeyedMap(item);
      if (m == null || m.isEmpty) continue;
      out.add(<String, dynamic>{
        'zone': m['zone']?.toString() ?? '',
        'type': m['type']?.toString() ?? '',
        'x': m['x'] is num ? (m['x'] as num).toDouble() : 0,
        'y': m['y'] is num ? (m['y'] as num).toDouble() : 0,
      });
    }
    return jsonEncode(out);
  }

  static String? _checkInSignature(Map<String, dynamic> json) {
    final cond = _asStringKeyedMap(json['condition_checkin']) ??
        _asStringKeyedMap(json['conditionCheckin']);
    if (cond == null) return null;
    return _scalarString(cond['signature']);
  }

  static String _normalizeTicketStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'lost') return 'lost';
    if (s == 'completed' || s == 'complete') return 'completed';
    if (s == 'draft') return 'draft';
    if (s == 'active' || s == 'parked') return 'active';
    return 'active';
  }

  static double? _feeFromLostResponse(Map<String, dynamic> m) {
    final f = m['fee'];
    if (f is num) return f.toDouble();
    if (f != null) return double.tryParse(f.toString());
    return null;
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

class _ServerTicketFields {
  const _ServerTicketFields({
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleColor,
    required this.vehicleType,
    required this.cellphoneNumber,
    required this.damageMarkers,
    required this.personalBelongings,
    required this.signaturePng,
    required this.checkInAt,
    required this.checkOutAt,
    required this.fee,
    required this.status,
    required this.driverIn,
    required this.driverOut,
    this.parkingInfo,
  });

  final String plateNumber;
  final String vehicleBrand;
  final String vehicleColor;
  final String vehicleType;
  final String cellphoneNumber;
  final String damageMarkers;
  final String personalBelongings;
  final String? signaturePng;
  final String checkInAt;
  final String? checkOutAt;
  final double? fee;
  final String status;
  final String? driverIn;
  final String? driverOut;
  final String? parkingInfo;
}
