import 'dart:convert';

/// One row from login `user.shiftSchedule` (`dayOfWeek` 1 = Monday … 7 = Sunday).
class ShiftScheduleEntry {
  const ShiftScheduleEntry({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftScheduleEntry.fromJson(Map<String, dynamic> json) {
    final dow = json['dayOfWeek'] ?? json['day_of_week'];
    return ShiftScheduleEntry(
      dayOfWeek: dow is int ? dow : int.tryParse('$dow') ?? 0,
      startTime: (json['startTime'] ?? json['start_time'] ?? '').toString().trim(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      };

  final int dayOfWeek;
  final String startTime;
  final String endTime;
}

/// Cashier weekly shift windows from login (stored on [OfflineAccounts]).
class CashierShiftSchedule {
  const CashierShiftSchedule(this.entries);

  final List<ShiftScheduleEntry> entries;

  static const empty = CashierShiftSchedule([]);

  static List<ShiftScheduleEntry> parseList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => ShiftScheduleEntry.fromJson(Map<String, dynamic>.from(m)))
        .where((e) => e.dayOfWeek >= 1 && e.dayOfWeek <= 7)
        .toList();
  }

  static CashierShiftSchedule? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final list = parseList(decoded);
        return list.isEmpty ? null : CashierShiftSchedule(list);
      }
    } catch (_) {}
    return null;
  }

  static String encodeToJsonString(List<ShiftScheduleEntry> entries) {
    if (entries.isEmpty) return '';
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// API `dayOfWeek`: 1 = Monday … 7 = Sunday (same as [DateTime.weekday]).
  static String dayNameFor(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return weekdayNames[dayOfWeek - 1];
    }
    return '';
  }

  /// Whether [date] has a row in the saved weekly schedule.
  bool hasShiftOnDate(DateTime date) {
    if (entries.isEmpty) return false;
    return entryForDate(date) != null;
  }

  ShiftScheduleEntry? entryForDate(DateTime date) {
    final dow = date.weekday;
    for (final e in entries) {
      if (e.dayOfWeek == dow) return e;
    }
    return null;
  }

  /// Open Cash: `Saturday, 08:00 - 17:00` or `No shift today`.
  String todayShiftLabel(DateTime date) {
    if (entries.isEmpty) return 'No shift today';
    final entry = entryForDate(date);
    if (entry == null) return 'No shift today';
    final day = dayNameFor(entry.dayOfWeek);
    final start = entry.startTime;
    final end = entry.endTime;
    if (start.isEmpty && end.isEmpty) return day;
    if (start.isEmpty) return '$day, $end';
    if (end.isEmpty) return '$day, $start';
    return '$day, $start - $end';
  }
}
