import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../local/db/app_database.dart';
import '../remote/area_detail.dart';

/// Pulls branch standard + per-vehicle-type rates from the API into Drift [rates].
class RateFetchService {
  RateFetchService(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

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

  /// Preferred sync: area detail API → local [rates] table.
  Future<void> syncRatesForBranchArea({
    required String branchId,
    required String areaId,
  }) async {
    final detail = await fetchAreaDetail(
      branchId: branchId,
      areaId: areaId,
    );
    if (detail == null) {
      await syncRatesForBranch(branchId);
      return;
    }
    await cacheAreaDetailRates(branchId: branchId, detail: detail);
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
    final flatHours = CheckoutPricing.defaultFlatBlockHours;
    final areaOvernightCutoff = detail.overnightCutoff;
    if (detail.standard.hasAny) {
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: 'Standard',
        flatHours: flatHours,
        flat: detail.standard.flatRate.toDouble(),
        succeeding: detail.standard.succeedingRate.toDouble(),
        overnight: detail.standard.overnightFee.toDouble(),
        lost: detail.standard.lostTicketFee.toDouble(),
        overnightCutoff: areaOvernightCutoff,
      );
    }

    final lostFallback = detail.standard.lostTicketFee > 0
        ? detail.standard.lostTicketFee.toDouble()
        : StandardParkingRates.offlineDefault.lostTicketFeePesos.toDouble();

    for (final row in detail.vehicleTypeRates) {
      final vt = _mapServerVehicleTypeName(row.name) ?? _vehicleTypeKey(row.name);
      if (vt == null) continue;
      var lost = row.fees.lostTicketFee.toDouble();
      if (lost <= 0) lost = lostFallback;
      await _upsertRateRow(
        branchId: branchId,
        vehicleType: vt,
        flatHours: flatHours,
        flat: row.fees.flatRate.toDouble(),
        succeeding: row.fees.succeedingRate.toDouble(),
        overnight: row.fees.overnightFee.toDouble(),
        lost: lost,
        overnightCutoff: areaOvernightCutoff,
      );
    }
  }

  static String? _vehicleTypeKey(String displayName) {
    final n = displayName.trim().toLowerCase();
    if (n.isEmpty) return null;
    return n.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  /// GET branch `/rates` then vehicle-types; on partial failure keeps whatever succeeded.
  Future<void> syncRatesForBranch(String branchId) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    if (bid == '_' || bid.isEmpty) return;
    if (AppConfig.useStubApi) return;

    final token = await _bearer();
    if (token == null) return;

    final opts = Options(
      headers: {'Authorization': 'Bearer $token'},
      validateStatus: (s) => s != null && s < 500,
    );

    StandardParkingRates? standardRates;
    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchStandardRatesUrl(bid),
        options: opts,
      );
      if (res.statusCode == 200) {
        final m = _asStringKeyedMap(res.data);
        if (m != null) {
          final parsed = _standardRatesFromMap(m);
          if (parsed != null &&
              (parsed.flatRatePesos > 0 || parsed.succeedingHourPesos > 0)) {
            standardRates = parsed;
            await _upsertRateRow(
              branchId: bid,
              vehicleType: 'Standard',
              flatHours: CheckoutPricing.defaultFlatBlockHours,
              flat: parsed.flatRatePesos.toDouble(),
              succeeding: parsed.succeedingHourPesos.toDouble(),
              overnight: parsed.overnightFeePesos.toDouble(),
              lost: parsed.lostTicketFeePesos.toDouble(),
              overnightCutoff: _overnightCutoffFromMap(m),
            );
          }
        }
      }
    } catch (e, st) {
      ValetLog.error(
        'RateFetchService',
        'GET branch standard rates failed',
        e,
        st,
      );
    }

    final lostFallback = (standardRates ?? StandardParkingRates.offlineDefault)
        .lostTicketFeePesos
        .toDouble();

    try {
      final res = await _dio.get<dynamic>(
        AppConfig.branchVehicleTypeRatesUrl(bid),
        options: opts,
      );
      if (res.statusCode != 200) return;

      final list = _asListOfMaps(res.data);
      for (final row in list) {
        if (!_isActiveStatus(row['status'])) continue;
        final name = row['name']?.toString().trim() ?? '';
        final vt = _mapServerVehicleTypeName(name);
        if (vt == null) continue;

        final flat = _doubleField(row, const ['flatRate', 'flat_rate']);
        final succeeding =
            _doubleField(row, const ['succeedingRate', 'succeeding_rate']);
        final overnight =
            _doubleField(row, const ['overnightFee', 'overnight_fee']);
        var lost = _doubleField(row, const ['lostTicketFee', 'lost_ticket_fee']);
        if (lost <= 0) lost = lostFallback;

        await _upsertRateRow(
          branchId: bid,
          vehicleType: vt,
          flatHours: CheckoutPricing.defaultFlatBlockHours,
          flat: flat,
          succeeding: succeeding,
          overnight: overnight,
          lost: lost,
          overnightCutoff: _overnightCutoffFromMap(row),
        );
      }
    } catch (e, st) {
      ValetLog.error(
        'RateFetchService',
        'GET vehicle-type rates failed — Standard fallback only if present',
        e,
        st,
      );
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
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

  static StandardParkingRates? _standardRatesFromMap(Map<String, dynamic> m) {
    int pick(String camel, String snake) {
      final v = m[camel] ?? m[snake];
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return StandardParkingRates(
      flatRatePesos: pick('flatRate', 'flat_rate'),
      succeedingHourPesos: pick('succeedingRate', 'succeeding_rate'),
      overnightFeePesos: pick('overnightFee', 'overnight_fee'),
      lostTicketFeePesos: pick('lostTicketFee', 'lost_ticket_fee'),
    );
  }

  static String? _overnightCutoffFromMap(Map<String, dynamic> m) {
    for (final k in const ['overnight_cutoff', 'overnightCutoff']) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static double _doubleField(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v != null) {
        final d = double.tryParse(v.toString());
        if (d != null) return d;
      }
    }
    return 0;
  }

  static bool _isActiveStatus(dynamic status) {
    if (status == null) return true;
    return status.toString().toUpperCase() == 'ACTIVE';
  }

  /// Maps API `name` to local `rates.vehicle_type` (aligned with check-out keys).
  static String? _mapServerVehicleTypeName(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return null;
    if (n.contains('ev') || n.contains('phev')) return 'ev_phev';
    if (n.contains('luxury')) return 'luxury';
    if (n.contains('sedan') || n.contains('hatchback')) return 'sedan';
    if (n.contains('suv') && n.contains('van')) return 'suv';
    if (n == 'van' || (n.contains('van') && !n.contains('suv'))) return 'van';
    if (n.contains('suv')) return 'suv';
    return null;
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
