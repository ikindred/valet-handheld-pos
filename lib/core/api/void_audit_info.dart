/// Flat void audit fields on transaction/ticket API responses.
class VoidedByUser {
  const VoidedByUser({
    required this.id,
    required this.username,
    required this.name,
  });

  final String id;
  final String username;
  final String name;

  static VoidedByUser? tryFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    if (json.isEmpty) return null;
    final id = json['id']?.toString().trim() ?? '';
    final username = json['username']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ??
        [
          json['firstName']?.toString().trim(),
          json['lastName']?.toString().trim(),
        ].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
    if (id.isEmpty && username.isEmpty && name.isEmpty) return null;
    return VoidedByUser(
      id: id,
      username: username,
      name: name.isEmpty ? username : name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
      };
}

/// `void_reason`, `voided_by`, `voided_at` (snake_case) or camelCase on tickets void.
class VoidAuditInfo {
  const VoidAuditInfo({
    this.reason,
    this.voidedBy,
    this.voidedAt,
  });

  final String? reason;
  final VoidedByUser? voidedBy;
  final String? voidedAt;

  bool get isPopulated =>
      (reason != null && reason!.trim().isNotEmpty) ||
      voidedBy != null ||
      (voidedAt != null && voidedAt!.trim().isNotEmpty);

  static bool isVoidStatus(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    return s == 'void' || s == 'voided';
  }

  static VoidAuditInfo? tryFromJson(dynamic root) {
    if (root == null) return null;
    if (root is! Map) return null;
    final json = root is Map<String, dynamic>
        ? root
        : Map<String, dynamic>.from(root);

    final reason = _scalarString(
      json['void_reason'] ?? json['voidReason'],
    );
    final voidedBy = VoidedByUser.tryFromJson(
      json['voided_by'] ?? json['voidedBy'],
    );
    final voidedAt = _scalarString(json['voided_at'] ?? json['voidedAt']);

    if (reason == null && voidedBy == null && voidedAt == null) {
      return null;
    }
    return VoidAuditInfo(
      reason: reason,
      voidedBy: voidedBy,
      voidedAt: voidedAt,
    );
  }

  static String? _scalarString(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  Map<String, dynamic> toJson() => {
        if (reason != null) 'void_reason': reason,
        if (voidedBy != null) 'voided_by': voidedBy!.toJson(),
        if (voidedAt != null) 'voided_at': voidedAt,
      };
}
