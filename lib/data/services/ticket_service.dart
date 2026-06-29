import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatting/plate_number.dart';
import '../../core/formatting/vr_number.dart';
import '../../core/formatting/valet_type_format.dart';
import '../../core/api/transaction_payment_fields.dart';
import '../remote/check_in_exceptions.dart';
import '../../core/api/transaction_payment_summary.dart';
import '../../core/api/void_audit_info.dart';
import '../../features/check_out/models/checkout_preview_rates.dart';
import '../../core/pricing/transaction_payment_calculator.dart';
import '../../core/config/app_config.dart';
import '../../core/services/device_id_service.dart';
import '../../core/time/check_in_time_resolution.dart';
import '../../core/time/philippine_time.dart';
import '../../features/check_out/domain/checkout_ticket_display.dart';
import '../../features/check_out/models/check_out_response.dart';
import '../../features/dashboard/domain/ticket_parking_info.dart';
import '../../features/check_in/domain/check_in_form_data.dart';
import '../../features/check_in/models/batch_check_in_response.dart';
import '../../features/check_in/models/check_in_response.dart';
import '../../core/connectivity/internet_reachability.dart';
import '../../core/logging/valet_log.dart';
import '../../core/sync/local_sync_notifier.dart';
import '../local/db/app_database.dart';
import '../remote/dashboard_api.dart';
import 'parking_layout_service.dart';
import '../remote/transactions_api.dart';
import 'batch_check_in_payload.dart';
import 'batch_check_out_payload.dart';
import 'check_in_sync_payload.dart';
import 'rate_fetch_service.dart';
import 'rate_service.dart';

/// Result of [TicketService.voidCachedTicket] / [TicketService.voidExpressTicket].
enum ExpressVoidResult {
  /// Void applied on the server (or already void there).
  applied,

  /// Void saved locally; `sync_queue` will POST void when online.
  queuedForSync,
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

/// JSON blob stored in [Tickets.driverOut] between check-in and checkout finalize.
String? _encodeCheckoutMetaDriverOut({
  String? customerName,
  String? valetType,
  String? parkingLevel,
  String? parkingSlot,
  String? driverOutName,
}) {
  final map = <String, dynamic>{};
  final name = customerName?.trim();
  final valet = valetType?.trim();
  final level = parkingLevel?.trim();
  final slot = parkingSlot?.trim();
  final driverOut = driverOutName?.trim();
  if (name != null && name.isNotEmpty) map['customer_name'] = name;
  if (valet != null && valet.isNotEmpty) map['valet_type'] = valet;
  if (level != null && level.isNotEmpty) map['parking_level'] = level;
  if (slot != null && slot.isNotEmpty) map['parking_slot'] = slot;
  if (driverOut != null && driverOut.isNotEmpty) map['driver_out'] = driverOut;
  if (map.isEmpty) return null;
  return jsonEncode(map);
}

/// Plain driver-out name from [Tickets.driverOut] (meta JSON or post-checkout scalar).
String? driverOutNameFromColumn(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  if (t.startsWith('{')) {
    try {
      final body = jsonDecode(t);
      if (body is Map) {
        final name = body['driver_out']?.toString().trim();
        return name != null && name.isNotEmpty ? name : null;
      }
    } catch (_) {}
    return null;
  }
  return t;
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
      valetTypeLabel: valetRaw.isEmpty ? null : ValetTypeFormat.label(valetRaw),
    );
  } catch (_) {
    return null;
  }
}

/// `tickets` + `sync_queue` persistence and best-effort REST.
class TicketService {
  TicketService(
    this._db,
    this._dio,
    this._transactionsApi,
    this._dashboardApi,
    RateService rates,
    this._rateFetch,
    this._parkingLayout, {
    LocalSyncNotifier? localSyncNotifier,
  })  : _paymentCalculator = TransactionPaymentCalculator(rates),
        _localSyncNotifier = localSyncNotifier;

  final AppDatabase _db;
  final Dio _dio;
  final TransactionsApi _transactionsApi;
  final DashboardApi _dashboardApi;
  final RateFetchService _rateFetch;
  final ParkingLayoutService _parkingLayout;
  final TransactionPaymentCalculator _paymentCalculator;
  final LocalSyncNotifier? _localSyncNotifier;

  void _notifyLocalSyncQueueChanged() {
    _localSyncNotifier?.notifyLocalQueueChanged();
  }

  static const _uuid = Uuid();

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Returns [s] if it is a valid UUID, otherwise null.
  static String? _validUuidOrNull(String s) {
    final t = s.trim();
    return _uuidPattern.hasMatch(t) ? t : null;
  }

  /// Branch UUID from the device identity row (guaranteed to be a UUID).
  Future<String?> get _deviceBranchId async {
    final identity = await (_db.select(_db.deviceIdentity)..limit(1))
        .getSingleOrNull();
    final bid = identity?.branchId.trim() ?? '';
    return _validUuidOrNull(bid);
  }

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
    await _db
        .into(_db.tickets)
        .insert(
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
    await (_db.delete(
      _db.tickets,
    )..where((t) => t.shiftId.equals(sid) & t.status.equals('draft'))).go();
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
      await (_db.update(
        _db.tickets,
      )..where((t) => t.id.equals(ticketId.trim()))).write(
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

    return (_db.select(
      _db.tickets,
    )..where((t) => t.id.equals(ticketId.trim()))).getSingle();
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
    final identity = await (_db.select(
      _db.deviceIdentity,
    )..limit(1)).getSingleOrNull();
    var hash = identity?.androidIdHash.trim() ?? '';
    if (hash.isEmpty) {
      hash = await DeviceIdService.sha256RawAndroidId();
    }
    final normalized = hash
        .replaceAll(RegExp(r'[^0-9A-Fa-f]'), '')
        .toUpperCase();
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
      await _db
          .into(_db.tickets)
          .insert(
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
    required String vrNo,
    String? driverIn,
    String? driverOut,
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
    final vr = normalizeVrNumber(vrNo);
    if (vr.isEmpty) {
      throw StateError('VR number is required');
    }
    await ensureVrNoAvailable(vr, excludeTicketId: tid);
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final now = PhilippineTime.iso8601Now();
    final metaDriverOut = _encodeCheckoutMetaDriverOut(
      customerName: customerName,
      valetType: valetType,
      parkingLevel: parkingLevel,
      parkingSlot: parkingSlot,
      driverOutName: driverOut,
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
        vrNo: Value(vr),
      ),
    );

    if (slotUuid.isNotEmpty) {
      final layoutBranchId = _validUuidOrNull(bid) ?? await _deviceBranchId;
      if (layoutBranchId != null) {
        await _parkingLayout.markSlotOccupiedForTicket(
          branchId: layoutBranchId,
          slotId: slotUuid,
        );
      }
    }

    return (_db.select(
      _db.tickets,
    )..where((t) => t.id.equals(tid))).getSingle();
  }

  /// Inserts an express cashier ticket — completed at intake, no check-out.
  Future<Ticket> persistExpressCheckInLocally({
    required String ticketId,
    required String shiftId,
    required String userId,
    required String branchId,
    required String plateNumber,
    required double amount,
    required String vrNo,
    String? driverIn,
    String? driverOut,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) {
      throw StateError('Ticket id is required');
    }
    final existing = await ticketById(tid);
    if (existing != null) {
      throw StateError('Ticket number already exists');
    }
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final now = PhilippineTime.iso8601Now();
    final vr = normalizeVrNumber(vrNo);
    if (vr.isEmpty) {
      throw StateError('VR number is required');
    }
    await ensureVrNoAvailable(vr);

    await _db.into(_db.tickets).insert(
          TicketsCompanion.insert(
            id: tid,
            shiftId: shiftId,
            userId: userId,
            branchId: bid,
            plateNumber: plateNumber,
            vehicleBrand: '',
            vehicleColor: '',
            vehicleType: '',
            cellphoneNumber: '',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            checkOutAt: Value(now),
            fee: Value(amount),
            status: 'completed',
            syncStatus: 'pending',
            createdAt: now,
            isExpressCashier: const Value(true),
            vrNo: Value(vr),
            driverIn: Value(_normalizedDriverName(driverIn)),
            driverOut: Value(_normalizedDriverName(driverOut)),
          ),
        );

    return (_db.select(_db.tickets)..where((t) => t.id.equals(tid)))
        .getSingle();
  }

  /// Removes a failed express save that never reached the server (validation).
  Future<void> deleteExpressPendingTicket(String ticketId) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    final row = await ticketById(tid);
    if (row == null ||
        !row.isExpressCashier ||
        row.syncStatus != 'pending') {
      return;
    }
    await (_db.delete(_db.tickets)..where((t) => t.id.equals(tid))).go();
    _notifyLocalSyncQueueChanged();
  }

