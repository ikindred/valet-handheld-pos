import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/esc_pos_text_sanitize.dart';
import 'package:valet_handheld_pos/core/printing/receipt_print_format.dart';

void main() {
  test('pesoAmount uses ASCII P prefix', () {
    expect(ReceiptPrintFormat.pesoAmount(100), 'P 100.00');
    expect(ReceiptPrintFormat.pesoAmount(1234.5), 'P 1,234.50');
  });

  test('sanitizeEscPosText maps peso sign to P', () {
    expect(sanitizeEscPosText('\u20B1100.00'), 'P100.00');
  });
}
