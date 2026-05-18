import 'package:equatable/equatable.dart';

/// POST `/transactions/{id}/check-out` — authoritative totals.
class CheckOutResponse extends Equatable {
  const CheckOutResponse({
    required this.invoiceNumber,
    required this.durationMinutes,
    required this.base,
    required this.extra,
    required this.overnight,
    required this.total,
  });

  final String invoiceNumber;
  final int durationMinutes;
  final double base;
  final double extra;
  final double overnight;
  final double total;

  factory CheckOutResponse.fromResponseBody(Map<String, dynamic> root) {
    final invoice =
        root['invoice_number']?.toString() ?? root['invoiceNumber']?.toString() ?? '';
    final computeRaw = root['compute'];
    final compute = computeRaw is Map
        ? Map<String, dynamic>.from(computeRaw)
        : root;
    return CheckOutResponse.fromJson(compute, invoiceNumber: invoice);
  }

  factory CheckOutResponse.fromJson(
    Map<String, dynamic> json, {
    String? invoiceNumber,
  }) {
    return CheckOutResponse(
      invoiceNumber: invoiceNumber ?? json['invoice_number']?.toString() ?? '',
      durationMinutes: _int(json['duration_minutes'] ?? json['durationMinutes']),
      base: _dbl(json['base'] ?? json['flat_rate_amount'] ?? json['flat']),
      extra: _dbl(json['extra'] ?? json['succeeding_rate_amount'] ?? json['extra_rate']),
      overnight: _dbl(json['overnight'] ?? json['overnight_amount']),
      total: _dbl(json['total'] ?? json['total_amount']),
    );
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  List<Object?> get props =>
      [invoiceNumber, durationMinutes, base, extra, overnight, total];
}
