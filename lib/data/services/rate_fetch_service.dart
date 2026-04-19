import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../local/db/app_database.dart';

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
              syncStatus: 'synced',
              updatedAt: now,
            ),
          );
    }
  }
}
