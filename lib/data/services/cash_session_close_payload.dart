/// POST `/api/v1/cash-sessions/close-cash` body (camelCase per mobile API).
/// Open session is resolved from the Bearer token — no shift id in the body.
Map<String, dynamic> buildCashSessionCloseBody({
  required double actualCash,
  required String timestampUtcIso,
  String? notes,
}) {
  return <String, dynamic>{
    'actualCash': actualCash,
    'timestamp': timestampUtcIso,
    'notes': notes?.trim() ?? '',
  };
}
