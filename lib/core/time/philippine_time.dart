/// Wall-clock helpers for Philippines (UTC+8, no DST).
class PhilippineTime {
  PhilippineTime._();

  static const Duration _utcOffset = Duration(hours: 8);

  /// Current date/time in Asia/Manila as a local [DateTime] (components are PH wall time).
  /// Returns a non-UTC DateTime so wallClock() does not double-shift it.
  static DateTime now() => fromUtc(DateTime.now().toUtc());

  /// Current instant in UTC (for API `time_out` and receipt unix).
  static DateTime utcNow() => DateTime.now().toUtc();

  /// UTC ISO-8601 with `Z` for `POST …/check-out` `time_out`.
  static String apiIsoInstant([DateTime? utc]) =>
      (utc ?? utcNow()).toIso8601String();

  static int unixSecondsUtc([DateTime? utc]) =>
      (utc ?? utcNow()).millisecondsSinceEpoch ~/ 1000;

  /// ISO-8601 wall time in Manila (no `Z` / offset — stored as-is in Drift).
  static String iso8601Now() => formatIso(now());

  static String formatIso(DateTime ph) {
    final ms = ph.millisecond.toString().padLeft(3, '0');
    return '${ph.year.toString().padLeft(4, '0')}-'
        '${ph.month.toString().padLeft(2, '0')}-'
        '${ph.day.toString().padLeft(2, '0')}T'
        '${ph.hour.toString().padLeft(2, '0')}:'
        '${ph.minute.toString().padLeft(2, '0')}:'
        '${ph.second.toString().padLeft(2, '0')}.$ms';
  }

  /// Parses a stored Manila wall-time string without timezone conversion.
  static DateTime parseWallIso(String raw) {
    final p = DateTime.tryParse(raw.trim());
    if (p == null) return now();
    return DateTime(
      p.year,
      p.month,
      p.day,
      p.hour,
      p.minute,
      p.second,
      p.millisecond,
    );
  }

  /// `true` when [raw] is a UTC/offset instant from the API (`…Z`, `+08:00`, etc.).
  static bool isApiInstant(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    if (s.endsWith('Z')) return true;
    return RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s);
  }

  /// Converts a UTC instant to Manila wall-clock components for display.
  static DateTime fromUtc(DateTime utc) {
    final u = utc.toUtc();
    final shifted = DateTime.fromMillisecondsSinceEpoch(
      u.millisecondsSinceEpoch + _utcOffset.inMilliseconds,
      isUtc: true,
    );
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  /// API ISO (UTC `Z`) → Manila wall; Drift wall strings (no `Z`) → as-is.
  static DateTime fromApiIso(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return now();
    if (isApiInstant(s)) {
      final p = DateTime.tryParse(s);
      if (p == null) return now();
      return fromUtc(p);
    }
    return parseWallIso(s);
  }

  /// Epoch seconds (UTC) → Manila wall [DateTime] for labels.
  static DateTime fromUnixSeconds(int seconds) => fromUtc(
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
      );

  /// Normalize API / Drift check-in strings to Manila wall storage (no `Z`).
  static String normalizeCheckInStorage(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return iso8601Now();
    return formatIso(fromApiIso(s));
  }

  /// Elapsed time since [checkInRaw]; clamped at zero when clock is behind.
  static Duration elapsedSinceCheckIn(String checkInRaw, [DateTime? clock]) {
    final checkIn = fromApiIso(checkInRaw);
    final elapsed = (clock ?? now()).difference(checkIn);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
}
