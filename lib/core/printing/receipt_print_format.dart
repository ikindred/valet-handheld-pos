import 'package:intl/intl.dart';

import '../time/philippine_time.dart';

/// ASCII-safe formatting for thermal printers (no ₱ — many ESC/POS fonts lack it).
abstract final class ReceiptPrintFormat {
  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en_US');

  /// e.g. `PHP 100.00` (renders reliably on Bluetooth ESC/POS).
  static String pesoAmount(double amount) => 'PHP ${_amount.format(amount)}';

  /// Stay length for receipts, e.g. `3m` or `1h 5m`.
  static String durationLabel(int durationMinutes) {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h <= 0) return '${m}m';
    if (m <= 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Receipt timestamps without middle-dot (sanitizer maps · to space).
  static String dateTimeLabel(DateTime local) =>
      DateFormat('MMM d, yyyy h:mm a').format(local);

  static String printedAtLabel([DateTime? when]) {
    final ph = when ?? PhilippineTime.now();
    return 'Printed ${dateTimeLabel(ph)}';
  }
}

/// Shared copy for check-in / check-out thermal templates.
abstract final class ReceiptTemplateCopy {
  static const defaultMallHours = 'MONDAY - SUNDAY  10:00AM - 9:00PM';
  static const brandName = 'VALET MASTER';
  static const thankYouLine = 'THANK YOU FOR USING VALET MASTER';
  static const orDisclaimerNote =
      'NOTE: This is not an Official Receipt (OR).';
  static const orDisclaimer = 'This is not an Official Receipt (OR).';
  static const scanQrHint = 'Scan at check-out';
}