  /// Express cashier tickets on [shiftId], newest first (includes voided).
  Future<List<Ticket>> expressTicketsForShift(String shiftId) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.shiftId.equals(sid) &
                t.isExpressCashier.equals(true),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)]))
        .get();
  }

  /// GET `/transactions` for today, upserts express rows into Drift for [shiftId].
  Future<void> syncExpressTransactionsForToday({
    required String token,
    required String shiftId,
  }) async {
    await cacheTodayServerTransactionsForShift(
      token: token,
      shiftId: shiftId,
      expressOnly: true,
    );
  }

  /// Upserts today's server transactions into Drift for offline void/edit.
  Future<int> cacheTodayServerTransactionsForShift({
    required String token,
    required String shiftId,
    bool expressOnly = false,
    bool standardOnly = false,
  }) async {
    if (AppConfig.useStubApi) return 0;
    if (!await InternetReachability.hasInternet()) return 0;

    final rows = await _fetchTodayServerTransactions(token);
    return cacheTransactionsFromServerJsonList(
      rows: rows,
      shiftId: shiftId,
      expressOnly: expressOnly,
      standardOnly: standardOnly,
    );
  }

  /// Upserts server transaction JSON rows into Drift (no sync_queue).
  Future<int> cacheTransactionsFromServerJsonList({
    required List<Map<String, dynamic>> rows,
    required String shiftId,
    bool expressOnly = false,
    bool standardOnly = false,
  }) async {
    if (rows.isEmpty) return 0;
    var cached = 0;
    for (final row in rows) {
      final isExpress = _isExpressServerTransactionJson(row);
      if (expressOnly && !isExpress) continue;
      if (standardOnly && isExpress) continue;
      if (!_isTransactionToday(row)) continue;
      try {
        await _upsertFromServerTransactionJson(
          row,
          shiftIdOverride: shiftId,
          markExpressCashier: isExpress,
        );
        cached++;
      } catch (e, st) {
        ValetLog.error(
          'TicketService.cacheTransactionsFromServerJsonList',
          'upsert failed serverId=${row['id']}',
          e,
          st,
        );
      }
    }
    if (cached > 0) {
      _notifyLocalSyncQueueChanged();
    }
    return cached;
  }

  /// Caches dashboard `recent_transactions` into Drift for the open shift.
  Future<int> cacheDashboardRecentTransactions({
    required List<Map<String, dynamic>> transactionJsonRows,
    required String shiftId,
    bool standardOnly = true,
  }) {
    return cacheTransactionsFromServerJsonList(
      rows: transactionJsonRows,
      shiftId: shiftId,
      standardOnly: standardOnly,
      expressOnly: !standardOnly,
    );
  }

  /// Voids a locally cached ticket and syncs void to the server when applicable.
  Future<ExpressVoidResult> voidCachedTicket({
    required String localTicketId,
    String? reason,
  }) async {
    final tid = localTicketId.trim();
    final row = await ticketById(tid);
    if (row == null) {
      throw TransactionsApiException('Ticket not found.');
    }
    if (row.status == 'void') {
      await _ensureVoidQueuedForTicket(tid, row.serverTicketId, reason);
      return ExpressVoidResult.queuedForSync;
    }

    await _cancelPendingCheckInQueueForTicket(tid);
    await _markTicketVoidLocally(tid, reason);

    var serverId = row.serverTicketId?.trim() ?? '';
    if (serverId.isEmpty && await InternetReachability.hasInternet()) {
      final token = await _activeBearer();
      if (token != null && token.isNotEmpty) {
        final linked = await reconcileLocalTicketFromServerLookup(
          localTicketId: tid,
          token: token,
        );
        if (linked) {
          serverId = (await ticketById(tid))?.serverTicketId?.trim() ?? '';
        }
      }
    }

    if (serverId.isNotEmpty && await InternetReachability.hasInternet()) {
      try {
        await requestTicketVoid(serverTicketId: serverId, reason: reason);
        await _markVoidQueuesSyncedForTicket(tid);
        return ExpressVoidResult.applied;
      } on TransactionsApiException catch (e) {
        if (e.statusCode == 409) {
          await _markVoidQueuesSyncedForTicket(tid);
          return ExpressVoidResult.applied;
        }
        rethrow;
      } on DioException catch (e) {
        if (!_isUncertainNetworkDio(e)) rethrow;
      }
    }

    await enqueueTicketVoid(
      localTicketId: tid,
      serverTicketId: serverId.isNotEmpty ? serverId : null,
      reason: reason,
    );
    return ExpressVoidResult.queuedForSync;
  }

  /// Voids an express ticket locally and syncs void to the server when a record
  /// exists (or may exist after a lost check-in response).
  Future<ExpressVoidResult> voidExpressTicket({
    required String localTicketId,
    String? reason,
  }) async {
    final tid = localTicketId.trim();
    final row = await ticketById(tid);
    if (row == null || !row.isExpressCashier) {
      throw TransactionsApiException('Express ticket not found.');
    }
    return voidCachedTicket(localTicketId: tid, reason: reason);
  }

  Future<void> _ensureVoidQueuedForTicket(
    String localTicketId,
    String? serverTicketId,
    String? reason,
  ) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    final hasPendingVoidQueue = await (_db.select(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.operation.equals('void') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .get();
    if (hasPendingVoidQueue.isNotEmpty) return;

    final sid = serverTicketId?.trim() ?? '';
    if (sid.isEmpty &&
        !await InternetReachability.hasInternet()) {
      await enqueueTicketVoid(
        localTicketId: tid,
        reason: reason,
      );
      return;
    }
    if (sid.isNotEmpty && await InternetReachability.hasInternet()) {
      try {
        await requestTicketVoid(serverTicketId: sid, reason: reason);
        await _markVoidQueuesSyncedForTicket(tid);
      } on TransactionsApiException catch (e) {
        if (e.statusCode == 409) {
          await _markVoidQueuesSyncedForTicket(tid);
        } else {
          await enqueueTicketVoid(
            localTicketId: tid,
            serverTicketId: sid,
            reason: reason,
          );
        }
      }
      return;
    }
    await enqueueTicketVoid(
      localTicketId: tid,
      serverTicketId: sid.isNotEmpty ? sid : null,
      reason: reason,
    );
  }

  static bool _isUncertainNetworkDio(DioException e) {
    if (e.error is SocketException) return true;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Future<void> _cancelPendingCheckInQueueForTicket(String localTicketId) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('checkin') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
  }

  Future<void> _markVoidQueuesSyncedForTicket(String ticketId) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('void') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
  }

  Future<void> _markTicketVoidLocally(
    String localTicketId,
    String? reason,
  ) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    final trimmedReason = reason?.trim();
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        status: const Value('void'),
        voidReason: trimmedReason != null && trimmedReason.isNotEmpty
            ? Value(trimmedReason)
            : const Value.absent(),
        pendingVoidRequest: const Value(false),
        pendingVoidReason: const Value(null),
      ),
    );
    _notifyLocalSyncQueueChanged();
  }

  /// Queues `POST /tickets/:id/void` for when the device is back online.
  ///
  /// When [serverTicketId] is omitted, sync resolves the server UUID from the
  /// local ticket / today's transaction list before calling void.
  Future<void> enqueueTicketVoid({
    required String localTicketId,
    String? serverTicketId,
    String? reason,
  }) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    final sid = serverTicketId?.trim() ?? '';

    final existing = await (_db.select(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('void') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final payload = jsonEncode(<String, dynamic>{
      'local_ticket_id': tid,
      'ticket_number': tid,
      if (sid.isNotEmpty) 'server_ticket_id': sid,
      if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
    });
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: _uuid.v4(),
            operation: 'void',
            queueTableName: 'tickets',
            recordId: tid,
            payload: payload,
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
    _notifyLocalSyncQueueChanged();
  }

  /// Processes a queued ticket void row.
  Future<void> syncQueuedTicketVoid(
    Map<String, dynamic> body,
    String token,
  ) async {
    final localId =
        body['local_ticket_id']?.toString().trim() ??
        body['ticket_number']?.toString().trim() ??
        '';
    final reason = body['reason']?.toString();

    final serverId = await _resolveServerIdForQueuedVoid(
      body: body,
      localId: localId,
      token: token,
    );
    if (serverId == null || serverId.isEmpty) {
      ValetLog.info(
        'TicketService.syncQueuedTicketVoid',
        'no server record for localId=$localId — local void only',
      );
      return;
    }

    if (localId.isNotEmpty) {
      await updateServerTicketId(localId, serverId);
    }

    try {
      final voidBody = await _transactionsApi.requestVoid(
        token: token,
        ticketId: serverId,
        reason: reason,
      );
      if (localId.isNotEmpty) {
        final voidMeta = _voidAuditCompanion(voidBody);
        await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
          TicketsCompanion(
            status: const Value('void'),
            pendingVoidRequest: const Value(false),
            pendingVoidReason: const Value(null),
            voidReason: voidMeta.voidReason,
            voidedByJson: voidMeta.voidedByJson,
            voidedAt: voidMeta.voidedAt,
          ),
        );
      }
    } on TransactionsApiException catch (e) {
      if (e.statusCode == 409 && localId.isNotEmpty) {
        await _markTicketVoidLocally(localId, reason);
        return;
      }
      rethrow;
    }
  }

  Future<String?> _resolveServerIdForQueuedVoid({
    required Map<String, dynamic> body,
    required String localId,
    required String token,
  }) async {
    final fromPayload = body['server_ticket_id']?.toString().trim() ?? '';
    if (fromPayload.isNotEmpty) return fromPayload;

    if (localId.isEmpty) return null;
    final ticket = await ticketById(localId);
    if (ticket == null) return null;

    final fromRow = ticket.serverTicketId?.trim() ?? '';
    if (fromRow.isNotEmpty) return fromRow;

    return resolveServerTransactionIdByVr(
      token: token,
      vrNo: ticket.vrNo ?? '',
      plateNumber: ticket.plateNumber,
      ticketNumber: ticket.id,
    );
  }

  Future<void> updateServerTicketId(
    String localTicketId,
    String serverId,
  ) async {
    final tid = localTicketId.trim();
    final sid = serverId.trim();
    if (tid.isEmpty || sid.isEmpty) return;
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        serverTicketId: Value(sid),
        syncStatus: Value(await _resolvedSyncStatusForTicket(tid)),
      ),
    );
    _notifyLocalSyncQueueChanged();
  }

  Future<bool> _hasUnsyncedQueueForTicket(String ticketId) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return false;
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM sync_queue
WHERE record_id = ? AND sync_status IN ('pending', 'failed')
''',
      variables: [Variable.withString(tid)],
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return ((row.data['c'] as num?)?.toInt() ?? 0) > 0;
  }

  Future<String> _resolvedSyncStatusForTicket(String ticketId) async {
    if (await _hasUnsyncedQueueForTicket(ticketId)) return 'pending';
    final ticket = await ticketById(ticketId);
    if (ticket == null) return 'synced';
    if (ticket.status == 'completed' || ticket.status == 'lost') {
      final checkoutRows =
          await (_db.select(_db.syncQueue)..where(
                (q) =>
                    q.recordId.equals(ticketId) &
                    q.operation.equals('checkout/finalize'),
              ))
              .get();
      if (checkoutRows.any(
        (r) => r.syncStatus == 'pending' || r.syncStatus == 'failed',
      )) {
        return 'pending';
      }
      if (checkoutRows.isNotEmpty) return 'synced';
      if (ticket.checkOutAt?.trim().isNotEmpty ?? false) return 'synced';
    }
    return 'synced';
  }

  bool _localCheckoutAwaitingServerUpload(Ticket ticket) {
    if (ticket.status != 'completed' && ticket.status != 'lost') return false;
    return ticket.checkOutAt?.trim().isNotEmpty ?? false;
  }

  static bool _serverTransactionStillCheckedIn(Map<String, dynamic> txn) {
    final status = txn['status']?.toString().trim().toLowerCase() ?? '';
    if (status == 'completed' || status == 'lost' || status == 'void') {
      return false;
    }
    final timeOut = txn['time_out'] ?? txn['timeOut'];
    if (timeOut != null && '$timeOut'.trim().isNotEmpty) return false;
    return true;
  }

  /// Reopens checkout uploads that were cleared locally while the server still
  /// shows the vehicle checked in (e.g. after check-in sync swallowed checkout).
  Future<int> reconcileStaleCheckoutUploads(String token) async {
    final rows = await _db.customSelect(
      '''
SELECT DISTINCT t.id AS ticket_id
FROM tickets t
WHERE t.status IN ('completed', 'lost')
  AND t.check_out_at IS NOT NULL
  AND TRIM(t.check_out_at) != ''
  AND t.server_ticket_id IS NOT NULL
  AND TRIM(t.server_ticket_id) != ''
''',
      readsFrom: {_db.tickets, _db.syncQueue},
    ).get();

    var reopened = 0;
    for (final row in rows) {
      final ticketId = row.read<String>('ticket_id');
      final ticket = await ticketById(ticketId);
      final serverId = ticket?.serverTicketId?.trim() ?? '';
      if (ticket == null || serverId.isEmpty) continue;

      try {
        final txn = await _transactionsApi.getTransactionById(
          token: token,
          id: serverId,
        );
        if (!_serverTransactionStillCheckedIn(txn)) continue;

        final pendingCheckout = await (_db.select(_db.syncQueue)
              ..where(
                (q) =>
                    q.recordId.equals(ticketId) &
                    q.operation.equals('checkout/finalize') &
                    q.syncStatus.isIn(['pending', 'failed']),
              )
              ..limit(1))
            .getSingleOrNull();
        if (pendingCheckout != null) {
          await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId)))
              .write(const TicketsCompanion(syncStatus: Value('pending')));
          reopened++;
          continue;
        }

        final syncedCheckout = await (_db.select(_db.syncQueue)
              ..where(
                (q) =>
                    q.recordId.equals(ticketId) &
                    q.operation.equals('checkout/finalize') &
                    q.syncStatus.equals('synced'),
              )
              ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        if (syncedCheckout != null) {
          await (_db.update(_db.syncQueue)
                ..where((q) => q.id.equals(syncedCheckout.id)))
              .write(
            const SyncQueueCompanion(
              syncStatus: Value('pending'),
              retryCount: Value(0),
            ),
          );
          await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId)))
              .write(const TicketsCompanion(syncStatus: Value('pending')));
          reopened++;
          continue;
        }

        if (await _reenqueueCheckoutFromTicket(ticket)) {
          reopened++;
        }
      } catch (e, st) {
        ValetLog.error(
          'TicketService.reconcileStaleCheckoutUploads',
          'verify failed ticketId=$ticketId serverId=$serverId',
          e,
          st,
        );
      }
    }

    if (reopened > 0) {
      _notifyLocalSyncQueueChanged();
    }
    return reopened;
  }

  /// True when checkout finished locally but still needs a server upload.
  Future<bool> needsCheckoutServerUpload(Ticket ticket) async {
    if (ticket.status != 'completed' && ticket.status != 'lost') return false;
    final checkOut = ticket.checkOutAt?.trim() ?? '';
    if (checkOut.isEmpty) return false;
    if (await _hasUnsyncedQueueForTicket(ticket.id)) return true;
    if (ticket.syncStatus != 'synced') return true;
    final checkoutRows =
        await (_db.select(_db.syncQueue)..where(
              (q) =>
                  q.recordId.equals(ticket.id) &
                  q.operation.equals('checkout/finalize'),
            ))
            .get();
    if (checkoutRows.isEmpty) return true;
    return checkoutRows.any(
      (r) => r.syncStatus == 'pending' || r.syncStatus == 'failed',
    );
  }

  /// Reopens and uploads a single locally completed checkout when the server
  /// still shows the vehicle checked in.
  Future<int> retryCheckoutUploadForTicket(String ticketId, String token) async {
    final ticket = await ticketById(ticketId.trim());
    if (ticket == null) return 0;
    if (!await needsCheckoutServerUpload(ticket)) return 0;

    final serverId = ticket.serverTicketId?.trim() ?? '';
    if (serverId.isNotEmpty) {
      try {
        final txn = await _transactionsApi.getTransactionById(
          token: token,
          id: serverId,
        );
        if (!_serverTransactionStillCheckedIn(txn)) {
          await _markLocalCheckoutFullySynced(ticket.id);
          return 1;
        }
        await _reconcileStaleCheckoutForTicket(ticket, token);
      } catch (e, st) {
        ValetLog.error(
          'TicketService.retryCheckoutUploadForTicket',
          'verify failed ticketId=${ticket.id} serverId=$serverId',
          e,
          st,
        );
        return 0;
      }
    } else {
      await _reconcileStaleCheckoutForTicket(ticket, token);
    }

    final rows =
        await (_db.select(_db.syncQueue)..where(
              (q) =>
                  q.recordId.equals(ticket.id) &
                  q.operation.equals('checkout/finalize') &
                  q.syncStatus.isIn(['pending', 'failed']),
            ))
            .get();
    if (rows.isEmpty) {
      final updated = await ticketById(ticket.id);
      if (updated == null) return 0;
      return await needsCheckoutServerUpload(updated) ? 0 : 1;
    }
    return syncPendingCheckoutsBatch(rows, token);
  }

  Future<int> _reconcileStaleCheckoutForTicket(
    Ticket ticket,
    String token,
  ) async {
    final ticketId = ticket.id;
    final serverId = ticket.serverTicketId?.trim() ?? '';
    if (serverId.isEmpty) return 0;

    try {
      final txn = await _transactionsApi.getTransactionById(
        token: token,
        id: serverId,
      );
      if (!_serverTransactionStillCheckedIn(txn)) return 0;

      final pendingCheckout = await (_db.select(_db.syncQueue)
            ..where(
              (q) =>
                  q.recordId.equals(ticketId) &
                  q.operation.equals('checkout/finalize') &
                  q.syncStatus.isIn(['pending', 'failed']),
            )
            ..limit(1))
          .getSingleOrNull();
      if (pendingCheckout != null) {
        await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId)))
            .write(const TicketsCompanion(syncStatus: Value('pending')));
        _notifyLocalSyncQueueChanged();
        return 1;
      }

      final syncedCheckout = await (_db.select(_db.syncQueue)
            ..where(
              (q) =>
                  q.recordId.equals(ticketId) &
                  q.operation.equals('checkout/finalize') &
                  q.syncStatus.equals('synced'),
            )
            ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      if (syncedCheckout != null) {
        await (_db.update(_db.syncQueue)
              ..where((q) => q.id.equals(syncedCheckout.id)))
            .write(
          const SyncQueueCompanion(
            syncStatus: Value('pending'),
            retryCount: Value(0),
          ),
        );
        await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId)))
            .write(const TicketsCompanion(syncStatus: Value('pending')));
        _notifyLocalSyncQueueChanged();
        return 1;
      }

      if (await _reenqueueCheckoutFromTicket(ticket)) {
        _notifyLocalSyncQueueChanged();
        return 1;
      }
    } catch (e, st) {
      ValetLog.error(
        'TicketService._reconcileStaleCheckoutForTicket',
        'verify failed ticketId=$ticketId serverId=$serverId',
        e,
        st,
      );
    }
    return 0;
  }

  Future<void> _markLocalCheckoutFullySynced(String ticketId) async {
    await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId))).write(
      const TicketsCompanion(syncStatus: Value('synced')),
    );
    await (_db.update(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(ticketId) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('checkout/finalize') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
    _notifyLocalSyncQueueChanged();
  }

  Future<bool> _reenqueueCheckoutFromTicket(Ticket ticket) async {
    final amount = ticket.fee;
    final checkOutAt = ticket.checkOutAt?.trim() ?? '';
    if (amount == null || amount <= 0 || checkOutAt.isEmpty) return false;

    Map<String, dynamic>? appliedRate;
    final rateRaw = ticket.appliedRateJson?.trim() ?? '';
    if (rateRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(rateRaw);
        if (decoded is Map) {
          appliedRate = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    if (appliedRate == null || appliedRate.isEmpty) return false;

    double? cashTendered;
    final paymentRaw = ticket.paymentSummaryJson?.trim() ?? '';
    if (paymentRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(paymentRaw);
        if (decoded is Map) {
          cashTendered = TransactionPaymentFields.optionalMoney(
            decoded['cash_tendered'] ?? decoded['cashTendered'],
          );
        }
      } catch (_) {}
    }

    final conditionCheckout = <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(ticket.damageMarkers);
      if (decoded is List) {
        for (final entry in decoded) {
          if (entry is Map) {
            conditionCheckout.add(Map<String, dynamic>.from(entry));
          }
        }
      }
    } catch (_) {}

    await enqueueCheckoutFinalize(
      ticketId: ticket.id,
      serverTicketId: ticket.serverTicketId,
      amount: amount,
      timeOut: PhilippineTime.apiIsoInstant(
        PhilippineTime.wallComponentsToUtc(PhilippineTime.fromApiIso(checkOutAt)),
      ),
      isOvernight: ticket.isOvernight ?? false,
      ticketLost: ticket.ticketLost ?? false,
      conditionCheckout: conditionCheckout,
      driverOut: ticket.driverOut,
      cashTendered: cashTendered,
      appliedRate: appliedRate,
    );
    await (_db.update(_db.tickets)..where((t) => t.id.equals(ticket.id))).write(
      const TicketsCompanion(syncStatus: Value('pending')),
    );
    return true;
  }

  /// Enqueues multipart check-in for [SyncCubit] when offline.
  Future<void> enqueueCheckInSync({
    required String localTicketId,
    required Map<String, dynamic> payload,
  }) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db
        .into(_db.syncQueue)
        .insert(
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
    _notifyLocalSyncQueueChanged();
  }

  /// Pending tickets with no outstanding `sync_queue` row (manual sync had nothing to send).
  Future<int> countOrphanPendingTickets() async {
    final row = await _db.customSelect(
      _orphanPendingTicketsSql,
      readsFrom: {_db.tickets, _db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Re-enqueues orphan pending tickets so [SyncCubit.flush] can upload them.
  Future<int> reconcileOrphanPendingTickets() async {
    final rows = await _db.customSelect(
      '''
