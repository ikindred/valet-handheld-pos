import 'check_in_receipt_data.dart';

/// Thermal print entry point (Bluetooth ESC/POS).
abstract interface class ValetPrintService {
  Future<void> printCheckIn(CheckInReceiptData data);

  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel,
  });
}

/// No-op when printing is unavailable (desktop / tests).
class NoopValetPrintService implements ValetPrintService {
  @override
  Future<void> printCheckIn(CheckInReceiptData data) async {}

  @override
  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel = 'Test print',
  }) async {}
}
