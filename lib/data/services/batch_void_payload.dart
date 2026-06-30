/// Builds one `voids[]` item for `POST /transactions/void`.
Map<String, dynamic> voidApiItem({
  required String id,
  String? voidReason,
}) {
  final trimmedId = id.trim();
  if (trimmedId.isEmpty) {
    throw StateError('Void item id is empty.');
  }
  final item = <String, dynamic>{'id': trimmedId};
  final reason = voidReason?.trim();
  if (reason != null && reason.isNotEmpty) {
    item['void_reason'] = reason;
  }
  return item;
}
