import '../../check_in/domain/vehicle_body_type.dart';

class CloseCashVehicleTypeStat {
  const CloseCashVehicleTypeStat({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

/// Shift checkout stats for close-cash summary (aligned with dashboard when online).
class CloseCashShiftStats {
  const CloseCashShiftStats({
    required this.checkInCount,
    required this.checkoutCount,
    required this.vehiclesIn,
    required this.totalSales,
    required this.openingFloat,
    required this.vehicleTypes,
  });

  final int checkInCount;
  final int checkoutCount;
  final int vehiclesIn;
  final double totalSales;
  final double openingFloat;
  final List<CloseCashVehicleTypeStat> vehicleTypes;

  static String vehicleTypeLabel(String rawKey) {
    final label = vehicleTypeDisplayLabel(rawKey);
    return label.isEmpty ? 'Unspecified' : label;
  }

  factory CloseCashShiftStats.fromAggregates({
    required int checkInCount,
    required int checkoutCount,
    required int vehiclesIn,
    required double totalSales,
    required double openingFloat,
    required Map<String, int> byVehicleType,
  }) {
    final rows = <CloseCashVehicleTypeStat>[
      for (final type in VehicleBodyType.values)
        CloseCashVehicleTypeStat(
          label: type.label,
          count: byVehicleType[type.rateKey] ?? 0,
        ),
    ];
    return CloseCashShiftStats(
      checkInCount: checkInCount,
      checkoutCount: checkoutCount,
      vehiclesIn: vehiclesIn,
      totalSales: totalSales,
      openingFloat: openingFloat,
      vehicleTypes: rows,
    );
  }
}
