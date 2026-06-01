import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/api/transaction_payment_fields.dart';

void main() {
  test('optionalMoney ignores empty object placeholders', () {
    expect(TransactionPaymentFields.optionalMoney({}), isNull);
    expect(TransactionPaymentFields.optionalMoney(200), 200);
    expect(TransactionPaymentFields.optionalMoney('150.5'), 150.5);
  });

  test('resolve reads cash_tendered and computes change from amount', () {
    final payment = TransactionPaymentFields.resolve(
      json: {
        'amount': 150,
        'cash_tendered': 200,
        'change': {},
      },
    );

    expect(payment.cashTendered, 200);
    expect(payment.change, 50);
  });

  test('resolve ignores explicit API change field', () {
    final payment = TransactionPaymentFields.resolve(
      json: {
        'amount': 150,
        'cash_tendered': 200,
        'change': 48,
      },
    );

    expect(payment.change, 50);
  });
}
