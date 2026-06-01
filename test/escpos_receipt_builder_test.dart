import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/check_in_receipt_data.dart';
import 'package:valet_handheld_pos/core/printing/escpos_receipt_builder.dart';
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
}
