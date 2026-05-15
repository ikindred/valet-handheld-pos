import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/time/philippine_time.dart';

void main() {
  test('PhilippineTime.now is UTC+8 wall clock', () {
    final utc = DateTime.now().toUtc();
    final ph = PhilippineTime.now();
    final expected = utc.add(const Duration(hours: 8));
    expect(ph.year, expected.year);
    expect(ph.month, expected.month);
    expect(ph.day, expected.day);
    expect(ph.hour, expected.hour);
    expect(ph.minute, expected.minute);
  });
}
