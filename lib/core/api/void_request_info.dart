/// Pending / resolved void request on a ticket (`void_request` from API).
class VoidRequestInfo {
  const VoidRequestInfo({
    required this.id,
    required this.status,
    this.reason,
    this.requestedAt = '',
  });

  final String id;
  final String status;
  final String? reason;
  final String requestedAt;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  static VoidRequestInfo? tryFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    if (json.isEmpty) return null;
    final id = json['id']?.toString().trim() ?? '';
    final status = json['status']?.toString().trim() ?? '';
    if (id.isEmpty && status.isEmpty) return null;
    return VoidRequestInfo(
      id: id,
      status: status.isEmpty ? 'pending' : status,
      reason: json['reason']?.toString(),
      requestedAt:
          json['requested_at']?.toString() ??
          json['requestedAt']?.toString() ??
          '',
    );
  }
}
