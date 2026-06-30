/// `GET /api/v1/reports/today` — shift KPIs + transaction rows for Today tab.
class ReportsTodayResponse {
  const ReportsTodayResponse({
    this.shiftId,
    this.openedAt,
    this.totalCollected,
    this.totalTransactions,
    this.currentlyParked = const [],
    this.transactionRows = const [],
    this.alerts = const [],
  });

  final String? shiftId;
  final String? openedAt;
  final double? totalCollected;
  final int? totalTransactions;

  /// Active/parked rows (standard cashier).
  final List<Map<String, dynamic>> currentlyParked;

  /// All transaction-shaped rows from any list field on the payload.
  final List<Map<String, dynamic>> transactionRows;
  final List<Map<String, dynamic>> alerts;

  factory ReportsTodayResponse.fromJson(dynamic data) {
    if (data is! Map) return const ReportsTodayResponse();
    final json = Map<String, dynamic>.from(data);

    final parked = _listOfMaps(json['currently_parked'] ?? json['currentlyParked']);
    final transactionRows = _collectTransactionRows(json);
    final alerts = _listOfMaps(json['alerts']);

    return ReportsTodayResponse(
      shiftId: _scalar(json['shift_id'] ?? json['shiftId']),
      openedAt: _scalar(json['opened_at'] ?? json['openedAt']),
      totalCollected: _double(json['total_collected'] ?? json['totalCollected']),
      totalTransactions:
          _int(json['total_transactions'] ?? json['totalTransactions']),
      currentlyParked: parked,
      transactionRows: transactionRows,
      alerts: alerts,
    );
  }

  static List<Map<String, dynamic>> _collectTransactionRows(
    Map<String, dynamic> json,
  ) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addFromList(dynamic raw) {
      for (final map in _listOfMaps(raw)) {
        final id = map['id']?.toString().trim() ?? '';
        final ticket =
            map['ticket_number']?.toString().trim() ??
            map['ticketNumber']?.toString().trim() ??
            '';
        final key = id.isNotEmpty ? id : ticket;
        if (key.isEmpty) {
          out.add(map);
          continue;
        }
        if (seen.contains(key)) continue;
        seen.add(key);
        out.add(map);
      }
    }

    for (final key in const [
      'currently_parked',
      'currentlyParked',
      'transactions',
      'shift_transactions',
      'shiftTransactions',
      'recent_transactions',
      'recentTransactions',
      'completed_transactions',
      'completedTransactions',
    ]) {
      addFromList(json[key]);
    }

    return out;
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  static String? _scalar(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _double(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? _int(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
