import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/branch/overnight_window.dart';
import 'package:valet_handheld_pos/features/check_out/domain/checkout_pricing.dart';
import 'package:valet_handheld_pos/features/check_out/models/checkout_preview_rates.dart';

void main() {
  group('OvernightWindow.stayOverlaps', () {
    test('9pm check-in to 6am check-out hits 01:30–05:30 window', () {
      final window = OvernightWindow.tryFromHhMm('01:30', '05:30')!;
      final timeIn = DateTime(2026, 5, 20, 21, 0);
      final timeOut = DateTime(2026, 5, 21, 6, 0);
      expect(window.stayOverlaps(timeIn, timeOut), isTrue);
    });

    test('same-evening stay before overnight window does not overlap', () {
      final window = OvernightWindow.tryFromHhMm('01:30', '05:30')!;
      final timeIn = DateTime(2026, 5, 20, 21, 0);
      final timeOut = DateTime(2026, 5, 20, 22, 0);
      expect(window.stayOverlaps(timeIn, timeOut), isFalse);
    });

    test('morning exit after window does not overlap when never in window', () {
      final window = OvernightWindow.tryFromHhMm('01:30', '05:30')!;
      final timeIn = DateTime(2026, 5, 21, 6, 0);
      final timeOut = DateTime(2026, 5, 21, 8, 0);
      expect(window.stayOverlaps(timeIn, timeOut), isFalse);
    });
  });

  group('CheckoutPricing overnight fee', () {
    test('applies overnight fee for 9pm–6am with preview rates', () {
      const rates = CheckoutPreviewRates(
        flatRate: 150,
        succeedingRate: 30,
        overnightFee: 500,
        lostTicketFee: 200,
        overnightStart: '01:30',
        overnightEnd: '05:30',
      );
      final breakdown = CheckoutPricing.computeFromPreviewRates(
        timeIn: DateTime(2026, 5, 20, 21, 0),
        timeOut: DateTime(2026, 5, 21, 6, 0),
        rates: rates,
      );
      expect(breakdown.overnightApplied, isTrue);
      expect(breakdown.overnightAmount, 500);
    });

    test('no overnight fee for same-evening checkout', () {
      const rates = CheckoutPreviewRates(
        flatRate: 150,
        succeedingRate: 30,
        overnightFee: 500,
        lostTicketFee: 200,
        overnightStart: '01:30',
        overnightEnd: '05:30',
      );
      final breakdown = CheckoutPricing.computeFromPreviewRates(
        timeIn: DateTime(2026, 5, 20, 21, 0),
        timeOut: DateTime(2026, 5, 20, 22, 0),
        rates: rates,
      );
      expect(breakdown.overnightApplied, isFalse);
      expect(breakdown.overnightAmount, 0);
    });
  });

  test('CheckoutPreviewRates parses overnight_start and overnight_end', () {
    final rates = CheckoutPreviewRates.fromJson({
      'flat_rate': 150,
      'succeeding_rate': 30,
      'overnight_fee': 500,
      'lost_ticket_fee': 200,
      'overnight_start': '01:30',
      'overnight_end': '05:30',
    });
    expect(rates, isNotNull);
    expect(rates!.overnightStart, '01:30');
    expect(rates.overnightEnd, '05:30');
  });
}
