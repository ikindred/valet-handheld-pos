import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/branch/overnight_window.dart';
import 'package:valet_handheld_pos/core/time/philippine_time.dart';
import 'package:valet_handheld_pos/features/check_out/domain/checkout_pricing.dart';
import 'package:valet_handheld_pos/features/check_out/models/checkout_preview_rates.dart';

void main() {
  group('CheckoutPricing short stay', () {
    test('3 minutes within flat block has no succeeding or overnight', () {
      const rates = CheckoutPreviewRates(
        flatRate: 100,
        succeedingRate: 30,
        overnightFee: 500,
        lostTicketFee: 200,
        overnightStart: '01:30',
        overnightEnd: '06:00',
      );
      final timeIn = DateTime(2026, 5, 30, 23, 21);
      final timeOut = DateTime(2026, 5, 30, 23, 24);

      final b = CheckoutPricing.computeFromPreviewRates(
        timeIn: timeIn,
        timeOut: timeOut,
        rates: rates,
      );

      expect(b.durationMinutes, 3);
      expect(b.flatRateAmount, 100);
      expect(b.succeedingAmount, 0);
      expect(b.overnightAmount, 0);
      expect(b.overnightApplied, isFalse);
      expect(b.total, 100);
    });

    test('pricingWindow uses ticket check-in and checkout instant', () {
      final window = CheckoutPricing.pricingWindow(
        checkInRaw: '2026-05-30T23:21:00.000',
        timeOut: DateTime(2026, 5, 30, 23, 24),
      );
      expect(window.durationMinutes, 3);
    });

    test('pricingWindow does not double-shift PhilippineTime.now checkout', () {
      final window = CheckoutPricing.pricingWindow(
        checkInRaw: '2026-05-31T00:00:00.000',
        timeOut: DateTime(2026, 5, 31, 0, 18),
      );
      expect(window.durationMinutes, 18);
    });

    test('PhilippineTime.now() is not UTC-flagged', () {
      final now = PhilippineTime.now();
      expect(now.isUtc, isFalse,
          reason:
              'now() must return a non-UTC DateTime so wallClock() does not double-shift it');
    });

    test('wallClock does not double-shift PhilippineTime.now()', () {
      final now = PhilippineTime.now();
      final wall = CheckoutPricing.wallClock(now);
      expect(wall.hour, now.hour);
      expect(wall.day, now.day);
    });
  });

  group('OvernightWindow.stayOverlaps', () {
    // Window: 9 PM (21:00) → 5 AM (05:00), crosses midnight.
    final window = OvernightWindow.tryFromHhMm('21:00', '05:00')!;

    test('park after midnight inside overnight window triggers fee', () {
      // Check-in 12:00 AM May 31, check-out 12:27 AM May 31.
      // The 9 PM–5 AM window that started May 30 evening covers this stay.
      final timeIn = DateTime(2026, 5, 31, 0, 0);
      final timeOut = DateTime(2026, 5, 31, 0, 27);
      expect(window.stayOverlaps(timeIn, timeOut), isTrue,
          reason: 'midnight stay falls inside the previous evening window');
    });

    test('park at 9 PM triggers overnight fee', () {
      final timeIn = DateTime(2026, 5, 30, 21, 0);
      final timeOut = DateTime(2026, 5, 30, 21, 30);
      expect(window.stayOverlaps(timeIn, timeOut), isTrue);
    });

    test('park at 10 AM does not trigger overnight fee', () {
      final timeIn = DateTime(2026, 5, 31, 10, 0);
      final timeOut = DateTime(2026, 5, 31, 11, 0);
      expect(window.stayOverlaps(timeIn, timeOut), isFalse);
    });

    test('pricing compute applies overnight for midnight stay', () {
      const rates = CheckoutPreviewRates(
        flatRate: 100,
        succeedingRate: 30,
        overnightFee: 500,
        lostTicketFee: 200,
        overnightStart: '21:00',
        overnightEnd: '05:00',
      );
      final b = CheckoutPricing.computeFromPreviewRates(
        timeIn: DateTime(2026, 5, 31, 0, 0),
        timeOut: DateTime(2026, 5, 31, 0, 27),
        rates: rates,
      );
      expect(b.overnightApplied, isTrue,
          reason: 'midnight-to-12:27AM overlaps 9PM–5AM window');
      expect(b.overnightAmount, 500);
      expect(b.total, 600); // flat 100 + overnight 500
    });
  });
}
