import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/session/cashier_shift_schedule.dart';

void main() {
  test('hasShiftOnDate matches API dayOfWeek Mon–Fri', () {
    final schedule = CashierShiftSchedule(
      CashierShiftSchedule.parseList([
        {'dayOfWeek': 1, 'startTime': '08:00', 'endTime': '17:00'},
        {'dayOfWeek': 5, 'startTime': '08:00', 'endTime': '17:00'},
      ]),
    );
    // 2026-05-15 is Friday
    expect(
      schedule.hasShiftOnDate(DateTime(2026, 5, 15)),
      isTrue,
    );
    // 2026-05-16 is Saturday
    expect(
      schedule.hasShiftOnDate(DateTime(2026, 5, 16)),
      isFalse,
    );
  });

  test('todayShiftLabel formats day and time range', () {
    final schedule = CashierShiftSchedule(
      CashierShiftSchedule.parseList([
        {'dayOfWeek': 6, 'startTime': '08:00', 'endTime': '17:00'},
      ]),
    );
    expect(
      schedule.todayShiftLabel(DateTime(2026, 5, 16)),
      'Saturday, 08:00 - 17:00',
    );
    expect(
      schedule.todayShiftLabel(DateTime(2026, 5, 17)),
      'No shift today',
    );
  });

  test('empty schedule means no shift today', () {
    expect(CashierShiftSchedule.fromJsonString(''), isNull);
    expect(
      const CashierShiftSchedule([]).todayShiftLabel(DateTime(2026, 5, 15)),
      'No shift today',
    );
  });
}
