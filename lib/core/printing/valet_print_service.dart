import 'check_in_receipt_data.dart';
import 'checkout_receipt_data.dart';
import 'close_cash_receipt_data.dart';

/// Thermal print entry point (Bluetooth ESC/POS).
abstract interface class ValetPrintService {
  Future<void> printCheckIn(CheckInReceiptData data, {required int part});

  Future<void> printCheckOut(CheckoutReceiptData data);

  Future<void> printCloseCash(CloseCashReceiptData data);

  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel,
  });
}

/// No-op when printing is unavailable (desktop / tests).
class NoopValetPrintService implements ValetPrintService {
  @override
  Future<void> printCheckIn(CheckInReceiptData data, {required int part}) async {}

  @override
  Future<void> printCheckOut(CheckoutReceiptData data) async {}

  @override
  Future<void> printCloseCash(CloseCashReceiptData data) async {}

  @override
  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel = 'Test print',
  }) async {}
}
