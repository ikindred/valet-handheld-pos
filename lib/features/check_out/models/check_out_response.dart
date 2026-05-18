import 'package:equatable/equatable.dart';

/// POST `/transactions/{id}/check-out` — `{ invoice_number, transaction, preview }`.
class CheckOutResponse extends Equatable {
  const CheckOutResponse({
    required this.invoiceNumber,
    required this.transactionId,
    required this.status,
    required this.total,
  });

  final String invoiceNumber;
  final String transactionId;
  final String status;

  /// Authoritative amount from `transaction.amount`.
  final double total;

  factory CheckOutResponse.fromResponseBody(Map<String, dynamic> root) {
    final invoice =
        root['invoice_number']?.toString() ?? root['invoiceNumber']?.toString() ?? '';

    final txRaw = root['transaction'];
    final tx = txRaw is Map
        ? Map<String, dynamic>.from(txRaw)
        : <String, dynamic>{};

    final transactionId = tx['id']?.toString() ?? '';
    final status = tx['status']?.toString() ?? '';
    final amountRaw = tx['amount'] ?? tx['total_amount'] ?? tx['totalAmount'];
    final total = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '') ?? 0.0;

    return CheckOutResponse(
      invoiceNumber: invoice,
      transactionId: transactionId,
      status: status,
      total: total,
    );
  }

  @override
  List<Object?> get props => [invoiceNumber, transactionId, status, total];
}
