import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_date_query.dart';

void main() {
  test('apiBounds sends inclusive date_from and date_to for single day', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 30),
      end: DateTime(2026, 5, 31),
    );
    final bounds = ReportsDateQuery.apiBounds(range);
    expect(bounds.dateFrom, '2026-05-30');
    expect(bounds.dateTo, '2026-05-30');
  });

  test('apiBounds for multi-day range uses last selected day as date_to', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 24),
      end: DateTime(2026, 5, 31),
    );
    final bounds = ReportsDateQuery.apiBounds(range);
    expect(bounds.dateFrom, '2026-05-24');
    expect(bounds.dateTo, '2026-05-30');
  });

  test('containsCheckIn matches half-open local range', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 30),
      end: DateTime(2026, 5, 31),
    );
    expect(
      ReportsDateQuery.containsCheckIn(
        DateTime(2026, 5, 30, 8, 33),
        range,
      ),
      isTrue,
    );
    expect(
      ReportsDateQuery.containsCheckIn(
        DateTime(2026, 5, 31, 0, 0),
        range,
      ),
      isFalse,
    );
  });
}
