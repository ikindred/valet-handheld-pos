import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/check_in_receipt_data.dart';
import 'package:valet_handheld_pos/core/printing/close_cash_receipt_data.dart';
import 'package:valet_handheld_pos/core/printing/escpos_receipt_builder.dart';
import 'package:valet_handheld_pos/features/cash/models/close_cash_shift_stats.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildCheckInReceipt produces ESC/POS bytes', () async {
    final profile = await CapabilityProfile.load();
    final builder = EscPosReceiptBuilder(profile);
    final ticket = Ticket(
      id: 'TKT-0001',
      shiftId: 'shift-1',
      userId: 'user-1',
      branchId: 'branch-a',
      plateNumber: 'ABC 1234',
      vehicleBrand: 'Toyota Vios',
      vehicleColor: 'White',
      vehicleType: 'Sedan',
      cellphoneNumber: '09171234567',
      damageMarkers: '[{"type":"dent","zone":"Front hood"}]',
      personalBelongings: '["iPad"]',
      checkInAt: DateTime(2026, 3, 24, 10, 18).toIso8601String(),
      status: 'active',
      syncStatus: 'pending',
      createdAt: DateTime.now().toIso8601String(),
      pendingVoidRequest: false,
    );

    final bytes = builder.buildCheckInReceipt(
      CheckInReceiptData(
        ticket: ticket,
        branchName: 'Branch A',
        customerName: 'Juan dela Cruz',
        hasSignature: true,
      ),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('buildCloseCashReceipt produces ESC/POS bytes', () async {
    final profile = await CapabilityProfile.load();
    final builder = EscPosReceiptBuilder(profile);
    final data = CloseCashReceiptData.fromClose(
      branch: 'SM Sta Rosa',
      area: 'Valet Area',
      cashierName: 'Cashier One',
      openedAtIso: '2026-06-06T08:00:00.000Z',
      closedAtIso: '2026-06-06T17:00:00.000Z',
      stats: CloseCashShiftStats.fromAggregates(
        checkInCount: 2,
        checkoutCount: 2,
        vehiclesIn: 0,
        totalSales: 1500,
        openingFloat: 500,
        byVehicleType: {'sedan': 2},
      ),
      activeCheckInCount: 0,
      actualCash: 1500,
    );

    final bytes = builder.buildCloseCashReceipt(data);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
