import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../local/db/app_database.dart';
import '../remote/area_detail.dart';
import 'parking_layout_service.dart';

/// Pulls branch standard + per-vehicle-type rates from the API into Drift [rates].
class RateFetchService {
  RateFetchService(this._db, this._dio, [ParkingLayoutService? parkingLayout])
      : _parkingLayout = parkingLayout ?? ParkingLayoutService(_db);

  final AppDatabase _db;
  final Dio _dio;
  final ParkingLayoutService _parkingLayout;

  static const _uuid = Uuid();

  Future<String?> _bearer() async {
    final s = await (_db.select(_db.sessions)
          ..where((x) => x.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    final t = s?.authToken;
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// `GET /branches/{branchId}/areas/{areaId}` — standard + vehicle-type rates.
  Future<AreaDetail?> fetchAreaDetail({
    required String branchId,
    required String areaId,
  }) async {
    if (AppConfig.useStubApi) return null;
    final token = await _bearer();
    if (token == null) return null;

    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchAreaDetailUrl(branchId, areaId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode != 200) {
        ValetLog.warning(
          'RateFetchService',
          'GET area detail HTTP ${res.statusCode}',
        );
        return null;
      }
      return AreaDetail.fromResponseData(res.data);
    } catch (e, st) {
      ValetLog.error('RateFetchService', 'GET area detail failed', e, st);
      return null;
    }
  }

  /// `GET /rates/branches/{branchId}` — `standardRates`, `areaOverrides`, `vehicleTypeRates`.
  Future<BranchRatesSnapshot?> fetchBranchRatesForArea({
    required String branchId,
    required String areaId,
    String areaCode = '',
  }) async {
    if (AppConfig.useStubApi) return null;
    final token = await _bearer();
    if (token == null) return null;

    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchRatesUrl(branchId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode != 200) {
        ValetLog.warning(
          'RateFetchService',
          'GET branch rates HTTP ${res.statusCode}',
        );
        return null;
      }
      final payload = BranchRatesApiPayload.fromResponseData(res.data);
      if (payload == null) return null;
      return payload.resolveForArea(
        areaId: areaId,
        areaCode: areaCode,
        defaultFlatBlockHours: CheckoutPricing.defaultFlatBlockHours,
      );
    } catch (e, st) {
      ValetLog.error('RateFetchService', 'GET branch rates failed', e, st);
      return null;
    }
  }

  /// `GET /branches/{branchId}` — nested `rate` object (Swagger branch detail).
  Future<BranchRatesSnapshot?> fetchBranchRatesSnapshot(String branchId) async {
    if (AppConfig.useStubApi) return null;
    final token = await _bearer();
    if (token == null) return null;

    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchDetailUrl(branchId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode != 200) {
        ValetLog.warning(
          'RateFetchService',
          'GET branch detail HTTP ${res.statusCode}',
        );
        return null;
      }
      var snapshot = BranchRatesSnapshot.fromResponseData(
        res.data,
        defaultFlatBlockHours: CheckoutPricing.defaultFlatBlockHours,
      );
      if (snapshot == null) return null;

      if (snapshot.vehicleTypeRates.isEmpty) {
        final vehicleTypes = await _fetchVehicleTypeRateRows(branchId, token);
        if (vehicleTypes.isNotEmpty) {
          snapshot = BranchRatesSnapshot(
            standard: snapshot.standard,
            vehicleTypeRates: vehicleTypes,
            overnightTimes: snapshot.overnightTimes,
            flatBlockHours: snapshot.flatBlockHours,
          );
        }
      }
      return snapshot;
    } catch (e, st) {
      ValetLog.error('RateFetchService', 'GET branch detail failed', e, st);
      return null;
    }
  }

