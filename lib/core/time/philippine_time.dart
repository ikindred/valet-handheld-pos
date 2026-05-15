/// Wall-clock helpers for Philippines (UTC+8, no DST).
class PhilippineTime {
  PhilippineTime._();

  static const Duration _utcOffset = Duration(hours: 8);

  /// Current date/time in Asia/Manila as a local [DateTime] (components are PH wall time).
  static DateTime now() => DateTime.now().toUtc().add(_utcOffset);
}
