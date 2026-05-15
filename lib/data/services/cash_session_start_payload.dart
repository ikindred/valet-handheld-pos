/// POST `/api/v1/cash-sessions/start` body (camelCase per mobile API).
Map<String, dynamic> buildCashSessionStartBody({
  required double openingBalance,
  required String timestampUtcIso,
  String? notes,
}) {
  return <String, dynamic>{
    'openingBalance': openingBalance,
    'timestamp': timestampUtcIso,
    'notes': notes?.trim() ?? '',
  };
}

/// Normalizes stored [openedAt] (or now) to UTC ISO-8601 for `timestamp`.
String cashSessionStartTimestamp({String? openedAtIso}) {
  if (openedAtIso != null && openedAtIso.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(openedAtIso.trim());
    if (parsed != null) return parsed.toUtc().toIso8601String();
  }
  return DateTime.now().toUtc().toIso8601String();
}
