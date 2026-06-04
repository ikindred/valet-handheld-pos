import 'package:intl/intl.dart';

import '../branch/overnight_window.dart';
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

  /// `01:30` → `1:30 AM` for thermal receipt copy; empty when [hhMm24] is invalid.
  static String overnightCutoffLabel(String hhMm24) {
    final tod = OvernightWindow.parseHhMm(hhMm24.trim());
    if (tod == null) return '';
    final dt = DateTime(2000, 1, 1, tod.hour, tod.minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Human-readable overnight window for receipts and rate dialogs.
  ///
  /// Examples: `after 1:30 AM`, `1:30 AM – 6:00 AM`.
  static String overnightWindowLabel({
    required String startHhMm24,
    String endHhMm24 = '',
  }) {
    final start = overnightCutoffLabel(startHhMm24);
    if (start.isEmpty) return '';
    final end = overnightCutoffLabel(endHhMm24);
    if (end.isEmpty) return 'after $start';
    return '$start – $end';
  }

  /// Rates modal row, e.g. `Overnight Fee (after 1:30 AM)`.
  static String overnightFeeRowLabel({
    required String startHhMm24,
    String endHhMm24 = '',
  }) {
    final window = overnightWindowLabel(
      startHhMm24: startHhMm24,
      endHhMm24: endHhMm24,
    );
    if (window.isEmpty) return 'Overnight Fee';
    return 'Overnight Fee ($window)';
  }

  /// Builds a single mall-hours line from cached `branch_config` keys.
  static String? mallHoursFromBranchConfig(Map<String, String> config) {
    final open = config['mall_open_time']?.trim() ?? '';
    final close = config['mall_close_time']?.trim() ?? '';
    if (open.isEmpty || close.isEmpty) return null;
    return 'MONDAY - SUNDAY  ${overnightCutoffLabel(open)} - '
        '${overnightCutoffLabel(close)}';
  }
}

/// Shared copy for check-in / check-out thermal templates.
abstract final class ReceiptTemplateCopy {
  static const defaultMallHours = 'MONDAY - SUNDAY  10:00AM - 9:00PM';
  static const brandName = 'VALET MASTER';
  static const thankYouLine = 'THANK YOU FOR USING VALET MASTER';
  /// Customer copy (part 2) — shown after the rule line, before the QR code.
  static const claimStubHeading = 'CLAIM STUB';
  static const scanQrHint = 'Scan at check-out';
}
