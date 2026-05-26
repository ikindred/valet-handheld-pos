import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/esc_pos_text_sanitize.dart';
import 'package:valet_handheld_pos/core/printing/receipt_print_format.dart';

void main() {
  test('pesoAmount uses ASCII PHP prefix', () {
    expect(ReceiptPrintFormat.pesoAmount(100), 'PHP 100.00');
    expect(ReceiptPrintFormat.pesoAmount(1234.5), 'PHP 1,234.50');
    expect(ReceiptPrintFormat.pesoAmount(0), 'PHP 0.00');
  });

  test('durationLabel formats minutes and hours', () {
    expect(ReceiptPrintFormat.durationLabel(3), '3m');
    expect(ReceiptPrintFormat.durationLabel(60), '1h');
    expect(ReceiptPrintFormat.durationLabel(65), '1h 5m');
  });

  test('sanitizeEscPosText maps peso sign to PHP', () {
    expect(sanitizeEscPosText('\u20B1100.00'), 'PHP 100.00');
  });

  test('printedAtLabel prefixes wall time', () {
    final label = ReceiptPrintFormat.printedAtLabel(
      DateTime(2026, 5, 26, 14, 30),
    );
    expect(label, startsWith('Printed '));
    expect(label, contains('2026'));
  });
}
