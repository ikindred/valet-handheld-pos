import 'philippine_time.dart';

/// Resolves Manila wall-time check-in from server transaction fields.
///
/// Backend may send [start_date] (unix seconds, PH parking-day anchor at midnight)
/// before [checkout_timestamp] exists. When checkout lands on the next calendar
/// day, [time_in] can incorrectly share checkout's date — this restores the
/// parking day from [start_date] while keeping the clock time from [time_in].
abstract final class CheckInTimeResolution {
  static const _timeInKeys = [
    'time_in',
    'check_in_time',
    'checkInTime',
    'check_in_at',
    'checkInAt',
    'created_at',
    'createdAt',
  ];

  static const _startDateKeys = [
    'start_date',
    'startDate',
    'valet_date',
    'valetDate',
  ];

  static const _checkoutKeys = [
    'checkout_timestamp',
    'checkoutTimestamp',
    'time_out',
    'timeOut',
    'check_out_at',
    'checkOutAt',
  ];

  /// Unix seconds for PH midnight on the check-in calendar day (outbound sync).
  static int parkingDateUnixSeconds(DateTime phWall) =>
      PhilippineTime.parkingDateUnixSeconds(phWall);

  /// Parking-day anchor from a stored check-in wall ISO string.
  static int? parkingDateUnixFromCheckInRaw(String? checkInRaw) =>
      PhilippineTime.parkingDateUnixFromCheckInRaw(checkInRaw);

  static String resolveWallIsoFromTransaction(
    Map<String, dynamic> json, {
    String? localFallback,
  }) {
    final startDateUnix = _pickUnix(json, _startDateKeys);
    final checkoutUnix = _pickUnix(json, _checkoutKeys);
    final timeInRaw = _pickString(json, _timeInKeys);

    if (timeInRaw != null) {
      final ph = PhilippineTime.fromApiIso(timeInRaw);
      if (startDateUnix != null && checkoutUnix != null) {
        final startDay = _dateOnly(PhilippineTime.fromUnixSeconds(startDateUnix));
        final checkoutDay =
            _dateOnly(PhilippineTime.fromUnixSeconds(checkoutUnix));
        final timeInDay = _dateOnly(ph);
        if (startDay != checkoutDay && timeInDay == checkoutDay) {
          return PhilippineTime.formatIso(
            DateTime(
              startDay.year,
              startDay.month,
              startDay.day,
              ph.hour,
              ph.minute,
              ph.second,
              ph.millisecond,
            ),
          );
        }
      }
      return PhilippineTime.normalizeCheckInStorage(timeInRaw);
    }

    if (startDateUnix != null) {
      final startPh = PhilippineTime.fromUnixSeconds(startDateUnix);
      final fallback = localFallback?.trim() ?? '';
      if (fallback.isNotEmpty) {
        final local = PhilippineTime.fromApiIso(fallback);
        return PhilippineTime.formatIso(
          DateTime(
            startPh.year,
            startPh.month,
            startPh.day,
            local.hour,
            local.minute,
            local.second,
            local.millisecond,
          ),
        );
      }
      return PhilippineTime.formatIso(startPh);
    }

    if (localFallback != null && localFallback.trim().isNotEmpty) {
      return PhilippineTime.normalizeCheckInStorage(localFallback);
    }
    return PhilippineTime.iso8601Now();
  }

  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;
      if (raw is Map && raw.isEmpty) continue;
      final s = raw.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static int? _pickUnix(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw == null) continue;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      final parsed = int.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
