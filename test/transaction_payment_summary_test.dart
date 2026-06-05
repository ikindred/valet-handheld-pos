import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/api/transaction_payment_fields.dart';
import 'package:valet_handheld_pos/core/api/transaction_payment_summary.dart';
import 'package:valet_handheld_pos/core/pricing/transaction_payment_calculator.dart';
import 'package:valet_handheld_pos/features/check_out/domain/checkout_pricing.dart';

void main() {
  test('resolve ignores API change and computes tendered minus amount', () {
    final payment = TransactionPaymentFields.resolve(
      json: {
        'amount': 780,
        'cash_tendered': 800,
        'change': {},
      },
    );

    expect(payment.cashTendered, 800);
    expect(payment.change, 20);
  });

  test('sedan overnight stay matches flat + succeeding + overnight total', () {
    final breakdown = CheckoutPricing.computeFees(
      timeIn: DateTime(2026, 5, 30, 20, 33),
      timeOut: DateTime(2026, 5, 31, 4, 35),
      flatRate: 100,
      succeedingRate: 30,
      overnightFee: 500,
      overnightStart: '01:30',
      overnightEnd: '06:00',
      flatBlockHours: 3,
    );

    expect(breakdown.durationMinutes, 482);
    expect(breakdown.flatRateAmount, 100);
    expect(breakdown.succeedingAmount, 180);
    expect(breakdown.overnightAmount, 500);
    expect(breakdown.total, 780);

    final summary = TransactionPaymentCalculator.summaryFromBreakdown(
      breakdown: breakdown,
      flatBlockHours: 3,
      succeedingRatePerHour: 30,
      totalDue: 780,
      cashTendered: null,
      change: null,
      isLostTicket: false,
      lostTicketFee: 0,
    );

    expect(summary.flatRate, 100);
    expect(summary.succeedingHoursLabel, '5h 2m');
    expect(summary.overnightFee, 500);
    expect(summary.totalDue, 780);
  });

  test('withFlatBlockHours updates label without changing amounts', () {
    const stored = TransactionPaymentSummary(
      totalDue: 320,
      flatRate: 120,
      flatRateLabel: 'Flat rate (3h)',
      flatBlockHours: 3,
      overnightFee: 200,
      isOvernight: true,
      durationMinutes: 3,
    );

    final aligned = stored.withFlatBlockHours(8);

    expect(aligned.flatBlockHours, 8);
    expect(aligned.flatRateLabel, 'Flat rate (8h)');
    expect(aligned.flatRate, 120);
    expect(aligned.overnightFee, 200);
    expect(aligned.totalDue, 320);
  });
}
