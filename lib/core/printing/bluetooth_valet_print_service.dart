import '../logging/valet_log.dart';
import 'bluetooth_pos_printer.dart';
import 'check_in_receipt_data.dart';
import 'escpos_receipt_builder.dart';
import 'printer_config.dart';
import 'valet_print_service.dart';

class BluetoothValetPrintService implements ValetPrintService {
  BluetoothValetPrintService(this._printer);

  final BluetoothPosPrinter _printer;

  Future<EscPosReceiptBuilder> _builder() async {
    final profile = await _printer.loadProfile();
    final width = await _printer.paperWidth;
    return EscPosReceiptBuilder(profile, paperSize: width.paperSize);
  }

  @override
  Future<void> printCheckIn(CheckInReceiptData data) async {
    final bytes = (await _builder()).buildCheckInReceipt(data);
    await _printer.printBytes(bytes);
    ValetLog.info(
      'BluetoothValetPrintService',
      'printed check-in ${data.ticket.id}',
    );
  }

  @override
  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel = 'Test print',
  }) async {
    final bytes = (await _builder()).buildTestReceipt(
      branchName: branchName,
      staffLabel: staffLabel,
    );
    await _printer.printBytes(bytes);
  }
}
