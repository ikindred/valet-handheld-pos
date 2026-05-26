import '../logging/valet_log.dart';
import 'bluetooth_pos_printer.dart';
import 'check_in_receipt_data.dart';
import 'checkout_receipt_data.dart';
import 'escpos_receipt_builder.dart';
import 'receipt_brand_logo.dart';
import 'printer_config.dart';
import 'receipt_raster_builder.dart';
import 'valet_print_service.dart';

class BluetoothValetPrintService implements ValetPrintService {
  BluetoothValetPrintService(this._printer);

  final BluetoothPosPrinter _printer;

  Future<List<int>> _buildCheckInPartBytes(
    CheckInReceiptData data, {
    required int part,
  }) async {
    final profile = await _printer.loadProfile();
    final width = await _printer.paperWidth;
    final logo = await ReceiptBrandLogo.loadForReceipt(
      maxWidthPx: width == PrinterPaperWidth.mm58 ? 160 : 220,
    );
    if (width == PrinterPaperWidth.mm58) {
      return ReceiptRasterBuilder(paperSize: width.paperSize)
          .buildCheckInPartEscPosBytes(data, profile, part, logo: logo);
    }
    return EscPosReceiptBuilder(profile, paperSize: width.paperSize)
        .buildCheckInPartReceipt(data, part: part, logo: logo);
  }

  Future<List<int>> _buildTestBytes({
    required String branchName,
    required String staffLabel,
  }) async {
    final profile = await _printer.loadProfile();
    final width = await _printer.paperWidth;
    final logo = await ReceiptBrandLogo.loadForReceipt(
      maxWidthPx: width == PrinterPaperWidth.mm58 ? 160 : 220,
    );
    if (width == PrinterPaperWidth.mm58) {
      return ReceiptRasterBuilder(paperSize: width.paperSize)
          .buildTestEscPosBytes(
            profile: profile,
            branchName: branchName,
            staffLabel: staffLabel,
            logo: logo,
          );
    }
    return EscPosReceiptBuilder(profile, paperSize: width.paperSize)
        .buildTestReceipt(
          branchName: branchName,
          staffLabel: staffLabel,
          logo: logo,
        );
  }

  Future<List<int>> _buildCheckoutBytes(CheckoutReceiptData data) async {
    final profile = await _printer.loadProfile();
    final width = await _printer.paperWidth;
    final logo = await ReceiptBrandLogo.loadForReceipt(
      maxWidthPx: width == PrinterPaperWidth.mm58 ? 160 : 220,
    );
    if (width == PrinterPaperWidth.mm58) {
      return ReceiptRasterBuilder(paperSize: width.paperSize)
          .buildCheckoutEscPosBytes(data, profile, logo: logo);
    }
    return EscPosReceiptBuilder(profile, paperSize: width.paperSize)
        .buildCheckoutReceipt(data, logo: logo);
  }

  @override
  Future<void> printCheckOut(CheckoutReceiptData data) async {
    final bytes = await _buildCheckoutBytes(data);
    await _printer.printBytes(bytes);
    ValetLog.info(
      'BluetoothValetPrintService',
      'printed checkout ${data.ticketNumber}',
    );
  }

  @override
  Future<void> printCheckIn(CheckInReceiptData data, {required int part}) async {
    final bytes = await _buildCheckInPartBytes(data, part: part);
    await _printer.printBytes(bytes);
    ValetLog.info(
      'BluetoothValetPrintService',
      'printed check-in ${data.ticket.id} part $part',
    );
  }

  @override
  Future<void> printTestReceipt({
    required String branchName,
    String staffLabel = 'Test print',
  }) async {
    final bytes = await _buildTestBytes(
      branchName: branchName,
      staffLabel: staffLabel,
    );
    await _printer.printBytes(bytes);
  }
}
