import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/close_cash_receipt_data.dart';
import 'package:valet_handheld_pos/features/cash/models/close_cash_shift_stats.dart';
import 'package:valet_handheld_pos/features/check_in/domain/vehicle_body_type.dart';

void main() {
  test('fromClose builds receipt fields for thermal print', () {
    final data = CloseCashReceiptData.fromClose(
      branch: 'SM Sta Rosa',
      area: 'Valet Area',
      cashierName: 'Kindred Inocencio',
      openedAtIso: '2026-06-06T08:00:00.000Z',
      closedAtIso: '2026-06-06T17:00:00.000Z',
      stats: CloseCashShiftStats.fromAggregates(
        checkInCount: 4,
        checkoutCount: 3,
        vehiclesIn: 0,
        totalSales: 2430,
        openingFloat: 2000,
        byVehicleType: {'sedan': 2, 'suv': 1},
      ),
      activeCheckInCount: 0,
      actualCash: 2430,
    );

    expect(data.headerBranchLine, 'SM Sta Rosa / Valet Area');
    expect(data.cashierName, 'Kindred Inocencio');
    expect(data.checkoutCount, 3);
    expect(data.vehicleTypeStats.length, VehicleBodyType.values.length);
    expect(data.vehicleTypeStats.firstWhere((r) => r.label == 'Sedan/Crossover').count, 2);
    expect(data.vehicleTypeStats.firstWhere((r) => r.label == 'SUV').count, 1);
    expect(data.actualCashLabel, 'PHP 2,430.00');
    expect(data.activeCheckInCount, 0);
    expect(data.openedAtLabel, isNotEmpty);
    expect(data.closedAtLabel, isNotEmpty);
  });
}
