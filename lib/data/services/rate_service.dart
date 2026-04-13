import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/session/standard_parking_rates.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../local/db/app_database.dart';

/// Resolved checkout fees from `rates` + flat block length.
typedef CheckoutRatesResolved = ({
  StandardParkingRates rates,
  int flatBlockHours,
});

/// Reads `rates` (Drift). Other services must not query `rates` directly.
class RateService {
  RateService(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Distinct `vehicle_type` values for UI (e.g. check-in dropdown).
  Future<List<String>> getDistinctVehicleTypesForBranch(String branchId) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final rows = await (_db.select(_db.rates)
          ..where((r) => r.branchId.equals(bid)))
        .get();
    final set = rows.map((r) => r.vehicleType).toSet().toList()..sort();
    return set;
  }

  /// When [rates] has no rows for [branchId], insert one **Standard** row using
  /// login [StandardParkingRates] (pesos → double). No-op if rows exist or [rates] is null.
  Future<void> syncFromAuthIfEmpty({
    required String branchId,
    StandardParkingRates? rates,
  }) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final existing = await (_db.select(_db.rates)
          ..where((r) => r.branchId.equals(bid)))
        .get();
    if (existing.isNotEmpty || rates == null) return;

    final now = DateTime.now().toIso8601String();
    await _db.into(_db.rates).insert(
          RatesCompanion.insert(
            id: _uuid.v4(),
            branchId: bid,
            vehicleType: 'Standard',
            flatRateHours: CheckoutPricing.defaultFlatBlockHours,
            flatRateFee: rates.flatRatePesos.toDouble(),
            succeedingHourFee: rates.succeedingHourPesos.toDouble(),
            overnightFee: rates.overnightFeePesos.toDouble(),
            lostTicketFee: rates.lostTicketFeePesos.toDouble(),
            syncStatus: 'synced',
            updatedAt: now,
          ),
        );
  }

  /// Picks a `rates` row for [branchId]: exact [vehicleType] (case-insensitive), else **Standard**,
  /// else first row. Returns null when there are no rows for the branch.
  Future<CheckoutRatesResolved?> checkoutRatesResolved({
    required String branchId,
    String? vehicleType,
  }) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final rows = await (_db.select(_db.rates)
          ..where((r) => r.branchId.equals(bid)))
        .get();
    if (rows.isEmpty) return null;
    final want = (vehicleType ?? '').trim().toLowerCase();
    Rate? pick;
    if (want.isNotEmpty) {
      for (final r in rows) {
        if (r.vehicleType.trim().toLowerCase() == want) {
          pick = r;
          break;
        }
      }
    }
    pick ??= _firstWhereIgnoreCase(rows, 'standard') ?? rows.first;
    final hours = pick.flatRateHours <= 0
        ? CheckoutPricing.defaultFlatBlockHours
        : pick.flatRateHours;
    return (
      rates: StandardParkingRates(
        flatRatePesos: pick.flatRateFee.round(),
        succeedingHourPesos: pick.succeedingHourFee.round(),
        overnightFeePesos: pick.overnightFee.round(),
        lostTicketFeePesos: pick.lostTicketFee.round(),
      ),
      flatBlockHours: hours,
    );
  }

  static Rate? _firstWhereIgnoreCase(List<Rate> rows, String vehicleType) {
    final w = vehicleType.trim().toLowerCase();
    for (final r in rows) {
      if (r.vehicleType.trim().toLowerCase() == w) return r;
    }
    return null;
  }

  /// JSON snapshot of all rate rows for a branch (printer / future sync).
  Future<String> ratesJsonForBranch(String branchId) async {
    final bid = branchId.trim().isEmpty ? '_' : branchId.trim();
    final rows = await (_db.select(_db.rates)
          ..where((r) => r.branchId.equals(bid)))
        .get();
    return jsonEncode([
      for (final r in rows)
        {
          'id': r.id,
          'vehicle_type': r.vehicleType,
          'flat_rate_hours': r.flatRateHours,
          'flat_rate_fee': r.flatRateFee,
          'succeeding_hour_fee': r.succeedingHourFee,
          'overnight_fee': r.overnightFee,
          'lost_ticket_fee': r.lostTicketFee,
        },
    ]);
  }
}
