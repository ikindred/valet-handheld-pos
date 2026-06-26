/// Per-item outcome from `POST /transactions/check-in` batch JSON API.
class BatchCheckInResultItem {
  const BatchCheckInResultItem({
    required this.index,
    required this.status,
    required this.ticketNumber,
    required this.plateNumber,
    required this.vrNo,
    this.serverTransactionId,
    this.transaction,
    this.error,
  });

  final int index;
  final String status;
  final String ticketNumber;
  final String plateNumber;
  final String vrNo;
  final String? serverTransactionId;
  final Map<String, dynamic>? transaction;
  final BatchCheckInResultError? error;

  bool get isSuccess => status.toLowerCase() == 'success';

  bool get isFailed => !isSuccess;

  factory BatchCheckInResultItem.fromJson(Map<String, dynamic> json) {
    final transaction = _unwrapResultTransaction(json);

    final errRaw = json['error'];
    BatchCheckInResultError? error;
    if (errRaw is Map<String, dynamic>) {
      error = BatchCheckInResultError.fromJson(errRaw);
    } else if (errRaw is Map) {
      error = BatchCheckInResultError.fromJson(Map<String, dynamic>.from(errRaw));
    }

    final ticketNumber = json['ticket_number']?.toString() ?? '';
    var plateNumber = json['plate_number']?.toString() ?? '';
    var vrNo = json['vr_no']?.toString() ?? '';
    if (transaction != null) {
      if (vrNo.isEmpty) {
        vrNo = transaction['vr_no']?.toString() ?? '';
      }
      if (plateNumber.isEmpty) {
        final vehicle = transaction['vehicle'];
        if (vehicle is Map) {
          plateNumber = vehicle['plate_number']?.toString() ?? '';
        }
      }
    }

    final topId = json['server_transaction_id']?.toString().trim() ??
        json['id']?.toString().trim();
    final txnId = transaction?['id']?.toString().trim();
    final serverId = _pickServerTransactionId(
      topId: topId,
      txnId: txnId,
      ticketNumber: ticketNumber,
    );

    return BatchCheckInResultItem(
      index: json['index'] is num ? (json['index'] as num).toInt() : 0,
      status: json['status']?.toString() ?? 'failed',
      ticketNumber: ticketNumber,
      plateNumber: plateNumber,
      vrNo: vrNo,
      serverTransactionId: serverId,
      transaction: transaction,
      error: error,
    );
  }

  static Map<String, dynamic>? _unwrapResultTransaction(
    Map<String, dynamic> json,
  ) {
    final txn = json['transaction'];
    if (txn is Map<String, dynamic>) return txn;
    if (txn is Map) return Map<String, dynamic>.from(txn);

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final inner = data['transaction'];
      if (inner is Map<String, dynamic>) return inner;
      if (inner is Map) return Map<String, dynamic>.from(inner);
      if (data['id'] != null) return data;
    } else if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final inner = dataMap['transaction'];
      if (inner is Map<String, dynamic>) return inner;
      if (inner is Map) return Map<String, dynamic>.from(inner);
      if (dataMap['id'] != null) return dataMap;
    }
    return null;
  }

  /// Ignores [topId] when it is the client ticket number (`TKT-…`), not a UUID.
  static String? _pickServerTransactionId({
    required String? topId,
    required String? txnId,
    required String ticketNumber,
  }) {
    if (txnId != null && txnId.isNotEmpty) return txnId;
    final top = topId?.trim() ?? '';
    if (top.isEmpty) return null;
    if (top == ticketNumber.trim()) return null;
    if (top.startsWith('TKT-')) return null;
    return top;
  }
}

class BatchCheckInResultError {
  const BatchCheckInResultError({
    this.statusCode,
    this.code,
    required this.message,
  });

  final int? statusCode;
  final String? code;
  final String message;

