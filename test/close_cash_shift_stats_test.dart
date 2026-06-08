import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/cash/models/close_cash_shift_stats.dart';
import 'package:valet_handheld_pos/features/check_in/domain/vehicle_body_type.dart';

void main() {
  test('vehicleTypeLabel maps rate keys to display labels', () {
    expect(CloseCashShiftStats.vehicleTypeLabel('sedan'), 'Sedan/Crossover');
    expect(CloseCashShiftStats.vehicleTypeLabel('ev_phev'), 'EV/PHEV');
    expect(CloseCashShiftStats.vehicleTypeLabel(''), 'Unspecified');
  });

  test('fromAggregates lists every vehicle type with counts', () {
    final stats = CloseCashShiftStats.fromAggregates(
      checkInCount: 5,
      checkoutCount: 4,
      vehiclesIn: 0,
      totalSales: 1200,
      openingFloat: 500,
      byVehicleType: {
        'sedan': 2,
        'suv': 4,
      },
    );
    expect(stats.checkoutCount, 4);
    expect(stats.vehicleTypes.length, VehicleBodyType.values.length);
    expect(
      stats.vehicleTypes.firstWhere((e) => e.label == 'SUV').count,
      4,
    );
    expect(
      stats.vehicleTypes.firstWhere((e) => e.label == 'Van').count,
      0,
    );
  });
}
