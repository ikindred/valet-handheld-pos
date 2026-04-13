import 'package:flutter/material.dart';

/// Overnight billing window from cached `branch_config` (`HH:mm`, 24h).
class OvernightWindow {
  const OvernightWindow({
    required this.startTime,
    required this.endTime,
  });

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
}
