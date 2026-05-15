/// Human-readable branch / area labels from API JSON or legacy stored strings.
abstract final class SiteDisplayName {
  static final RegExp _nameFromMapToString = RegExp(
    r'NAME:\s*([^,}]+)',
    caseSensitive: false,
  );

  /// Resolves a display name from a JSON field (string or nested `{ id, name }` map).
  static String fromJsonValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final map = value is Map<String, dynamic>
          ? value
          : Map<String, dynamic>.from(value);
      for (final key in [
        'name',
        'branch_name',
        'branchName',
        'area_name',
        'areaName',
        'label',
        'title',
        'code',
      ]) {
        final raw = map[key];
        if (raw == null) continue;
        if (raw is Map) {
          final nested = fromJsonValue(raw);
          if (nested.isNotEmpty) return nested;
          continue;
        }
        final t = raw.toString().trim();
        if (t.isNotEmpty) return t;
      }
      return '';
    }
    return sanitizeStored(value.toString());
  }

  /// Cleans prefs / DB values; recovers `NAME:` from old `Map.toString()` blobs.
  static String sanitizeStored(String? raw) {
    if (raw == null) return '';
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('{')) {
      final match = _nameFromMapToString.firstMatch(t);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return t;
  }
}