  Future<List<VehicleTypeRateRow>> _fetchVehicleTypeRateRows(
    String branchId,
    String token,
  ) async {
    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchVehicleTypeRatesUrl(branchId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (res.statusCode != 200) return const [];

      final rows = <VehicleTypeRateRow>[];
      for (final row in _asListOfMaps(res.data)) {
        if (!_isActiveStatus(row['status'])) continue;
        final name = row['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final fees = ParkingRateFees.fromJson(row);
        if (!fees.hasAny) continue;
        rows.add(
          VehicleTypeRateRow(
            id: (row['id'] ?? name).toString(),
            name: name,
            fees: fees,
            flatRateHours: BranchRatesSnapshot.flatHoursFromMap(row),
          ),
        );
      }
      return rows;
    } catch (e, st) {
      ValetLog.error(
        'RateFetchService',
        'GET vehicle-type rates failed',
        e,
        st,
      );
      return const [];
    }
  }

  /// Persists branch detail + optional vehicle-type rates into Drift.
  Future<void> cacheBranchRatesSnapshot({
    required String branchId,
    required BranchRatesSnapshot snapshot,
  }) async {
    await _persistOvernightWindowConfig(
      branchId: branchId,
      start: snapshot.overnightTimes.start,
      end: snapshot.overnightTimes.end,
    );
    if (snapshot.standard.hasAny) {
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: 'Standard',
        flatHours: snapshot.flatBlockHours,
        flat: snapshot.standard.flatRate.toDouble(),
        succeeding: snapshot.standard.succeedingRate.toDouble(),
        overnight: snapshot.standard.overnightFee.toDouble(),
        lost: snapshot.standard.lostTicketFee.toDouble(),
        overnightCutoff: snapshot.overnightTimes.start,
      );
    }
    for (final row in snapshot.vehicleTypeRates) {
      final vt =
          BranchRatesSnapshot.mapServerVehicleTypeName(row.name) ??
          _vehicleTypeKey(row.name);
      if (vt == null) continue;
      final rowFlatHours = row.flatRateHours > 0
          ? row.flatRateHours
          : snapshot.flatBlockHours;
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: vt,
        flatHours: rowFlatHours,
        flat: row.fees.flatRate.toDouble(),
        succeeding: row.fees.succeedingRate.toDouble(),
        overnight: row.fees.overnightFee.toDouble(),
        lost: row.fees.lostTicketFee.toDouble(),
        overnightCutoff: snapshot.overnightTimes.start,
      );
    }
  }

  /// Preferred sync: `GET /rates/branches/:id` for area fees; area detail for layout only.
  Future<void> syncRatesForBranchArea({
    required String branchId,
    required String areaId,
  }) async {
    final detail = await fetchAreaDetail(
      branchId: branchId,
      areaId: areaId,
    );
    final areaCode = detail?.code ?? '';
    final snapshot = await fetchBranchRatesForArea(
      branchId: branchId,
      areaId: areaId,
      areaCode: areaCode,
    );
    if (snapshot != null && (snapshot.standard.hasAny || snapshot.vehicleTypeRates.isNotEmpty)) {
      await cacheBranchRatesSnapshot(branchId: branchId, snapshot: snapshot);
    } else if (detail != null) {
      await cacheAreaDetailRates(branchId: branchId, detail: detail);
    } else {
      await syncRatesForBranch(branchId);
    }
    if (detail != null && detail.levels.isNotEmpty) {
      await _parkingLayout.saveLevels(
        branchId: branchId,
        areaId: areaId,
        levels: detail.levels,
      );
    }
  }

  /// Writes standard + vehicle-type fees from area detail into Drift [rates].
  Future<void> cacheAreaDetailRates({
    required String branchId,
    required AreaDetail detail,
  }) =>
      _persistAreaRatesDetail(branchId: branchId, detail: detail);

  Future<void> _persistAreaRatesDetail({
    required String branchId,
    required AreaDetail detail,
  }) async {
    final flatHours = detail.flatBlockHours > 0
        ? detail.flatBlockHours
        : CheckoutPricing.defaultFlatBlockHours;
    final areaOvernight = detail.overnightTimes;
    await _persistOvernightWindowConfig(
      branchId: branchId,
      start: areaOvernight.start,
      end: areaOvernight.end,
    );
    if (detail.standard.hasAny) {
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: 'Standard',
        flatHours: flatHours,
        flat: detail.standard.flatRate.toDouble(),
        succeeding: detail.standard.succeedingRate.toDouble(),
        overnight: detail.standard.overnightFee.toDouble(),
        lost: detail.standard.lostTicketFee.toDouble(),
        overnightCutoff: areaOvernight.start,
      );
    }

    final lostFallback = detail.standard.lostTicketFee > 0
        ? detail.standard.lostTicketFee.toDouble()
        : StandardParkingRates.offlineDefault.lostTicketFeePesos.toDouble();

    for (final row in detail.vehicleTypeRates) {
      final vt =
          BranchRatesSnapshot.mapServerVehicleTypeName(row.name) ??
          _vehicleTypeKey(row.name);
      if (vt == null) continue;
      var lost = row.fees.lostTicketFee.toDouble();
      if (lost <= 0) lost = lostFallback;
      final rowFlatHours = row.flatRateHours > 0 ? row.flatRateHours : flatHours;
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: vt,
        flatHours: rowFlatHours,
        flat: row.fees.flatRate.toDouble(),
        succeeding: row.fees.succeedingRate.toDouble(),
        overnight: row.fees.overnightFee.toDouble(),
        lost: lost,
        overnightCutoff: areaOvernight.start,
      );
    }
  }

  static String? _vehicleTypeKey(String displayName) {
    final n = displayName.trim().toLowerCase();
    if (n.isEmpty) return null;
    return n.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  /// `GET /rates/branches/:branchId` (branch default — no area override).
  Future<void> syncRatesForBranch(String branchId) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    if (bid == '_' || bid.isEmpty) return;
    if (AppConfig.useStubApi) return;

    final snapshot = await fetchBranchRatesForArea(
      branchId: bid,
      areaId: '',
      areaCode: '',
    );
    if (snapshot != null &&
        (snapshot.standard.hasAny || snapshot.vehicleTypeRates.isNotEmpty)) {
      await cacheBranchRatesSnapshot(branchId: bid, snapshot: snapshot);
      return;
    }

    final legacy = await fetchBranchRatesSnapshot(bid);
    if (legacy != null && legacy.standard.hasAny) {
      await cacheBranchRatesSnapshot(branchId: bid, snapshot: legacy);
    }
  }

  static List<Map<String, dynamic>> _asListOfMaps(dynamic data) {
    if (data is List) {
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) e
          else if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      for (final key in const ['data', 'items', 'results', 'rows']) {
        final v = m[key];
        final nested = _asListOfMaps(v);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  Future<void> _persistOvernightWindowConfig({
    required String branchId,
    String? start,
    String? end,
  }) async {
    final bid = branchId.trim();
    if (bid.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    if (start != null && start.trim().isNotEmpty) {
      await _upsertBranchConfigRow(
        branchId: bid,
        configKey: 'overnight_start_time',
        configValue: start.trim(),
        updatedAt: now,
      );
    }
    if (end != null && end.trim().isNotEmpty) {
      await _upsertBranchConfigRow(
        branchId: bid,
        configKey: 'overnight_end_time',
        configValue: end.trim(),
        updatedAt: now,
      );
    }
  }

  Future<void> _upsertBranchConfigRow({
    required String branchId,
    required String configKey,
    required String configValue,
    required String updatedAt,
  }) async {
    final existing = await (_db.select(_db.branchConfigs)
          ..where(
            (c) =>
                c.branchId.equals(branchId) & c.configKey.equals(configKey),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.branchConfigs)..where((c) => c.id.equals(existing.id)))
          .write(
        BranchConfigsCompanion(
          configValue: Value(configValue),
          syncStatus: const Value('synced'),
          updatedAt: Value(updatedAt),
        ),
      );
    } else {
      await _db.into(_db.branchConfigs).insert(
            BranchConfigsCompanion.insert(
              id: _uuid.v4(),
              branchId: branchId,
              configKey: configKey,
              configValue: configValue,
              syncStatus: 'synced',
              updatedAt: updatedAt,
            ),
          );
    }
  }

  static bool _isActiveStatus(dynamic status) {
    if (status == null) return true;
    return status.toString().toUpperCase() == 'ACTIVE';
  }

  Future<void> _upsertRateRow({
    required String branchId,
    required String vehicleType,
    required int flatHours,
    required double flat,
    required double succeeding,
    required double overnight,
    required double lost,
    String? overnightCutoff,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await (_db.select(_db.rates)
          ..where(
            (r) =>
                r.branchId.equals(branchId) & r.vehicleType.equals(vehicleType),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.rates)..where((r) => r.id.equals(existing.id)))
          .write(
        RatesCompanion(
          flatRateHours: Value(flatHours),
          flatRateFee: Value(flat),
          succeedingHourFee: Value(succeeding),
          overnightFee: Value(overnight),
          lostTicketFee: Value(lost),
          overnightCutoff: Value(overnightCutoff),
          syncStatus: const Value('synced'),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _db.into(_db.rates).insert(
            RatesCompanion.insert(
              id: _uuid.v4(),
              branchId: branchId,
              vehicleType: vehicleType,
              flatRateHours: flatHours,
              flatRateFee: flat,
              succeedingHourFee: succeeding,
              overnightFee: overnight,
              lostTicketFee: lost,
              overnightCutoff: Value(overnightCutoff),
              syncStatus: 'synced',
              updatedAt: now,
            ),
          );
    }
  }
}
