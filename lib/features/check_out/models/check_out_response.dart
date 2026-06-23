import 'package:equatable/equatable.dart';

import '../../../core/api/transaction_payment_fields.dart';
import '../../../core/formatting/valet_type_format.dart';

/// POST `/transactions/{id}/check-out` — `{ invoice_number, transaction, preview }`.
class CheckOutResponse extends Equatable {
  const CheckOutResponse({
    required this.invoiceNumber,
    required this.transactionId,
    required this.status,
    required this.total,
    this.cashTendered,
    this.changePesos,
    this.valetType,
  });

  final String invoiceNumber;
  final String transactionId;
  final String status;

  /// Authoritative amount from `transaction.amount`.
  final double total;

  final double? cashTendered;
  final double? changePesos;
  final String? valetType;

  factory CheckOutResponse.fromResponseBody(Map<String, dynamic> root) {
    final invoice =
        root['invoice_number']?.toString() ?? root['invoiceNumber']?.toString() ?? '';

    final txRaw = root['transaction'];
    final tx = txRaw is Map
        ? Map<String, dynamic>.from(txRaw)
        : <String, dynamic>{};

    final transactionId = tx['id']?.toString() ?? '';
    final status = tx['status']?.toString() ?? '';
    final total = TransactionPaymentFields.amountFrom(tx) ?? 0.0;
    final payment = TransactionPaymentFields.resolve(json: tx, amount: total);

    return CheckOutResponse(
      invoiceNumber: invoice,
      transactionId: transactionId,
      status: status,
      total: total,
      cashTendered: payment.cashTendered,
      changePesos: payment.change,
      valetType: ValetTypeFormat.rawFromTransaction(tx),
    );
  }

  @override
  List<Object?> get props => [
        invoiceNumber,
        transactionId,
        status,
        total,
        cashTendered,
        changePesos,
        valetType,
      ];
}
