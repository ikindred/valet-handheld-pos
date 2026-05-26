import 'package:intl/intl.dart';

/// ASCII-safe formatting for thermal printers (no ₱ — many ESC/POS fonts lack it).
abstract final class ReceiptPrintFormat {
  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en_US');

  /// e.g. `P 100.00` (renders reliably on Bluetooth ESC/POS).
  static String pesoAmount(double amount) => 'P ${_amount.format(amount)}';

  /// Receipt timestamps without middle-dot (sanitizer maps · to space).
  static String dateTimeLabel(DateTime local) =>
      DateFormat('MMM d, yyyy - h:mm a').format(local);
}
