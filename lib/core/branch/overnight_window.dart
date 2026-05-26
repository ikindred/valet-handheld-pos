import 'package:flutter/material.dart';

/// Overnight billing window (`HH:mm`, 24h military time).
class OvernightWindow {
  const OvernightWindow({
    required this.startTime,
    required this.endTime,
  });

  /// Default end when the API omits `overnight_end` (legacy cutoff-only payloads).
  static const TimeOfDay defaultEndTime = TimeOfDay(hour: 6, minute: 0);

  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Parses `"14:05"` → [TimeOfDay]; returns null if invalid or empty.
  static TimeOfDay? parseHhMm(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// JSON keys for overnight window start/end (`HH:mm`, 24h military time).
  static const overnightStartKeys = [
    'overnightStartTime',
    'overnight_start_time',
    'overnight_start',
    'overnightStart',
    'overnight_cutoff',
    'overnightCutoff',
  ];

  static const overnightEndKeys = [
    'overnightEndTime',
    'overnight_end_time',
    'overnight_end',
    'overnightEnd',
  ];

  /// Reads the first non-empty overnight start/end from [json].
  static ({String? start, String? end}) parseTimesFromJson(
    Map<String, dynamic> json,
  ) =>
      (
        start: _pickTimeField(json, overnightStartKeys),
        end: _pickTimeField(json, overnightEndKeys),
      );

  static String? _pickTimeField(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Builds a window from API strings; null when [startRaw] is missing/invalid.
  static OvernightWindow? tryFromHhMm(String? startRaw, String? endRaw) {
    final start = parseHhMm(startRaw);
    if (start == null) return null;
    final end = parseHhMm(endRaw) ?? defaultEndTime;
    return OvernightWindow(startTime: start, endTime: end);
  }

  /// `true` when stay `[timeIn, timeOut]` overlaps this window on any calendar day.
  ///
  /// Example: check-in 9pm, check-out 6am with window 01:30–05:30 → overnight applies
  /// because the stay crosses the morning overnight period.
  bool stayOverlaps(DateTime timeIn, DateTime timeOut) {
    if (!timeOut.isAfter(timeIn)) return false;

    var day = DateTime(timeIn.year, timeIn.month, timeIn.day);
    final lastDay = DateTime(timeOut.year, timeOut.month, timeOut.day);

    while (!day.isAfter(lastDay)) {
      final windowStart = _onDay(day, startTime);
      final windowEnd = _windowEndInstant(day, startTime, endTime);
      if (timeIn.isBefore(windowEnd) && timeOut.isAfter(windowStart)) {
        return true;
      }
      day = day.add(const Duration(days: 1));
    }
    return false;
  }

  DateTime _onDay(DateTime day, TimeOfDay t) =>
      DateTime(day.year, day.month, day.day, t.hour, t.minute);

  DateTime _windowEndInstant(DateTime day, TimeOfDay start, TimeOfDay end) {
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    if (endMins > startMins) {
      return _onDay(day, end);
    }
    final next = day.add(const Duration(days: 1));
    return _onDay(next, end);
  }
}