SELECT t.id FROM tickets t
WHERE t.sync_status = 'pending'
  AND t.status != 'draft'
  AND t.id NOT IN (
    SELECT q.record_id FROM sync_queue q
    WHERE q.table_name = 'tickets'
      AND q.sync_status IN ('pending', 'failed')
  )
''',
      readsFrom: {_db.tickets, _db.syncQueue},
    ).get();

    var enqueued = 0;
    for (final row in rows) {
      final tid = row.read<String>('id');
      final ticket = await ticketById(tid);
      if (ticket == null) continue;

      final serverId = ticket.serverTicketId?.trim() ?? '';
      if (serverId.isNotEmpty) {
        continue;
      }

      if (ticket.isExpressCashier) {
        final vr = ticket.vrNo?.trim() ?? '';
        final plate = ticket.plateNumber.trim();
        final amount = ticket.fee ?? 0;
        if (vr.isEmpty || plate.isEmpty || amount <= 0) {
          ValetLog.warning(
            'TicketService.reconcileOrphanPendingTickets',
            'skip express ticketId=$tid — missing vr/plate/amount',
          );
          continue;
        }

        await enqueueCheckInSync(
          localTicketId: tid,
          payload: expressCheckInSyncQueuePayload(
            localTicketId: tid,
            ticketNumber: tid,
            plateNumber: plate,
            amount: amount,
            vrNo: vr,
            driverIn: ticket.driverIn,
            driverOut: ticket.driverOut,
          ),
        );
        enqueued++;
        ValetLog.debug(
          'TicketService.reconcileOrphanPendingTickets',
          're-enqueued express check-in ticketId=$tid',
        );
        continue;
      }

      final standardPayload = standardCheckInSyncQueuePayloadFromTicket(ticket);
      if (standardPayload == null) {
        ValetLog.warning(
          'TicketService.reconcileOrphanPendingTickets',
          'skip standard ticketId=$tid — missing signature/slot/vr',
        );
        continue;
      }

      await enqueueCheckInSync(
        localTicketId: tid,
        payload: standardPayload,
      );
      enqueued++;
      ValetLog.debug(
        'TicketService.reconcileOrphanPendingTickets',
        're-enqueued standard check-in ticketId=$tid',
      );
    }
    if (enqueued > 0) {
      _notifyLocalSyncQueueChanged();
    }
    return enqueued;
  }

  static const _orphanPendingTicketsSql = '''
SELECT COUNT(*) AS c FROM tickets t
WHERE t.sync_status = 'pending'
  AND t.status != 'draft'
  AND t.id NOT IN (
    SELECT q.record_id FROM sync_queue q
    WHERE q.table_name = 'tickets'
      AND q.sync_status IN ('pending', 'failed')
  )
''';

  /// Clears orphan `pending` active tickets that already have a server UUID and
  /// no outstanding queue row (check-in reached the server; queue row was synced).
  Future<int> reconcileActiveServerBackedOrphans() async {
    final cleared = await _db.customUpdate(
      '''
UPDATE tickets SET sync_status = 'synced'
WHERE sync_status = 'pending'
  AND status = 'active'
  AND server_ticket_id IS NOT NULL
  AND TRIM(server_ticket_id) != ''
  AND id NOT IN (
    SELECT record_id FROM sync_queue
    WHERE table_name = 'tickets'
      AND sync_status IN ('pending', 'failed')
  )
''',
      updates: {_db.tickets},
    );
    if (cleared > 0) {
      _notifyLocalSyncQueueChanged();
    }
    return cleared;
  }

  /// Marks pending tickets `synced` only after GET confirms they exist on the server.
  Future<int> reconcilePendingServerBackedTickets(String token) async {
    final rows = await (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.syncStatus.equals('pending') &
                t.serverTicketId.isNotNull(),
          ))
        .get();

    var verified = 0;
    for (final ticket in rows) {
      final sid = ticket.serverTicketId?.trim() ?? '';
      if (sid.isEmpty) continue;
      try {
        final exists = await _verifyServerTransactionExists(
          token: token,
          serverId: sid,
        );
        if (!exists) continue;
        if (_localCheckoutAwaitingServerUpload(ticket)) {
          try {
            final txn = await _transactionsApi.getTransactionById(
              token: token,
              id: sid,
            );
            if (_serverTransactionStillCheckedIn(txn)) continue;
          } catch (e, st) {
            ValetLog.error(
              'TicketService.reconcilePendingServerBackedTickets',
              'checkout verify failed ticketId=${ticket.id} serverId=$sid',
              e,
              st,
            );
            continue;
          }
        }
        await (_db.update(_db.tickets)..where((t) => t.id.equals(ticket.id)))
            .write(
          const TicketsCompanion(syncStatus: Value('synced')),
        );
        verified++;
      } catch (e, st) {
        ValetLog.error(
          'TicketService.reconcilePendingServerBackedTickets',
          'verify failed ticketId=${ticket.id} serverId=$sid',
          e,
          st,
        );
      }
    }

    if (verified > 0) {
      _notifyLocalSyncQueueChanged();
    }
    return verified;
  }

  Future<bool> _verifyServerTransactionExists({
    required String token,
    required String serverId,
  }) async {
    try {
      await _transactionsApi.getTransactionById(token: token, id: serverId);
      return true;
    } on TransactionsApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  /// When the server already has this check-in (409) or a list fetch finds a
  /// match, link the local row and mark upload queue rows synced.
  Future<bool> reconcileLocalTicketFromServerLookup({
    required String localTicketId,
    required String token,
    Map<String, dynamic>? serverTxn,
    String? serverIdOverride,
  }) async {
    final ticket = await ticketById(localTicketId.trim());
    if (ticket == null) return false;

    final serverId = serverIdOverride?.trim() ??
        await resolveServerTransactionIdByVr(
          token: token,
          vrNo: ticket.vrNo ?? '',
          plateNumber: ticket.plateNumber,
          ticketNumber: ticket.id,
        );
    if (serverId == null || serverId.isEmpty) return false;

    return _applyServerReconciliationForLocalTicket(
      ticket: ticket,
      serverId: serverId,
      serverTxn: serverTxn,
      token: token,
    );
  }

  /// Fetches today's server transactions and links pending local tickets that
  /// already exist remotely (standard + express check-in / check-out).
  Future<int> reconcileOfflineTicketsFromServerList(String token) async {
    if (AppConfig.useStubApi) return 0;

    final pending = await _pendingTicketsNeedingReconcile();
    if (pending.isEmpty) return 0;

    final reconciledLocalIds = <String>{};
    var linked = 0;

    final serverRows = await _fetchTodayServerTransactions(token);
    for (final ticket in pending) {
      final match = _findMatchingServerRow(
        ticket,
        serverRows,
        excludeServerIds: const {},
      );
      if (match == null) continue;
      final serverId = _serverUuidFromTransactionJson(match);
      if (serverId == null) continue;
      final ok = await _applyServerReconciliationForLocalTicket(
        ticket: ticket,
        serverId: serverId,
        serverTxn: match,
        token: token,
      );
      if (ok) {
        linked++;
        reconciledLocalIds.add(ticket.id);
      }
    }

    for (final ticket in pending) {
      if (reconciledLocalIds.contains(ticket.id)) continue;
      final fresh = await ticketById(ticket.id);
      if (fresh == null || fresh.syncStatus == 'synced') continue;
      if (!await _hasUnsyncedQueueForTicket(ticket.id) &&
          fresh.syncStatus == 'synced') {
        continue;
      }
      if (await reconcileLocalTicketFromServerLookup(
        localTicketId: ticket.id,
        token: token,
      )) {
        linked++;
      }
    }

    if (linked > 0) {
      ValetLog.info(
        'TicketService.reconcileOfflineTicketsFromServerList',
        'linked $linked pending ticket(s) already on server',
      );
    }
    return linked;
  }

  Future<List<Ticket>> _pendingTicketsNeedingReconcile() async {
    final rows = await _db.customSelect(
      '''
SELECT DISTINCT t.id AS id FROM tickets t
WHERE t.sync_status = 'pending'
   OR t.id IN (
     SELECT q.record_id FROM sync_queue q
     WHERE q.table_name = 'tickets'
       AND q.sync_status IN ('pending', 'failed')
   )
