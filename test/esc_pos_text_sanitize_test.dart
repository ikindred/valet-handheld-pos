import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/esc_pos_text_sanitize.dart';

void main() {
  test('replaces em dash and middle dot', () {
    expect(sanitizeEscPosText('Plate: —'), 'Plate: -');
    expect(sanitizeEscPosText('A · B'), 'A   B');
  });
}