  factory BatchCheckInResultError.fromJson(Map<String, dynamic> json) {
    final codeRaw = json['status_code'];
    return BatchCheckInResultError(
      statusCode: codeRaw is num ? codeRaw.toInt() : int.tryParse('$codeRaw'),
      code: json['code']?.toString(),
      message: json['message']?.toString() ?? 'Check-in failed',
    );
  }

  bool get isVrConflict =>
      code == 'VR_NUMBER_ALREADY_EXISTS' ||
      (statusCode == 409 &&
          message.toLowerCase().contains('vr number') &&
          message.toLowerCase().contains('already exists'));

  bool get isTicketNumberConflict =>
      code == 'TICKET_NUMBER_ALREADY_EXISTS' ||
      (statusCode == 409 &&
          message.toLowerCase().contains('ticket number') &&
          message.toLowerCase().contains('already exists'));

  /// Server already has this check-in — link local row instead of retrying POST.
  bool get isAlreadyOnServerConflict =>
      isVrConflict || isTicketNumberConflict;
}

class BatchCheckInSummary {
  const BatchCheckInSummary({
    required this.total,
    required this.succeeded,
    required this.failed,
  });

  final int total;
  final int succeeded;
  final int failed;

  factory BatchCheckInSummary.fromJson(Map<String, dynamic> json) {
    int readCount(String key) {
      final v = json[key];
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return BatchCheckInSummary(
      total: readCount('total'),
      succeeded: readCount('succeeded'),
      failed: readCount('failed'),
    );
  }
}

class BatchCheckInResponse {
  const BatchCheckInResponse({
    required this.results,
    required this.summary,
  });

  final List<BatchCheckInResultItem> results;
  final BatchCheckInSummary summary;

  factory BatchCheckInResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    final results = <BatchCheckInResultItem>[];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is Map<String, dynamic>) {
          results.add(BatchCheckInResultItem.fromJson(e));
        } else if (e is Map) {
          results.add(
            BatchCheckInResultItem.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    final summaryRaw = json['summary'];
    final summary = summaryRaw is Map<String, dynamic>
        ? BatchCheckInSummary.fromJson(summaryRaw)
        : summaryRaw is Map
            ? BatchCheckInSummary.fromJson(Map<String, dynamic>.from(summaryRaw))
            : BatchCheckInSummary(
                total: results.length,
                succeeded: results.where((r) => r.isSuccess).length,
                failed: results.where((r) => r.isFailed).length,
              );

    return BatchCheckInResponse(results: results, summary: summary);
  }

  /// Stub success for every queued item (online + offline tests).
  factory BatchCheckInResponse.stubForCheckIns(
    List<Map<String, dynamic>> checkIns,
  ) {
    final results = <BatchCheckInResultItem>[];
    for (var i = 0; i < checkIns.length; i++) {
      final item = checkIns[i];
      final ticketNumber = item['ticket_number']?.toString() ?? 'TKT-STUB';
      final vehicle = item['vehicle'];
      var plate = '';
      if (vehicle is Map) {
        plate = vehicle['plate_number']?.toString() ?? '';
      }
      plate = item['plate_number']?.toString() ?? plate;
      final vrNo = item['vr_no']?.toString() ?? '';
      const serverId = '00000000-0000-4000-8000-000000000099';
      results.add(
        BatchCheckInResultItem(
          index: i,
          status: 'success',
          ticketNumber: ticketNumber,
          plateNumber: plate,
          vrNo: vrNo,
          serverTransactionId: serverId,
          transaction: <String, dynamic>{
            'id': serverId,
            'ticket_number': ticketNumber,
            'vr_no': vrNo,
            if (plate.isNotEmpty)
              'vehicle': <String, dynamic>{'plate_number': plate},
          },
        ),
      );
    }
    return BatchCheckInResponse(
      results: results,
      summary: BatchCheckInSummary(
        total: results.length,
        succeeded: results.length,
        failed: 0,
      ),
    );
  }
}
