import 'package:flutter/material.dart' show DateTimeRange;

/// Maps UI date-range selection to `GET /api/v1/reports/transactions` query params.
///
/// The UI stores a half-open Manila range `[start, end)` where [DateTimeRange.end]
/// is midnight on the day **after** the last selected calendar day.
///
/// Swagger documents `date_from` / `date_to` as `YYYY-MM-DD` with both ends
/// **inclusive** (start and end of the selected range).
abstract final class ReportsDateQuery {
  static String isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Inclusive `date_from` and `date_to` for the API.
  static ({String dateFrom, String dateTo}) apiBounds(DateTimeRange range) {
    final lastDay = range.end.subtract(const Duration(days: 1));
    return (dateFrom: isoDate(range.start), dateTo: isoDate(lastDay));
  }

  /// Whether [rowTimeIn] falls in the UI half-open `[range.start, range.end)`.
  static bool containsCheckIn(DateTime rowTimeIn, DateTimeRange range) {
    return !rowTimeIn.isBefore(range.start) && rowTimeIn.isBefore(range.end);
  }
}
