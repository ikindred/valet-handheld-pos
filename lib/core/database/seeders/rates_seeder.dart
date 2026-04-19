import 'package:drift/drift.dart';

import '../../../data/local/db/app_database.dart';
import '../../../features/check_out/domain/checkout_pricing.dart';

/// Dev/test: seeds `rates` like a successful online fetch + local persist.
///
/// Branch slugs are not stored in a `branches` table — [branchSlugByDisplayName]
/// maps human names to the `branch_id` strings used elsewhere (e.g. `device_info`).
class RatesSeeder {
  /// Display name → `rates.branch_id` slug (no DB migration; local convention only).
  static const branchSlugByDisplayName = <String, String>{
    'Jazz Mall': 'jazz-mall',
    'SM North EDSA': 'sm-north-edsa',
    'Trinoma': 'trinoma',
    'Eastwood City': 'eastwood-city',
    'Vertis North': 'vertis-north',
  };

  /// `(vehicleType, flat, succeeding)` — overnight/lost match branch defaults.
  static const _vehicleTiers = <(String, double, double)>[
    ('Standard', 150, 30),
    ('sedan', 150, 30),
    ('suv', 180, 40),
    ('van', 180, 40),
    ('luxury', 220, 50),
    ('ev_phev', 160, 35),
  ];

  /// One row per (branch, vehicle type); [InsertMode.insertOrReplace] is safe to run repeatedly.
  Future<void> seed(AppDatabase db) async {
    final now = DateTime.now().toIso8601String();
    const syncStatus = 'synced';
    const overnight = 200.0;
    const lost = 200.0;
    final hours = CheckoutPricing.defaultFlatBlockHours;

    for (final slug in branchSlugByDisplayName.values) {
      for (final tier in _vehicleTiers) {
        final (vehicleType, flat, succeeding) = tier;
        final id = 'seed-rate-$slug-$vehicleType';
        await db.into(db.rates).insert(
              RatesCompanion.insert(
                id: id,
                branchId: slug,
                vehicleType: vehicleType,
                flatRateHours: hours,
                flatRateFee: flat,
                succeedingHourFee: succeeding,
                overnightFee: overnight,
                lostTicketFee: lost,
                syncStatus: syncStatus,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    }
  }
}