''',
      readsFrom: {_db.tickets, _db.syncQueue},
    ).get();

    final out = <Ticket>[];
    for (final row in rows) {
      final ticket = await ticketById(row.read<String>('id'));
      if (ticket != null) out.add(ticket);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _fetchTodayServerTransactions(
    String token,
  ) async {
    final now = PhilippineTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final fromUnix = start.millisecondsSinceEpoch ~/ 1000;
    final toUnix = end.millisecondsSinceEpoch ~/ 1000;

    final all = <Map<String, dynamic>>[];
    for (var page = 1; page <= 5; page++) {
      try {
        final rows = await _transactionsApi.fetchTransactions(
          token: token,
          dateFromUnix: fromUnix,
          dateToUnix: toUnix,
          limit: 200,
          page: page,
        );
        if (rows.isEmpty) break;
        all.addAll(rows);
        if (rows.length < 200) break;
      } catch (e, st) {
        ValetLog.error(
          'TicketService._fetchTodayServerTransactions',
          'page=$page',
          e,
          st,
        );
        break;
      }
    }
    return all;
  }

  Map<String, dynamic>? _findMatchingServerRow(
    Ticket local,
    List<Map<String, dynamic>> serverRows, {
    required Set<String> excludeServerIds,
  }) {
    for (final row in serverRows) {
      final serverId = _serverUuidFromTransactionJson(row);
      if (serverId == null || excludeServerIds.contains(serverId)) continue;
      if (_serverRowMatchesLocalTicket(local, row)) return row;
    }
    return null;
  }

  bool _serverRowMatchesLocalTicket(
    Ticket local,
    Map<String, dynamic> server,
  ) {
    final localId = local.id.trim();
    final serverTicket = server['ticket_number']?.toString().trim() ??
        server['ticketNumber']?.toString().trim() ??
        '';
    if (localId.isNotEmpty && serverTicket == localId) return true;

    final localVr = normalizeVrNumber(local.vrNo ?? '');
    final serverVr = normalizeVrNumber(_vrNoFromTransactionJson(server));
    if (localVr.isEmpty || serverVr.isEmpty || localVr != serverVr) {
      return false;
    }

    final localPlate = normalizePlateNumber(local.plateNumber).toUpperCase();
    final serverPlate = _plateFromTransactionJson(server);
    if (localPlate.isNotEmpty &&
        serverPlate.isNotEmpty &&
        localPlate != serverPlate) {
      return false;
    }
    return true;
  }

  String? _serverUuidFromTransactionJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    if (id.isEmpty || id.startsWith('TKT-')) return null;
    return id;
  }

  static String _plateFromTransactionJson(Map<String, dynamic> json) {
    final top = json['plate_number']?.toString().trim() ??
        json['plateNumber']?.toString().trim();
    if (top != null && top.isNotEmpty) {
      return normalizePlateNumber(top).toUpperCase();
    }
    final vehicle = json['vehicle'];
    if (vehicle is Map) {
      final m = Map<String, dynamic>.from(vehicle);
      final plate = m['plate_number']?.toString().trim() ??
          m['plateNumber']?.toString().trim() ??
          '';
      if (plate.isNotEmpty) {
        return normalizePlateNumber(plate).toUpperCase();
      }
    }
    return '';
  }

  Future<bool> _applyServerReconciliationForLocalTicket({
    required Ticket ticket,
    required String serverId,
    required String token,
    Map<String, dynamic>? serverTxn,
  }) async {
    await updateServerTicketId(ticket.id, serverId);
    await _markCheckInQueuesSyncedForTicket(ticket.id);

    Map<String, dynamic>? txn = serverTxn;
    if (txn == null) {
      try {
        txn = await _transactionsApi.getTransactionById(
          token: token,
          id: serverId,
        );
      } catch (e, st) {
        ValetLog.error(
          'TicketService._applyServerReconciliationForLocalTicket',
          'GET failed ticketId=${ticket.id} serverId=$serverId',
          e,
          st,
        );
      }
    }

    if (ticket.status == 'completed' || ticket.status == 'lost') {
      if (txn != null && !_serverTransactionStillCheckedIn(txn)) {
        await _markLocalCheckoutFullySynced(ticket.id);
        return true;
      }
      await (_db.update(_db.tickets)..where((t) => t.id.equals(ticket.id)))
          .write(
        TicketsCompanion(
          syncStatus: Value(await _resolvedSyncStatusForTicket(ticket.id)),
        ),
      );
      return true;
    }

    await (_db.update(_db.tickets)..where((t) => t.id.equals(ticket.id))).write(
      const TicketsCompanion(syncStatus: Value('synced')),
    );
    _notifyLocalSyncQueueChanged();
    return true;
  }

  Future<void> _markCheckInQueuesSyncedForTicket(String ticketId) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('checkin') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
  }

  Future<CheckInResponse?> _reconcileQueuedCheckInConflict({
    required String localTicketId,
    required String token,
  }) async {
    final linked = await reconcileLocalTicketFromServerLookup(
      localTicketId: localTicketId,
      token: token,
    );
    if (!linked) return null;

    final serverId = (await ticketById(localTicketId))?.serverTicketId?.trim();
    if (serverId == null || serverId.isEmpty) return null;
    return CheckInResponse(
      id: serverId,
      ticketNumber: localTicketId,
      qrCode: localTicketId,
    );
  }

  /// Uploads pending check-in queue rows in one batch JSON request.
  Future<int> syncPendingCheckInsBatch(
    List<SyncQueueData> rows,
    String token,
  ) async {
    if (rows.isEmpty) return 0;

    final entries = <_BatchCheckInEntry>[];
    for (final row in rows) {
      try {
        final raw = jsonDecode(row.payload);
        if (raw is! Map) {
          await _markSyncQueueFailedById(row.id);
          continue;
        }
        final map = Map<String, dynamic>.from(raw);
        final ticket = await ticketById(row.recordId);
        final item = await checkInQueuePayloadToApiItem(
          map,
          voidRequested: ticket?.pendingVoidRequest ?? false,
          voidReason: ticket?.pendingVoidReason,
        );
        entries.add(_BatchCheckInEntry(row: row, item: item, ticket: ticket));
      } catch (e, st) {
        ValetLog.error(
          'TicketService.syncPendingCheckInsBatch',
          'build item failed queueId=${row.id} recordId=${row.recordId}',
          e,
          st,
        );
        await _markSyncQueueFailedById(row.id);
      }
    }

    if (entries.isEmpty) return 0;

    final batch = await _transactionsApi.submitBatchCheckIn(
      token: token,
      checkIns: [for (final e in entries) e.item],
    );

    var synced = 0;
    final matchedQueueIds = <String>{};

    for (final result in batch.results) {
      final entry = _matchBatchCheckInEntry(
        entries,
        result,
        matchedQueueIds,
      );
      if (entry == null) {
        ValetLog.warning(
          'TicketService.syncPendingCheckInsBatch',
          'no local match for batch result index=${result.index} '
              'ticket=${result.ticketNumber}',
        );
        continue;
      }
      matchedQueueIds.add(entry.row.id);

      if (result.isSuccess) {
        // Clear the queue row before resolving ticket sync_status — otherwise
        // _resolvedSyncStatusForTicket still sees this pending check-in row.
        await _markSyncQueueSyncedById(entry.row.id);
        await _applyBatchCheckInSuccess(entry, result);
        synced++;
        continue;
      }

      if (result.error?.isAlreadyOnServerConflict == true) {
        final linked = await _tryLinkBatchExistingTransaction(
          entry,
          result,
          token,
        );
        if (linked) {
          await _markSyncQueueSyncedById(entry.row.id);
          synced++;
          continue;
        }
      }

      await _markSyncQueueFailedById(entry.row.id);
    }

    for (final entry in entries) {
      if (!matchedQueueIds.contains(entry.row.id)) {
        ValetLog.warning(
          'TicketService.syncPendingCheckInsBatch',
          'missing batch result for queueId=${entry.row.id} '
              'ticket=${entry.item['ticket_number']}',
        );
        await _markSyncQueueFailedById(entry.row.id);
      }
    }

    return synced;
  }

  /// Uploads pending checkout/finalize queue rows in one batch JSON request.
  Future<int> syncPendingCheckoutsBatch(
    List<SyncQueueData> rows,
    String token,
  ) async {
    if (rows.isEmpty) return 0;

    final entries = <_BatchCheckInEntry>[];
    for (final row in rows) {
      try {
        final raw = jsonDecode(row.payload);
        if (raw is! Map) {
          await _markSyncQueueFailedById(row.id);
          continue;
        }
        final map = Map<String, dynamic>.from(raw);
        final ticket = await ticketById(row.recordId);
        final serverTimeInRaw = await _serverTimeInInstantForCheckout(
          token: token,
          serverTicketId: ticket?.serverTicketId,
        );
        final item = checkoutQueuePayloadToApiItem(
          map,
          serverTicketIdOverride: ticket?.serverTicketId,
          checkInAtIso: ticket?.checkInAt,
          serverTimeInRaw: serverTimeInRaw,
        );
        entries.add(_BatchCheckInEntry(row: row, item: item, ticket: ticket));
      } catch (e, st) {
        ValetLog.error(
          'TicketService.syncPendingCheckoutsBatch',
          'build item failed queueId=${row.id} recordId=${row.recordId}',
          e,
          st,
        );
        await _markSyncQueueFailedById(row.id);
      }
    }

    if (entries.isEmpty) return 0;

    final batch = await _transactionsApi.submitBatchCheckOut(
      token: token,
      checkOuts: [for (final e in entries) e.item],
      localTicketNumbers: [for (final e in entries) e.row.recordId],
    );

    var synced = 0;
    final matchedQueueIds = <String>{};

    for (final result in batch.results) {
      final entry = _matchBatchCheckoutEntry(
        entries,
        result,
        matchedQueueIds,
      );
      if (entry == null) {
        ValetLog.warning(
          'TicketService.syncPendingCheckoutsBatch',
          'no local match for batch result index=${result.index} '
              'ticket=${result.ticketNumber}',
        );
        continue;
      }
      matchedQueueIds.add(entry.row.id);

      if (result.isSuccess) {
        await _applyBatchCheckoutSuccess(entry, result);
        await _markSyncQueueSyncedById(entry.row.id);
        synced++;
        continue;
      }

      if (await _tryReconcileBatchCheckoutConflict(entry, result)) {
        await _markSyncQueueSyncedById(entry.row.id);
        synced++;
        continue;
      }

      await _markSyncQueueFailedById(entry.row.id);
    }

    for (final entry in entries) {
      if (!matchedQueueIds.contains(entry.row.id)) {
        ValetLog.warning(
          'TicketService.syncPendingCheckoutsBatch',
          'missing batch result for queueId=${entry.row.id} '
              'ticket=${entry.row.recordId}',
        );
        await _markSyncQueueFailedById(entry.row.id);
      }
    }

    return synced;
  }

  _BatchCheckInEntry? _matchBatchCheckoutEntry(
    List<_BatchCheckInEntry> entries,
    BatchCheckInResultItem result,
    Set<String> alreadyMatched,
  ) {
    final ticketNo = result.ticketNumber.trim();
    if (ticketNo.isNotEmpty) {
      for (final e in entries) {
        if (alreadyMatched.contains(e.row.id)) continue;
        if (e.row.recordId.trim() == ticketNo) return e;
      }
    }

    if (result.index >= 0 && result.index < entries.length) {
      final e = entries[result.index];
      if (!alreadyMatched.contains(e.row.id)) return e;
    }
    return null;
  }

  Future<void> _applyBatchCheckoutSuccess(
    _BatchCheckInEntry entry,
    BatchCheckInResultItem result,
  ) async {
    final localId = entry.row.recordId.trim();
    if (localId.isEmpty) return;

    final serverId = result.serverTransactionId?.trim() ?? '';
    if (serverId.isNotEmpty) {
      await updateServerTicketId(localId, serverId);
    }

    final txn = result.transaction ?? const <String, dynamic>{};
    final txnStatus = txn['status']?.toString().trim().toLowerCase() ?? '';
    final statusUpdate = txnStatus == 'lost'
        ? 'lost'
        : txnStatus == 'completed'
            ? 'completed'
            : null;

    final checkOutRaw = txn['time_out'] ??
        txn['timeOut'] ??
        txn['check_out_at'] ??
        txn['checkOutAt'];
    final checkOutAt = checkOutRaw?.toString().trim();

    await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
      TicketsCompanion(
        syncStatus: const Value('synced'),
        status: statusUpdate != null ? Value(statusUpdate) : const Value.absent(),
        checkOutAt: checkOutAt != null && checkOutAt.isNotEmpty
            ? Value(checkOutAt)
            : const Value.absent(),
      ),
    );
    await _markLocalCheckoutFullySynced(localId);
  }

  Future<bool> _tryReconcileBatchCheckoutConflict(
    _BatchCheckInEntry entry,
    BatchCheckInResultItem result,
  ) async {
    if (result.error?.isCheckoutReconcileConflict != true) return false;
    final localId = entry.row.recordId.trim();
    if (localId.isEmpty) return false;

    final serverId = result.serverTransactionId?.trim() ?? '';
    if (serverId.isNotEmpty) {
      await updateServerTicketId(localId, serverId);
    }

    await _markLocalCheckoutFullySynced(localId);
    ValetLog.info(
      'TicketService.syncPendingCheckoutsBatch',
      'reconciled already-checked-out ticket=$localId',
    );
    return true;
  }

  Future<void> _markSyncQueueSyncedById(String queueId) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId))).write(
          const SyncQueueCompanion(syncStatus: Value('synced')),
        );
  }

  Future<void> _markSyncQueueFailedById(String queueId) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId))).write(
          const SyncQueueCompanion(syncStatus: Value('failed')),
        );
  }

  _BatchCheckInEntry? _matchBatchCheckInEntry(
    List<_BatchCheckInEntry> entries,
    BatchCheckInResultItem result,
    Set<String> alreadyMatched,
  ) {
    final ticketNo = result.ticketNumber.trim();
    final vr = normalizeVrNumber(result.vrNo);
    final plate = normalizePlateNumber(result.plateNumber).toUpperCase();

    if (ticketNo.isNotEmpty) {
      for (final e in entries) {
        if (alreadyMatched.contains(e.row.id)) continue;
        final itemTicket = e.item['ticket_number']?.toString().trim() ?? '';
        if (itemTicket == ticketNo) return e;
      }
    }

    if (vr.isNotEmpty && plate.isNotEmpty) {
      for (final e in entries) {
        if (alreadyMatched.contains(e.row.id)) continue;
        final itemVr = normalizeVrNumber(e.item['vr_no']?.toString() ?? '');
        final vehicle = e.item['vehicle'];
        var itemPlate = '';
        if (vehicle is Map) {
          itemPlate = normalizePlateNumber(
            vehicle['plate_number']?.toString() ?? '',
          ).toUpperCase();
        }
        if (itemVr == vr && itemPlate == plate) return e;
      }
    }

    if (result.index >= 0 && result.index < entries.length) {
      final e = entries[result.index];
      if (!alreadyMatched.contains(e.row.id)) return e;
    }
    return null;
  }

  Future<void> _applyBatchCheckInSuccess(
    _BatchCheckInEntry entry,
    BatchCheckInResultItem result,
  ) async {
    final localId = entry.row.recordId.trim();
    final serverId = result.serverTransactionId?.trim() ?? '';
    if (localId.isEmpty || serverId.isEmpty) return;

    await updateServerTicketId(localId, serverId);
    final txn = result.transaction ?? <String, dynamic>{'id': serverId};
    final isExpress =
        entry.ticket?.isExpressCashier == true ||
        entry.item['is_express_cashier'] == true ||
        entry.item.containsKey('amount');

    if (isExpress) {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
        TicketsCompanion(
          syncStatus: Value(await _resolvedSyncStatusForTicket(localId)),
        ),
      );
      return;
    }

    final body = entry.item;
    final vrNo = result.vrNo.trim().isNotEmpty
        ? result.vrNo.trim()
        : body['vr_no']?.toString().trim() ?? '';
    final voidMeta = _voidAuditCompanion(txn);
    final voidStatus = _resolveVoidStatus(txn);
    final queuedSlotId = body['slot_id']?.toString().trim() ?? '';
    final serverCheckIn = CheckInTimeResolution.resolveWallIsoFromTransaction(
      txn,
      localFallback: entry.ticket?.checkInAt,
    );
    await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
      TicketsCompanion(
        syncStatus: const Value('synced'),
        pendingVoidRequest: const Value(false),
        pendingVoidReason: const Value(null),
        status: voidStatus != null ? Value(voidStatus) : const Value.absent(),
        voidReason: voidMeta.voidReason,
        voidedByJson: voidMeta.voidedByJson,
        voidedAt: voidMeta.voidedAt,
        slotId: queuedSlotId.isNotEmpty
            ? Value(queuedSlotId)
            : const Value.absent(),
        vrNo: vrNo.isNotEmpty ? Value(vrNo) : const Value.absent(),
        checkInAt: Value(PhilippineTime.normalizeCheckInStorage(serverCheckIn)),
      ),
    );
  }

  /// Server `time_in` / `created_at` (UTC) for checkout batch clamping.
  Future<String?> _serverTimeInInstantForCheckout({
    required String token,
    String? serverTicketId,
  }) async {
    final serverId = serverTicketId?.trim() ?? '';
    if (serverId.isEmpty) return null;
    try {
      final txn = await _transactionsApi.getTransactionById(
        token: token,
        id: serverId,
      );
      for (final key in const [
        'time_in',
        'check_in_at',
        'checkInAt',
        'created_at',
        'createdAt',
      ]) {
        final raw = txn[key];
        if (raw == null) continue;
        final s = raw.toString().trim();
        if (s.isEmpty) continue;
        final parsed = DateTime.tryParse(s)?.toUtc();
        if (parsed != null) return parsed.toIso8601String();
      }
    } catch (e, st) {
      ValetLog.error(
        'TicketService._serverTimeInInstantForCheckout',
        'GET $serverId failed — using local check-in only',
        e,
        st,
      );
    }
    return null;
  }

  Future<bool> _tryLinkBatchExistingTransaction(
    _BatchCheckInEntry entry,
    BatchCheckInResultItem result,
    String token,
  ) async {
    final localId = entry.row.recordId.trim();
    final ticketNumber = result.ticketNumber.trim().isNotEmpty
        ? result.ticketNumber.trim()
        : entry.item['ticket_number']?.toString().trim() ?? localId;
    final plate = result.plateNumber.trim().isNotEmpty
        ? result.plateNumber.trim()
        : entry.item['vehicle'] is Map
            ? (entry.item['vehicle'] as Map)['plate_number']?.toString() ?? ''
            : '';
    final vrNo = result.vrNo.trim().isNotEmpty
        ? result.vrNo.trim()
        : entry.item['vr_no']?.toString().trim() ?? '';

    final serverId = await resolveServerTransactionIdByVr(
      token: token,
      vrNo: vrNo,
      plateNumber: plate,
      ticketNumber: ticketNumber,
    );
    if (serverId == null) return false;

    await updateServerTicketId(localId, serverId);
    await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
      const TicketsCompanion(syncStatus: Value('synced')),
    );
    ValetLog.info(
      'TicketService.syncPendingCheckInsBatch',
      'linked existing server ticket $serverId for localId=$localId vr=$vrNo',
    );
    return true;
  }

  /// Processes a queued check-in row via `POST /transactions/check-in`.
  Future<CheckInResponse> syncQueuedCheckIn(
    Map<String, dynamic> body,
    String token,
  ) async {
    if (body['is_express_cashier'] == true) {
      return syncQueuedExpressCheckIn(body, token);
    }

    final path = body['signature_path']?.toString().trim() ?? '';
    if (path.isEmpty) {
      throw StateError('Queued check-in missing signature_path');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Signature file missing: $path');
    }

    final vehicleRaw = _mapField(body['vehicle']);
    final vrFromVehicle =
        vehicleRaw['vr_no']?.toString().trim() ??
        vehicleRaw['vrNo']?.toString().trim();
    final vehicle = Map<String, dynamic>.from(vehicleRaw)
      ..remove('vr_no')
      ..remove('vrNo');
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

    final localRow = localId.isNotEmpty ? await ticketById(localId) : null;
    final vrFromQueue = body['vr_no']?.toString().trim();
    final vrNo = localRow?.vrNo?.trim().isNotEmpty == true
        ? localRow!.vrNo!.trim()
        : (vrFromQueue?.isNotEmpty == true
            ? vrFromQueue!
            : (vrFromVehicle?.isNotEmpty == true ? vrFromVehicle! : ''));
    if (vrNo.isEmpty) {
      throw StateError('Queued check-in missing vr_no');
    }

    try {
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
        driverOut: body['driver_out']?.toString(),
        notes: body['notes']?.toString(),
        vrNo: vrNo,
        voidRequested: localRow?.pendingVoidRequest ?? false,
        voidReason: localRow?.pendingVoidReason,
      );

      if (localId.isNotEmpty) {
        await updateServerTicketId(localId, response.id);
        final queuedSlotId = body['slot_id']?.toString().trim() ?? '';
        final voidMeta = _voidAuditCompanion(response.rawJson);
        final voidStatus = _resolveVoidStatus(response.rawJson);
        final companion = TicketsCompanion(
          syncStatus: const Value('synced'),
          pendingVoidRequest: const Value(false),
          pendingVoidReason: const Value(null),
          status: voidStatus != null ? Value(voidStatus) : const Value.absent(),
          voidReason: voidMeta.voidReason,
          voidedByJson: voidMeta.voidedByJson,
          voidedAt: voidMeta.voidedAt,
          slotId: queuedSlotId.isNotEmpty
              ? Value(queuedSlotId)
              : const Value.absent(),
          vrNo: Value(vrNo),
        );
        await (_db.update(_db.tickets)..where((t) => t.id.equals(localId)))
            .write(companion);
      }
      return response;
    } on VrNumberConflictOnServerException catch (_) {
      final reconciled = await _reconcileQueuedCheckInConflict(
        localTicketId: localId,
        token: token,
      );
      if (reconciled != null) return reconciled;
      rethrow;
    } on VehicleAlreadyCheckedInException catch (_) {
      final reconciled = await _reconcileQueuedCheckInConflict(
        localTicketId: localId,
        token: token,
      );
      if (reconciled != null) return reconciled;
      rethrow;
    }
  }

  /// Processes a queued express cashier check-in row.
  Future<CheckInResponse> syncQueuedExpressCheckIn(
    Map<String, dynamic> body,
    String token,
  ) async {
    final localId =
        body['local_ticket_id']?.toString().trim() ??
        body['ticket_number']?.toString().trim() ??
        '';
    if (localId.isEmpty) {
      throw StateError('Queued express check-in missing local_ticket_id');
    }

    final plate = body['plate_number']?.toString().trim() ?? '';
    if (plate.isEmpty) {
      throw StateError('Queued express check-in missing plate_number');
    }

    final amountRaw = body['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '') ?? 0;
    if (amount <= 0) {
      throw StateError('Queued express check-in missing amount');
    }

    final ticketNumber =
        body['ticket_number']?.toString().trim().isNotEmpty == true
            ? body['ticket_number'].toString().trim()
            : localId;

    final localRow = await ticketById(localId);
    final vrFromQueue = body['vr_no']?.toString().trim() ?? '';
    final vrNo = localRow?.vrNo?.trim().isNotEmpty == true
        ? localRow!.vrNo!.trim()
        : vrFromQueue;
    if (vrNo.isEmpty) {
      throw StateError('Queued express check-in missing vr_no');
    }

    try {
      final response = await _transactionsApi.submitExpressCheckIn(
        token: token,
        ticketNumber: ticketNumber,
        plateNumber: plate,
        amount: amount,
        vrNo: vrNo,
        driverIn: body['driver_in']?.toString(),
        driverOut: body['driver_out']?.toString(),
      );

      await updateServerTicketId(localId, response.id);
      await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
        const TicketsCompanion(syncStatus: Value('synced')),
      );
      return response;
    } on VrNumberConflictOnServerException catch (e, st) {
      final reconciled = await _reconcileQueuedCheckInConflict(
        localTicketId: localId,
        token: token,
      );
      if (reconciled != null) return reconciled;
      ValetLog.error(
        'TicketService.syncQueuedExpressCheckIn',
        'VR conflict but no server match vr=$vrNo localId=$localId',
        e,
        st,
      );
      rethrow;
    } on VehicleAlreadyCheckedInException catch (_) {
      final reconciled = await _reconcileQueuedCheckInConflict(
        localTicketId: localId,
        token: token,
      );
      if (reconciled != null) return reconciled;
      rethrow;
    }
  }

  /// Finds a server transaction UUID when check-in returns 409 (VR already exists).
  ///
  /// Reports `search` only matches plate or ticket number — not VR — so we try
  /// `GET /transactions/:id` and dated list endpoints before reports fallbacks.
  Future<String?> resolveServerTransactionIdByVr({
    required String token,
    required String vrNo,
    String? plateNumber,
    String? ticketNumber,
  }) async {
    final vr = normalizeVrNumber(vrNo);
    final ticket = ticketNumber?.trim() ?? '';
    final plate = normalizePlateNumber(plateNumber ?? '').toUpperCase();
    final today = _reportsDateIsoForToday();

    if (ticket.isNotEmpty) {
      final byGet = await _tryServerIdFromTransactionGet(
        token: token,
        lookupKey: ticket,
      );
      if (byGet != null) {
        ValetLog.debug(
          'TicketService.resolveServerTransactionIdByVr',
          'matched via GET /transactions/$ticket',
        );
        return byGet;
      }

      final byTicketReports = await _tryServerIdFromReports(
        token: token,
        search: ticket,
        vrNo: vr,
        dateFrom: today,
        dateTo: today,
      );
      if (byTicketReports != null) {
        ValetLog.debug(
          'TicketService.resolveServerTransactionIdByVr',
          'matched via reports ticket=$ticket',
        );
        return byTicketReports;
      }
    }

    if (vr.isNotEmpty) {
      final byList = await _tryServerIdFromTransactionsList(
        token: token,
        vrNo: vr,
        ticketNumber: ticket,
      );
      if (byList != null) {
        ValetLog.debug(
          'TicketService.resolveServerTransactionIdByVr',
          'matched via GET /transactions list vr=$vr',
        );
        return byList;
      }
    }

    if (plate.isNotEmpty) {
      final byPlateReports = await _tryServerIdFromReports(
        token: token,
        search: plate,
        vrNo: vr,
        dateFrom: today,
        dateTo: today,
      );
      if (byPlateReports != null) {
        ValetLog.debug(
          'TicketService.resolveServerTransactionIdByVr',
          'matched via reports plate=$plate',
        );
        return byPlateReports;
      }
    }

    return null;
  }

  String _reportsDateIsoForToday() {
    final now = PhilippineTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<String?> _tryServerIdFromTransactionGet({
    required String token,
    required String lookupKey,
  }) async {
    try {
      final map = await _transactionsApi.getTransactionById(
        token: token,
        id: lookupKey,
      );
      final id = map['id']?.toString().trim() ?? '';
      return id.isEmpty ? null : id;
    } on TransactionsApiException catch (e) {
      if (e.statusCode == 404) return null;
      ValetLog.error(
        'TicketService._tryServerIdFromTransactionGet',
        'lookupKey=$lookupKey',
        e,
      );
      return null;
    } catch (e, st) {
      ValetLog.error(
        'TicketService._tryServerIdFromTransactionGet',
        'lookupKey=$lookupKey',
        e,
        st,
      );
      return null;
    }
  }

  Future<String?> _tryServerIdFromReports({
    required String token,
    required String search,
    required String vrNo,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final page = await _transactionsApi.fetchReportsTransactions(
        token: token,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
        limit: 50,
        page: 1,
      );
      for (final row in page.rows) {
        if (vrNo.isNotEmpty) {
          final rowVr = normalizeVrNumber(row.vrNo == '—' ? '' : row.vrNo);
          if (rowVr.isNotEmpty && rowVr != vrNo) continue;
        }
        final sid = row.serverTransactionId?.trim() ?? '';
        if (sid.isNotEmpty) return sid;
      }
    } catch (e, st) {
      ValetLog.error(
        'TicketService._tryServerIdFromReports',
        'search=$search',
        e,
        st,
      );
    }
    return null;
  }

  Future<String?> _tryServerIdFromTransactionsList({
    required String token,
    required String vrNo,
    String? ticketNumber,
  }) async {
    final now = PhilippineTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final fromUnix = start.millisecondsSinceEpoch ~/ 1000;
    final toUnix = end.millisecondsSinceEpoch ~/ 1000;
    final ticket = ticketNumber?.trim() ?? '';

    try {
      final rows = await _transactionsApi.fetchTransactions(
        token: token,
        dateFromUnix: fromUnix,
        dateToUnix: toUnix,
        limit: 200,
        page: 1,
      );
      for (final row in rows) {
        final rowVr = normalizeVrNumber(_vrNoFromTransactionJson(row));
        if (vrNo.isNotEmpty && rowVr != vrNo) continue;
        if (ticket.isNotEmpty) {
          final rowTicket =
              row['ticket_number']?.toString().trim() ??
              row['ticketNumber']?.toString().trim() ??
              '';
          if (rowTicket != ticket) continue;
        }
        final id = row['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) return id;
      }
    } catch (e, st) {
      ValetLog.error(
        'TicketService._tryServerIdFromTransactionsList',
        'vr=$vrNo ticket=$ticket',
        e,
        st,
      );
    }
    return null;
  }

  static String _vrNoFromTransactionJson(Map<String, dynamic> json) {
    final top = json['vr_no']?.toString().trim() ?? json['vrNo']?.toString().trim();
    if (top != null && top.isNotEmpty) return top;
    final vehicle = json['vehicle'];
    if (vehicle is Map) {
      final m = Map<String, dynamic>.from(vehicle);
      return m['vr_no']?.toString().trim() ?? m['vrNo']?.toString().trim() ?? '';
    }
    return '';
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
          if (e is Map<String, dynamic>)
            e
          else if (e is Map)
            Map<String, dynamic>.from(e),
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
  Future<CheckoutTicketDisplay?> checkoutDisplayForTicket(
    String ticketId,
  ) async {
    final id = ticketId.trim();
    if (id.isEmpty) return null;

    final ticket = await ticketById(id);
    if (ticket != null) {
      final fromMeta = _checkoutDisplayFromDriverOutMeta(ticket.driverOut);
      if (fromMeta != null) return fromMeta;
    }

    final row =
        await (_db.select(_db.syncQueue)
              ..where(
                (q) =>
                    q.recordId.equals(id) & q.queueTableName.equals('tickets'),
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
        valetTypeLabel: valetRaw.isEmpty ? null : ValetTypeFormat.label(valetRaw),
      );
    } catch (_) {
      return null;
    }
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

  /// Ticket with [vrNo] (case-insensitive), excluding [excludeTicketId].
  Future<Ticket?> ticketByVrNo(
    String vrNo, {
    String? excludeTicketId,
  }) async {
    final normalized = normalizeVrNumber(vrNo);
    if (normalized.isEmpty) return null;
    final exclude = excludeTicketId?.trim() ?? '';
    final row = await _db
        .customSelect(
          exclude.isEmpty
              ? '''
