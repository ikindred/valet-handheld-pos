import '../../data/local/db/app_database.dart';
import 'receipt_print_format.dart';

/// Minimal thermal receipt payload for express cashier checkout.
class ExpressCheckoutReceiptData {
  const ExpressCheckoutReceiptData({
    required this.ticketNumber,
    required this.plateNumber,
    required this.valetInLabel,
    required this.valetOutLabel,
    required this.totalPesosLabel,
    required this.branchName,
    required this.mallHours,
  });

  final String ticketNumber;
  final String plateNumber;
  final String valetInLabel;
  final String valetOutLabel;
  final String totalPesosLabel;
  final String branchName;
  final String mallHours;

  factory ExpressCheckoutReceiptData.fromTicket({
    required Ticket ticket,
    String? branchDisplayName,
    String mallHours = 'MONDAY – SUNDAY · 10:00AM – 9:00PM',
  }) {
    final branch = (branchDisplayName ?? '').trim();
    final amount = (ticket.fee ?? 0).toDouble();
    return ExpressCheckoutReceiptData(
      ticketNumber: ticket.id,
      plateNumber:
          ticket.plateNumber.trim().isEmpty ? '-' : ticket.plateNumber.trim(),
      valetInLabel: _driverLabel(ticket.driverIn),
      valetOutLabel: _driverLabel(ticket.driverOut),
      totalPesosLabel: ReceiptPrintFormat.pesoAmount(amount),
      branchName: branch,
      mallHours: mallHours.trim().isEmpty
          ? ReceiptTemplateCopy.defaultMallHours
          : mallHours.trim(),
    );
  }

  static String _driverLabel(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t.startsWith('{')) return '-';
    return t;
  }
}
