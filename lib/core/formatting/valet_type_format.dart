import 'dart:convert';

/// Normalizes and labels API `valet_type` values (`standard_valet`, `self_park`).
abstract final class ValetTypeFormat {
  static const selfPark = 'self_park';
  static const standardValet = 'standard_valet';

  static bool isSelfPark(String? raw) {
    final t = _normalizeKey(raw);
    return t == selfPark;
  }

  static String? rawFromTransaction(Map<String, dynamic> json) {
    return _readStr(json['valet_type'] ?? json['valetType']);
  }

  /// Reads `valet_type` from check-in metadata stored in [Tickets.driverOut].
  static String? fromDriverOutMeta(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || !t.startsWith('{')) return null;
    try {
      final body = jsonDecode(t);
      if (body is! Map) return null;
      final map = Map<String, dynamic>.from(body);
      return _readStr(map['valet_type'] ?? map['valetType']);
    } catch (_) {
      return null;
    }
  }

  static String label(String? raw) {
    final key = _normalizeKey(raw);
    if (key == null) return '—';
    return switch (key) {
      selfPark => 'Self-Park',
      standardValet => 'Standard Valet',
      _ => _pretty(key),
    };
  }

  static String? labelIfPresent(String? raw) {
    final key = _normalizeKey(raw);
    if (key == null) return null;
    return label(key);
  }

  /// Whether a display label (from API or local UI) denotes self-park.
  static bool isSelfParkDisplayLabel(String? label) {
    final normalized = label?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    return normalized == selfPark;
  }

  static String? _readStr(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static String? _normalizeKey(String? raw) {
    final s = raw?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    return s.isEmpty ? null : s;
  }

  static String _pretty(String raw) {
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((s) => s.isNotEmpty)
        .map(
          (w) =>
              '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }
}