SELECT id FROM tickets
WHERE status != 'draft'
  AND vr_no IS NOT NULL
  AND TRIM(vr_no) != ''
  AND UPPER(TRIM(vr_no)) = ?
ORDER BY check_in_at DESC
LIMIT 1
'''
              : '''
SELECT id FROM tickets
WHERE status != 'draft'
  AND vr_no IS NOT NULL
  AND TRIM(vr_no) != ''
  AND UPPER(TRIM(vr_no)) = ?
  AND id != ?
ORDER BY check_in_at DESC
LIMIT 1
''',
          variables: exclude.isEmpty
              ? <Variable<Object>>[Variable.withString(normalized)]
              : <Variable<Object>>[
                  Variable.withString(normalized),
                  Variable.withString(exclude),
                ],
          readsFrom: {_db.tickets},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return ticketById(row.read<String>('id'));
  }

  /// Ensures [vrNo] is not already stored on another local ticket.
  Future<void> ensureVrNoAvailable(
    String vrNo, {
    String? excludeTicketId,
  }) async {
    final existing = await ticketByVrNo(vrNo, excludeTicketId: excludeTicketId);
    if (existing != null) {
      throw VrNumberAlreadyUsedException();
    }
  }

  /// Most recent ticket for [plate] regardless of status (offline lookup).
  Future<Ticket?> ticketByPlateAnyStatus(String plate) async {
    final normalized = plate
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    if (normalized.isEmpty) return null;
    final row = await _db
        .customSelect(
          '''
