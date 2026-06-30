import '../../core/time/philippine_time.dart';

/// Normalizes `GET /reports/today` list rows for Drift upsert.
abstract final class ReportsTodayRowMapper {
  /// Converts a `currently_parked[]` item into transaction-shaped JSON.
  static Map<String, dynamic> toServerCacheJson(
    Map<String, dynamic> json, {
    bool markExpress = false,
  }) {
    final out = Map<String, dynamic>.from(json);

    final plate = _scalar(json['plate_number'] ?? json['plateNumber']) ?? '';
    final vehicleRaw = json['vehicle'];
    if (vehicleRaw is String && vehicleRaw.trim().isNotEmpty) {
      out['vehicle'] = <String, dynamic>{
        'brand': vehicleRaw.trim(),
        if (plate.isNotEmpty) 'plate_number': plate,
      };
    } else if (plate.isNotEmpty) {
      final vehicle = out['vehicle'];
      if (vehicle is Map) {
        final vm = Map<String, dynamic>.from(vehicle);
        vm['plate_number'] = plate;
        out['vehicle'] = vm;
      } else {
        out['vehicle'] = <String, dynamic>{'plate_number': plate};
      }
    }

    final color = _scalar(json['color']);
    if (color != null) {
      final vehicle = out['vehicle'];
      if (vehicle is Map) {
        final vm = Map<String, dynamic>.from(vehicle);
        vm['color'] = color;
        out['vehicle'] = vm;
      }
    }

    final slot = _scalar(json['slot']);
    if (slot != null) {
      out['parking'] = <String, dynamic>{'slot': slot};
    }

    final timeIn = _resolveClockTime(json['time_in'] ?? json['timeIn']);
    if (timeIn != null) out['time_in'] = timeIn;

    final timeOut = _resolveClockTime(json['time_out'] ?? json['timeOut']);
    if (timeOut != null) out['time_out'] = timeOut;

    if (markExpress) {
      out['is_express'] = true;
      out['is_express_cashier'] = true;
    }

    return out;
  }

  static String? _scalar(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Expands `08:00` / `10:30` to today's Manila wall ISO.
  static String? _resolveClockTime(dynamic raw) {
    final text = _scalar(raw);
    if (text == null) return null;
    if (PhilippineTime.isApiInstant(text)) {
      return PhilippineTime.normalizeCheckInStorage(text);
    }
    final parts = text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final min = int.tryParse(parts[1]) ?? 0;
      final ph = PhilippineTime.now();
      return PhilippineTime.formatIso(
        DateTime(ph.year, ph.month, ph.day, h, min),
      );
    }
    return PhilippineTime.normalizeCheckInStorage(text);
  }
}