SELECT id FROM tickets
WHERE status != 'draft'
  AND REPLACE(UPPER(plate_number), ' ', '') = ?
ORDER BY check_in_at DESC
LIMIT 1
''',
          variables: <Variable<Object>>[Variable.withString(normalized)],
          readsFrom: {_db.tickets},
        )
        .getSingleOrNull();
    if (row == null) return null;
    final tid = row.read<String>('id');
    return ticketById(tid);
  }

  /// Most recent open ticket for [plate] (spaces ignored, case-insensitive).
  Future<Ticket?> activeTicketByPlate(String plate) async {
    final normalized = plate
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    if (normalized.isEmpty) return null;
    final row = await _db
        .customSelect(
          '''
SELECT id FROM tickets
WHERE status = 'active'
  AND REPLACE(UPPER(plate_number), ' ', '') = ?
ORDER BY check_in_at DESC
LIMIT 1
''',
          variables: <Variable<Object>>[Variable.withString(normalized)],
          readsFrom: {_db.tickets},
        )
        .getSingleOrNull();
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
    TransactionPaymentSummary? paymentSummary,
    bool syncedToServer = false,
  }) async {
    ValetLog.info(
      'TicketService.completeTicketCheckout',
      'ticketId=$ticketId fee=$totalFee (local)',
    );
    final ticketBefore = await ticketById(ticketId);
    final paymentJson = paymentSummary != null
        ? jsonEncode(paymentSummary.toJson())
        : null;
    await _db.transaction(() async {
      await (_db.update(
        _db.tickets,
      )..where((t) => t.id.equals(ticketId))).write(
        TicketsCompanion(
          checkOutAt: Value(checkOutAtIso),
          fee: Value(totalFee),
          status: Value(status),
          damageMarkers: Value(damageMarkersJson),
          syncStatus: Value(syncedToServer ? 'synced' : 'pending'),
          driverOut: Value(_normalizedDriverName(driverOut)),
          paymentSummaryJson: paymentJson != null
              ? Value(paymentJson)
              : const Value.absent(),
        ),
      );
    });
    final slotId = ticketBefore?.slotId?.trim() ?? '';
    if (slotId.isNotEmpty && ticketBefore != null) {
      final layoutBranchId =
          _validUuidOrNull(ticketBefore.branchId) ?? await _deviceBranchId;
      if (layoutBranchId != null) {
        await _parkingLayout.markSlotAvailableForTicket(
          branchId: layoutBranchId,
          slotId: slotId,
        );
      }
    }
  }

  /// Queues unified check-out for offline finalize (`operation: checkout/finalize`).
  Future<void> persistVrNo(String ticketId, String vrNo) async {
    final tid = ticketId.trim();
    final v = normalizeVrNumber(vrNo);
    if (tid.isEmpty || v.isEmpty) return;
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(vrNo: Value(v)),
    );
  }

  /// Persists checkout metadata on the local ticket row (offline display / replay).
  Future<void> persistCheckoutMetadata({
    required String ticketId,
    required bool isOvernight,
    required bool ticketLost,
    required Map<String, dynamic> appliedRate,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        isOvernight: Value(isOvernight),
        ticketLost: Value(ticketLost),
        appliedRateJson: Value(jsonEncode(appliedRate)),
      ),
    );
  }

  /// Online void request (`POST /tickets/:id/void`).
  Future<void> requestTicketVoid({
    required String serverTicketId,
    String? reason,
  }) async {
    if (AppConfig.useStubApi) return;
    if (!await InternetReachability.hasInternet()) {
      throw TransactionsApiException(
        'Device is offline. Connect to request a void.',
      );
    }
    final token = await _activeBearer();
    if (token == null || token.isEmpty) {
      throw TransactionsApiException('No active bearer token.');
    }
    final voidBody = await _transactionsApi.requestVoid(
      token: token,
      ticketId: serverTicketId,
      reason: reason,
    );
    final row = await _ticketByServerId(serverTicketId.trim());
    if (row != null) {
      final voidMeta = _voidAuditCompanion(voidBody);
      await (_db.update(_db.tickets)..where((t) => t.id.equals(row.id))).write(
        TicketsCompanion(
          status: const Value('void'),
          pendingVoidRequest: const Value(false),
          pendingVoidReason: const Value(null),
          voidReason: voidMeta.voidReason,
          voidedByJson: voidMeta.voidedByJson,
          voidedAt: voidMeta.voidedAt,
        ),
      );
      await _markVoidQueuesSyncedForTicket(row.id);
    }
  }

  /// PATCH `vehicle.plate_number` on the server and update local DB.
  ///
  /// Requires an active internet connection and a valid bearer token.
  /// If the ticket has no [serverTicketId] it has not synced yet; the update
  /// is applied locally only so it is included in the next sync.
  Future<void> updatePlateNumber({
    required String localTicketId,
    required String newPlate,
  }) async {
    final tid = localTicketId.trim();
    final plate = newPlate.trim().toUpperCase();
    if (tid.isEmpty) throw TransactionsApiException('Ticket id is empty.');

    final row = await ticketById(tid);
    if (row == null) throw TransactionsApiException('Ticket not found.');

    final serverId = row.serverTicketId?.trim() ?? '';
    if (serverId.isNotEmpty) {
      if (!await InternetReachability.hasInternet()) {
        await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
          TicketsCompanion(plateNumber: Value(plate)),
        );
        await enqueuePlatePatch(
          localTicketId: tid,
          serverTicketId: serverId,
          plateNumber: plate,
        );
        return;
      }
      final token = await _activeBearer();
      if (token == null || token.isEmpty) {
        throw TransactionsApiException('No active bearer token.');
      }
      await _transactionsApi.patchVehiclePlate(
        token: token,
        ticketId: serverId,
        plateNumber: plate,
      );
      await _markPlatePatchQueuesSyncedForTicket(tid);
    }

    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(plateNumber: Value(plate)),
    );
  }

  Future<void> enqueuePlatePatch({
    required String localTicketId,
    required String serverTicketId,
    required String plateNumber,
  }) async {
    final tid = localTicketId.trim();
    final sid = serverTicketId.trim();
    final plate = plateNumber.trim().toUpperCase();
    if (tid.isEmpty || sid.isEmpty || plate.isEmpty) return;

    final existing = await (_db.select(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('patch/plate') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .get();
    if (existing.isNotEmpty) {
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(existing.first.id)))
          .write(
        SyncQueueCompanion(
          payload: Value(
            jsonEncode(<String, dynamic>{
              'local_ticket_id': tid,
              'server_ticket_id': sid,
              'plate_number': plate,
            }),
          ),
          syncStatus: const Value('pending'),
        ),
      );
      _notifyLocalSyncQueueChanged();
      return;
    }

    final now = DateTime.now().toIso8601String();
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: _uuid.v4(),
            operation: 'patch/plate',
            queueTableName: 'tickets',
            recordId: tid,
            payload: jsonEncode(<String, dynamic>{
              'local_ticket_id': tid,
              'server_ticket_id': sid,
              'plate_number': plate,
            }),
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
    _notifyLocalSyncQueueChanged();
  }

  Future<void> syncQueuedPlatePatch(
    Map<String, dynamic> body,
    String token,
  ) async {
    var serverId = body['server_ticket_id']?.toString().trim() ?? '';
    final localId = body['local_ticket_id']?.toString().trim() ?? '';
    final plate = body['plate_number']?.toString().trim().toUpperCase() ?? '';
    if (plate.isEmpty) {
      throw StateError('Queued plate patch missing plate_number');
    }
    if (serverId.isEmpty && localId.isNotEmpty) {
      serverId = (await ticketById(localId))?.serverTicketId?.trim() ?? '';
    }
    if (serverId.isEmpty) {
      throw StateError('Queued plate patch missing server_ticket_id');
    }
    await _transactionsApi.patchVehiclePlate(
      token: token,
      ticketId: serverId,
      plateNumber: plate,
    );
    if (localId.isNotEmpty) {
      await (_db.update(_db.tickets)..where((t) => t.id.equals(localId))).write(
        TicketsCompanion(plateNumber: Value(plate)),
      );
    }
  }

  Future<void> _markPlatePatchQueuesSyncedForTicket(String ticketId) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.syncQueue)..where(
          (q) =>
              q.recordId.equals(tid) &
              q.queueTableName.equals('tickets') &
              q.operation.equals('patch/plate') &
              q.syncStatus.isIn(['pending', 'failed']),
        ))
        .write(const SyncQueueCompanion(syncStatus: Value('synced')));
  }

  /// Stores offline void intent until check-in sync sends `void_requested`.
  Future<void> storeOfflineVoidRequest(
    String localTicketId,
    String? reason,
  ) async {
    final tid = localTicketId.trim();
    if (tid.isEmpty) return;
    await (_db.update(_db.tickets)..where((t) => t.id.equals(tid))).write(
      TicketsCompanion(
        pendingVoidRequest: const Value(true),
        pendingVoidReason: Value(reason?.trim()),
      ),
    );
  }

  Future<void> enqueueCheckoutFinalize({
    required String ticketId,
    required String? serverTicketId,
    required double amount,
    required String timeOut,
    required bool isOvernight,
    required bool ticketLost,
    required List<Map<String, dynamic>> conditionCheckout,
    String? driverOut,
    double? cashTendered,
    Map<String, dynamic>? appliedRate,
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
      'condition_checkout': conditionCheckout,
      if (driverOut != null && driverOut.trim().isNotEmpty)
        'driver_out': driverOut.trim(),
      if (cashTendered != null && cashTendered > 0.009)
        'cash_tendered': cashTendered,
      if (appliedRate != null && appliedRate.isNotEmpty)
        'applied_rate': appliedRate,
    });
    await _db
        .into(_db.syncQueue)
        .insert(
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
    _notifyLocalSyncQueueChanged();
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
    final cashTenderedRaw = body['cash_tendered'] ?? body['cashTendered'];
    final cashTendered = cashTenderedRaw is num
        ? cashTenderedRaw.toDouble()
        : double.tryParse('$cashTenderedRaw');

    final appliedRaw = body['applied_rate'];
    final appliedRate = appliedRaw is Map
        ? Map<String, dynamic>.from(appliedRaw)
        : null;

    if (driverOut != null && driverOut.trim().isNotEmpty) {
      await _transactionsApi.patchTransactionDrivers(
        token: token,
        ticketId: serverId,
        driverOut: driverOut,
      );
    }

    return _transactionsApi.submitCheckOut(
      token: token,
      ticketId: serverId,
      amount: amount,
      timeOut: timeOut,
      isOvernight: isOvernight,
      ticketLost: ticketLost,
      cashTendered: cashTendered,
      conditionCheckout: conditionList,
      appliedRate: appliedRate,
    );
  }

  Future<int> countActiveTicketsForShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db
        .customSelect(
          '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'active'
''',
          variables: <Variable<Object>>[Variable.withString(sid)],
          readsFrom: {_db.tickets},
        )
        .getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Check-ins on the shift with `check_in_at` ≥ [sinceIso8601].
  Future<int> countCheckInsOnShiftSince({
    required String shiftId,
    required String sinceIso8601,
  }) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db
        .customSelect(
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
        )
        .getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> countCompletedCheckoutsForShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db
        .customSelect(
          '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
          variables: <Variable<Object>>[Variable.withString(sid)],
          readsFrom: {_db.tickets},
        )
        .getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<double> sumFeesForCompletedShift(String shiftId) async {
    final sid = shiftId.trim();
    if (sid.isEmpty) return 0;
    final row = await _db
        .customSelect(
          '''
SELECT COALESCE(SUM(fee), 0) AS s FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
          variables: <Variable<Object>>[Variable.withString(sid)],
          readsFrom: {_db.tickets},
        )
        .getSingle();
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

  /// All non-draft tickets for [shiftId], newest check-in first.
  Future<List<Ticket>> ticketsForShift(String shiftId) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where((t) => t.shiftId.equals(sid) & t.status.equals('draft').not())
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
                t.checkInAt.isSmallerThanValue(to) &
                t.status.equals('draft').not(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)])
          ..limit(limit))
        .get();
  }

  /// Recent tickets for dashboard: same shift, mixed status, cap [limit].
  Future<List<Ticket>> recentTicketsForShift(String shiftId, {int limit = 10}) {
    final sid = shiftId.trim();
    return (_db.select(_db.tickets)
          ..where((t) => t.shiftId.equals(sid) & t.status.equals('draft').not())
          ..orderBy([(t) => OrderingTerm.desc(t.checkInAt)])
          ..limit(limit))
        .get();
  }

  Future<Ticket?> ticketById(String id) {
    return (_db.select(
      _db.tickets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Recent-transaction detail: `GET /transactions/{id}` when online, else local Drift.
  ///
  /// When online, rates are synced from the API before computing the payment
  /// breakdown so the correct vehicle-type rates (e.g. Sedan ₱100) are used
  /// instead of the offline default (₱150). Drift is always the final fallback.
  ///
  /// [idOrTicketNumber] is the server UUID or `TKT-XXXX` from the dashboard list.
  Future<TicketDetailSnapshot?> loadTicketForDetail(
    String idOrTicketNumber,
  ) async {
    final key = idOrTicketNumber.trim();
    if (key.isEmpty) return null;

    final isOnline =
        !AppConfig.useStubApi && await InternetReachability.hasInternet();
    final token = isOnline ? await _activeBearer() : null;

    if (isOnline && token != null && token.isNotEmpty) {
      final map = await _fetchTransactionJsonForDetail(
        key: key,
        token: token,
      );

      // Determine the ticket (from server response or existing Drift row).
      final Ticket ticket;
      final Map<String, dynamic>? transactionJson;
      if (map != null) {
        ticket = await _upsertFromServerTransactionJson(map);
        transactionJson = map;
      } else {
        final local = await _localTicketByKey(key);
        if (local == null) return null;
        ticket = local;
        transactionJson = null;
      }

      // Refresh Drift rates from the API before computing the breakdown so the
      // correct per-vehicle-type fees (e.g. Sedan ₱100, not offline default
      // ₱150) are used. Errors are swallowed — Drift fallback still applies.
      // Guard: only sync when branchId is a valid UUID — legacy tickets may
      // store the branch name instead, which causes 400 from the API.
      final syncBranchId =
          _validUuidOrNull(ticket.branchId) ?? await _deviceBranchId;
      if (syncBranchId != null) {
        await _rateFetch.syncRatesForBranch(syncBranchId);
      }

      final parking = map != null
          ? TicketService._parkingFromTransactionJson(map)
          : null;
      final extras = _detailExtrasFrom(
        transactionJson: transactionJson,
        ticket: ticket,
      );
      final payment = await _resolvePaymentForTicket(
        ticket,
        transactionJson: transactionJson,
        appliedRate: extras.appliedRate,
      );
      if (payment != null) {
        await _persistPaymentSummary(ticket.id, payment);
      }
      return TicketDetailSnapshot(
        ticket: ticket,
        parking: parking ?? TicketService._parkingFromTicketRow(ticket),
        payment: payment,
        voidAudit: extras.voidAudit,
        isOvernight: extras.isOvernight,
        isTicketLost: extras.isTicketLost,
        appliedRate: extras.appliedRate,
        isOnline: true,
        valetTypeLabel: _valetTypeLabelForDetail(
          transactionJson: transactionJson,
          ticket: ticket,
        ),
      );
    }

    return _localDetailSnapshot(key);
  }

  /// `GET /transactions/{id}` — returns null on any failure so the caller falls
  /// back to local Drift. No secondary API hops (dashboard/summary or reports)
  /// because those rarely contain the specific ticket and add unnecessary latency.
  Future<Map<String, dynamic>?> _fetchTransactionJsonForDetail({
    required String key,
    required String token,
  }) async {
    try {
      return await _transactionsApi.getTransactionById(token: token, id: key);
    } on TransactionsApiException catch (e, st) {
      ValetLog.error(
        'TicketService.loadTicketForDetail',
        'GET /transactions/$key failed (${e.statusCode}) — using local Drift',
        e,
        st,
      );
    } catch (e, st) {
      ValetLog.error(
        'TicketService.loadTicketForDetail',
        'GET /transactions/$key failed — using local Drift',
        e,
        st,
      );
    }
    return null;
  }


  Future<TicketDetailSnapshot?> _localDetailSnapshot(String key) async {
    final ticket = await _localTicketByKey(key);
    if (ticket == null) return null;
    var parking = TicketService._parkingFromTicketRow(ticket);
    parking ??= await _parkingFromSyncQueue(ticket.id);
    final extras = _detailExtrasFrom(transactionJson: null, ticket: ticket);
    var payment = await _resolvePaymentForTicket(
      ticket,
      appliedRate: extras.appliedRate,
    );
    if (payment != null) {
      await _persistPaymentSummary(ticket.id, payment);
    }
    return TicketDetailSnapshot(
      ticket: ticket,
      parking: parking,
      payment: payment,
      voidAudit: extras.voidAudit,
      isOvernight: extras.isOvernight,
      isTicketLost: extras.isTicketLost,
      appliedRate: extras.appliedRate,
      isOnline: false,
      valetTypeLabel: _valetTypeLabelForDetail(
        transactionJson: null,
        ticket: ticket,
      ),
    );
  }

  static String? _valetTypeLabelForDetail({
    Map<String, dynamic>? transactionJson,
    required Ticket ticket,
  }) {
    if (transactionJson != null) {
      final fromApi = ValetTypeFormat.labelIfPresent(
        ValetTypeFormat.rawFromTransaction(transactionJson),
      );
      if (fromApi != null) return fromApi;
    }
    final fromMeta = ValetTypeFormat.fromDriverOutMeta(ticket.driverOut);
    if (fromMeta != null) return ValetTypeFormat.label(fromMeta);
    return null;
  }

  static String? _driverNameFromField(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final name = raw['name'] ?? raw['id'];
      return _normalizedDriverName(name?.toString());
    }
    return _normalizedDriverName(_scalarString(raw));
  }

  static String? _driverOutColumnFromServerTransaction(
    Map<String, dynamic> json,
  ) {
    final checkOutAt = _parseCheckOutTime(json);
    var status = _normalizeTicketStatus(json['status']?.toString() ?? 'active');
    if (checkOutAt != null && status == 'active') {
      status = 'completed';
    }
    final isCheckedOut = checkOutAt != null ||
        status == 'completed' ||
        status == 'lost';

    if (isCheckedOut) {
      return _driverNameFromField(json['driver_out'] ?? json['driverOut']);
    }

    final customer = _asStringKeyedMap(json['customer']) ?? const {};
    final customerName = customer['name']?.toString();
    final parkingMap = _mapField(json['parking']);
    return _encodeCheckoutMetaDriverOut(
      customerName: customerName,
      valetType: ValetTypeFormat.rawFromTransaction(json),
      parkingLevel: parkingMap['level']?.toString(),
      parkingSlot: parkingMap['slot']?.toString(),
    );
  }

  static ({
    VoidAuditInfo? voidAudit,
    bool? isOvernight,
    bool? isTicketLost,
    CheckoutPreviewRates? appliedRate,
  }) _detailExtrasFrom({
    Map<String, dynamic>? transactionJson,
    required Ticket ticket,
  }) {
    if (transactionJson != null) {
      final hasOvernight = transactionJson.containsKey('is_overnight') ||
          transactionJson.containsKey('isOvernight');
      final hasLost = transactionJson.containsKey('ticket_lost') ||
          transactionJson.containsKey('ticketLost');
      return (
        voidAudit: VoidAuditInfo.tryFromJson(transactionJson),
        isOvernight: hasOvernight
            ? TransactionPaymentFields.isOvernightFrom(transactionJson)
            : null,
        isTicketLost: hasLost
            ? TransactionPaymentFields.isTicketLostFrom(transactionJson)
            : null,
        appliedRate: CheckoutPreviewRates.fromJson(
          transactionJson['applied_rate'],
        ),
      );
    }

    VoidAuditInfo? voidAudit = _voidAuditFromTicketRow(ticket);
    if (voidAudit == null && ticket.pendingVoidRequest) {
      voidAudit = VoidAuditInfo(
        reason: ticket.pendingVoidReason,
      );
    }

    CheckoutPreviewRates? appliedRate;
    final rateRaw = ticket.appliedRateJson?.trim();
    if (rateRaw != null && rateRaw.isNotEmpty) {
      try {
        appliedRate = CheckoutPreviewRates.fromJson(
          jsonDecode(rateRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return (
      voidAudit: voidAudit,
      isOvernight: ticket.isOvernight,
      isTicketLost: ticket.ticketLost,
      appliedRate: appliedRate,
    );
  }

  static VoidAuditInfo? _voidAuditFromTicketRow(Ticket ticket) {
    final byRaw = ticket.voidedByJson?.trim();
    VoidedByUser? voidedBy;
    if (byRaw != null && byRaw.isNotEmpty) {
      try {
        voidedBy = VoidedByUser.tryFromJson(
          jsonDecode(byRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    final reason = ticket.voidReason?.trim();
    final at = ticket.voidedAt?.trim();
    if ((reason == null || reason.isEmpty) && voidedBy == null && at == null) {
      return null;
    }
    return VoidAuditInfo(
      reason: reason?.isNotEmpty == true ? reason : null,
      voidedBy: voidedBy,
      voidedAt: at?.isNotEmpty == true ? at : null,
    );
  }

  static ({
    Value<String?> voidReason,
    Value<String?> voidedByJson,
    Value<String?> voidedAt,
  }) _voidAuditCompanion(Map<String, dynamic> json) {
    final audit = VoidAuditInfo.tryFromJson(json);
    if (audit == null) {
      return (
        voidReason: const Value.absent(),
        voidedByJson: const Value.absent(),
        voidedAt: const Value.absent(),
      );
    }
    return (
      voidReason: audit.reason != null
          ? Value(audit.reason)
          : const Value.absent(),
      voidedByJson: audit.voidedBy != null
          ? Value(jsonEncode(audit.voidedBy!.toJson()))
          : const Value.absent(),
      voidedAt: audit.voidedAt != null
          ? Value(audit.voidedAt)
          : const Value.absent(),
    );
  }

  static String? _resolveVoidStatus(Map<String, dynamic> json) {
    if (VoidAuditInfo.isVoidStatus(json['status']?.toString())) {
      return 'void';
    }
    if (VoidAuditInfo.tryFromJson(json)?.isPopulated == true) {
      return 'void';
    }
    return null;
  }

  static TicketsCompanion _serverMetadataCompanion(Map<String, dynamic> json) {
    final vm = _vehicleMap(json);
    final vr =
        json['vr_no']?.toString().trim() ??
        vm['vr_no']?.toString().trim() ??
        vm['vrNo']?.toString().trim();
    final voidMeta = _voidAuditCompanion(json);
    final applied = json['applied_rate'];
    final appliedJson = applied is Map && applied.isNotEmpty
        ? jsonEncode(applied)
        : null;
    final isOvernight = json.containsKey('is_overnight') ||
            json.containsKey('isOvernight')
        ? TransactionPaymentFields.isOvernightFrom(json)
        : null;
    final ticketLost = json.containsKey('ticket_lost') ||
            json.containsKey('ticketLost')
        ? TransactionPaymentFields.isTicketLostFrom(json)
        : null;

    return TicketsCompanion(
      vrNo: vr != null && vr.isNotEmpty ? Value(vr) : const Value.absent(),
      voidReason: voidMeta.voidReason,
      voidedByJson: voidMeta.voidedByJson,
      voidedAt: voidMeta.voidedAt,
      appliedRateJson: appliedJson != null
          ? Value(appliedJson)
          : const Value.absent(),
      isOvernight: isOvernight != null
          ? Value(isOvernight)
          : const Value.absent(),
      ticketLost: ticketLost != null
          ? Value(ticketLost)
          : const Value.absent(),
    );
  }

  /// Resolves fee breakdown for ticket detail display.
  ///
  /// Prefers the stored [paymentSummaryJson] written at checkout time (which
  /// uses the actual server preview rates). Only falls back to recomputing from
  /// local Drift rates when no stored breakdown exists. Cash tendered / change
  /// are always merged from the best available source regardless.
  Future<TransactionPaymentSummary?> _resolvePaymentForTicket(
    Ticket ticket, {
    Map<String, dynamic>? transactionJson,
    CheckoutPreviewRates? appliedRate,
  }) async {
    final appliedFlatHours = appliedRate?.flatRateHours ?? 0;
    final stored = TransactionPaymentSummary.fromStoredJson(
      ticket.paymentSummaryJson,
    );
    final syncQueuePayment = await _paymentFromSyncQueueCheckout(ticket);

    final json = <String, dynamic>{
      if (ticket.fee != null) 'amount': ticket.fee,
      if (ticket.status == 'lost') 'ticket_lost': true,
      ...?transactionJson,
    };

    final cashTendered =
        TransactionPaymentFields.cashTenderedFrom(json) ??
        syncQueuePayment?.cashTendered ??
        stored?.cashTendered;

    final amount = TransactionPaymentFields.amountFrom(json);
    if (amount == null || amount < 0.009) return null;

    // Prefer stored breakdown — it was computed with the actual preview rates at
    // checkout time (e.g. flat ₱100 + overnight ₱500). Recomputing from local
    // Drift fallback rates would produce different flat-rate values.
    //
    // Guard: only trust the stored breakdown when the fee parts add up to the
    // total within ±₱1. If they don't match (e.g. flatRate was overwritten with
    // a stale offline default but overnight was not), the stored summary is
    // corrupt — fall through to recompute from local Drift rates.
    if (stored != null && stored.hasFlatRate && _storedBreakdownIsConsistent(stored, amount)) {
      final change = TransactionPaymentCalculator.computedChange(
        amount: amount,
        cashTendered: cashTendered,
      );
      return TransactionPaymentSummary(
        totalDue: amount,
        flatRate: stored.flatRate,
        flatRateLabel: stored.flatRateLabel,
        flatBlockHours: stored.flatBlockHours,
        succeedingHoursLabel: stored.succeedingHoursLabel,
        succeedingLineLabel: stored.succeedingLineLabel,
        succeedingRatePerHour: stored.succeedingRatePerHour,
        succeedingTotal: stored.succeedingTotal,
        overnightFee: stored.overnightFee,
        overnightStart: stored.overnightStart,
        overnightEnd: stored.overnightEnd,
        lostTicketFee: stored.lostTicketFee,
        cashTendered: cashTendered,
        change: change,
        isLostTicket: stored.isLostTicket,
        isOvernight: stored.isOvernight,
        durationMinutes: stored.durationMinutes,
      ).withFlatBlockHours(appliedFlatHours);
    }

    if (cashTendered != null) {
      json['cash_tendered'] = cashTendered;
    }

    final vehicleType = _vehicleTypeForPayment(ticket, transactionJson);

    final payment = await _paymentCalculator.fromTransactionJson(
      json: json,
      branchId: ticket.branchId,
      vehicleType: vehicleType,
      timeInOverride: PhilippineTime.fromApiIso(ticket.checkInAt),
      timeOutOverride:
          ticket.checkOutAt != null && ticket.checkOutAt!.isNotEmpty
          ? PhilippineTime.fromApiIso(ticket.checkOutAt!)
          : null,
      flatBlockHoursOverride:
          appliedFlatHours > 0 ? appliedFlatHours : null,
    );
    return payment?.withFlatBlockHours(appliedFlatHours);
  }

  /// Returns true when fee parts (flat + overnight + succeeding + lost) add up
  /// to [totalDue] within ±₱1. A mismatch means the stored breakdown was
  /// overwritten by a stale recompute that used incorrect offline-default rates.
  static bool _storedBreakdownIsConsistent(
    TransactionPaymentSummary s,
    double totalDue,
  ) {
    final parts = s.flatRate + s.overnightFee + s.succeedingTotal + s.lostTicketFee;
    return (parts - totalDue).abs() < 1.5;
  }

  static String? _vehicleTypeForPayment(
    Ticket ticket,
    Map<String, dynamic>? transactionJson,
  ) {
    if (transactionJson != null) {
      final vehicle = _mapField(transactionJson['vehicle']);
      final fromApi = vehicle['type']?.toString().trim();
      if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    }
    final fromTicket = ticket.vehicleType.trim();
    if (fromTicket.isNotEmpty) return fromTicket;
    return null;
  }

  Future<void> _persistPaymentSummary(
    String ticketId,
    TransactionPaymentSummary payment,
  ) async {
    await (_db.update(_db.tickets)..where((t) => t.id.equals(ticketId))).write(
      TicketsCompanion(paymentSummaryJson: Value(jsonEncode(payment.toJson()))),
    );
  }

  Future<TransactionPaymentSummary?> _paymentFromSyncQueueCheckout(
    Ticket ticket,
  ) async {
    final ticketId = ticket.id;
    final rows =
        await (_db.select(_db.syncQueue)
              ..where(
                (q) =>
                    q.recordId.equals(ticketId.trim()) &
                    q.operation.equals('checkout/finalize'),
              )
              ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])
              ..limit(1))
            .get();
    if (rows.isEmpty) return null;
    try {
      final body = jsonDecode(rows.first.payload);
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      final amount = TransactionPaymentFields.optionalMoney(
        map['amount'] ?? map['amount_paid'],
      );
      if (amount == null) return null;
      return _paymentCalculator.fromTransactionJson(
        json: {
          'amount': amount,
          'cash_tendered': map['cash_tendered'],
          'ticket_lost': map['ticket_lost'] == true,
        },
        branchId: ticket.branchId,
        vehicleType: ticket.vehicleType,
        timeInOverride: PhilippineTime.fromApiIso(ticket.checkInAt),
        timeOutOverride:
            ticket.checkOutAt != null && ticket.checkOutAt!.isNotEmpty
            ? PhilippineTime.fromApiIso(ticket.checkOutAt!)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<TicketParkingInfo?> _parkingFromSyncQueue(String ticketId) async {
    final row =
        await (_db.select(_db.syncQueue)
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
    final lostStatus = _normalizeTicketStatus(
      map['status']?.toString() ?? 'lost',
    );
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
    return (_db.select(
      _db.tickets,
    )..where((t) => t.serverTicketId.equals(u))).getSingleOrNull();
  }

  Future<({String shiftId, String userId, String branchId})?>
  _ticketUpsertContext() async {
    final session =
        await (_db.select(_db.sessions)
              ..where((x) => x.isActive.equals(true))
              ..limit(1))
            .getSingleOrNull();
    if (session == null) return null;
    final account =
        await (_db.select(_db.offlineAccounts)
              ..where((a) => a.id.equals(session.userId))
              ..limit(1))
            .getSingleOrNull();
    if (account == null) return null;
    final userIdStr = account.serverUserId.toString();
    final shift =
        await (_db.select(_db.shifts)
              ..where(
                (s) => s.userId.equals(userIdStr) & s.status.equals('open'),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (shift == null) return null;
    return (shiftId: shift.id, userId: userIdStr, branchId: shift.branchId);
  }

  Future<Ticket> _upsertFromServerTransactionJson(
    Map<String, dynamic> json, {
    TransactionPaymentSummary? paymentSummary,
    String? shiftIdOverride,
    bool? markExpressCashier,
  }) async {
    final serverUuid = json['id']?.toString().trim() ?? '';
    if (serverUuid.isEmpty) {
      throw TransactionsApiException('Server response missing id.');
    }
    final ticketNum =
        json['ticket_number']?.toString().trim() ??
        json['ticketNumber']?.toString().trim() ??
        json['qr_code']?.toString().trim() ??
        '';
    if (ticketNum.isEmpty) {
      throw TransactionsApiException('Server response missing ticket_number.');
    }

    final fields = _fieldsFromServerTransactionJson(json);
    final meta = _serverMetadataCompanion(json);
    final paymentJson = paymentSummary != null
        ? jsonEncode(paymentSummary.toJson())
        : null;
    final isExpress =
        markExpressCashier ?? _isExpressServerTransactionJson(json);

    final existing =
        await _ticketByServerId(serverUuid) ?? await ticketById(ticketNum);
    if (existing != null) {
      await (_db.update(
        _db.tickets,
      )..where((t) => t.id.equals(existing.id))).write(
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
          // Keep the device-recorded check-in wall time; server UTC can drift
          // from a slow handset clock and produce negative "parked for" values.
          checkInAt: existing.checkInAt.trim().isNotEmpty
              ? const Value.absent()
              : Value(
                  PhilippineTime.normalizeCheckInStorage(fields.checkInAt),
                ),
          checkOutAt: Value(fields.checkOutAt),
          fee: Value(fields.fee),
          status: Value(fields.status),
          driverIn: Value(fields.driverIn),
          driverOut: Value(fields.driverOut),
          parkingInfo: Value(fields.parkingInfo),
          paymentSummaryJson: paymentJson != null
              ? Value(paymentJson)
              : const Value.absent(),
          syncStatus: const Value('synced'),
          vrNo: meta.vrNo,
          voidReason: meta.voidReason,
          voidedByJson: meta.voidedByJson,
          voidedAt: meta.voidedAt,
          appliedRateJson: meta.appliedRateJson,
          isOvernight: meta.isOvernight,
          ticketLost: meta.ticketLost,
          isExpressCashier:
              isExpress ? const Value(true) : const Value.absent(),
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
    final resolvedShiftId = shiftIdOverride?.trim() ?? ctx.shiftId;
    final now = DateTime.now().toIso8601String();
    await _db
        .into(_db.tickets)
        .insert(
          TicketsCompanion.insert(
            id: ticketNum,
            shiftId: resolvedShiftId,
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
            checkInAt: PhilippineTime.normalizeCheckInStorage(fields.checkInAt),
            checkOutAt: Value(fields.checkOutAt),
            fee: Value(fields.fee),
            status: fields.status,
            syncStatus: 'synced',
            createdAt: now,
            serverTicketId: Value(serverUuid),
            driverIn: Value(fields.driverIn),
            driverOut: Value(fields.driverOut),
            parkingInfo: Value(fields.parkingInfo),
            paymentSummaryJson: paymentJson != null
                ? Value(paymentJson)
                : const Value.absent(),
            vrNo: meta.vrNo,
            voidReason: meta.voidReason,
            voidedByJson: meta.voidedByJson,
            voidedAt: meta.voidedAt,
            appliedRateJson: meta.appliedRateJson,
            isOvernight: meta.isOvernight,
            ticketLost: meta.ticketLost,
            isExpressCashier: Value(isExpress),
          ),
        );
    final out = await ticketById(ticketNum);
    if (out == null) {
      throw TransactionsApiException('Upsert failed after insert.');
    }
    return out;
  }

  static bool _isExpressServerTransactionJson(Map<String, dynamic> json) {
    for (final key in const [
      'express_cashier',
      'expressCashier',
      'is_express_cashier',
      'isExpressCashier',
    ]) {
      final value = json[key];
      if (value == true || value == 1 || value == 'true' || value == '1') {
        return true;
      }
    }
    return false;
  }

  static bool _isTransactionToday(Map<String, dynamic> json) {
    final raw = json['time_in'] ??
        json['check_in_at'] ??
        json['checkInAt'] ??
        json['created_at'] ??
        json['createdAt'];
    if (raw == null) return true;
    final text = raw.toString().trim();
    if (text.isEmpty) return true;
    final ph = PhilippineTime.fromApiIso(text);
    final now = PhilippineTime.now();
    return ph.year == now.year && ph.month == now.month && ph.day == now.day;
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
    final phone =
        _scalarString(
          customer['contact_number'] ?? customer['contactNumber'],
        ) ??
        '';
    final checkOutAt = _parseCheckOutTime(json);
    var status = _normalizeTicketStatus(json['status']?.toString() ?? 'active');
    if (checkOutAt != null && status == 'active') {
      status = 'completed';
    }

    final parkingMap = _mapField(json['parking']);
    final parkingJson = TicketParkingInfo.fromParkingMap(
      parkingMap,
    ).toJsonString();

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
      driverIn: _driverNameFromField(json['driver_in'] ?? json['driverIn']),
      driverOut: _driverOutColumnFromServerTransaction(json),
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
    return CheckInTimeResolution.resolveWallIsoFromTransaction(json);
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

  static double? _feeFromTransaction(Map<String, dynamic> json) =>
      TransactionPaymentFields.amountFrom(json);

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
    final cond =
        _asStringKeyedMap(json['condition_checkin']) ??
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
    final cond =
        _asStringKeyedMap(json['condition_checkin']) ??
        _asStringKeyedMap(json['conditionCheckin']);
    if (cond == null) return null;
    return _scalarString(cond['signature']);
  }

  static String _normalizeTicketStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'lost') return 'lost';
    if (s == 'void' || s == 'voided') return 'void';
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
    final s =
        await (_db.select(_db.sessions)
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

class _BatchCheckInEntry {
  const _BatchCheckInEntry({
    required this.row,
    required this.item,
    required this.ticket,
  });

  final SyncQueueData row;
  final Map<String, dynamic> item;
  final Ticket? ticket;
}
