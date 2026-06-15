import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/session/standard_parking_rates.dart';
import 'package:valet_handheld_pos/features/check_out/domain/checkout_rate_resolution.dart';
import 'package:valet_handheld_pos/features/check_out/models/checkout_preview_rates.dart';

void main() {
  test('previewParkingRatesEmpty is true only when flat and succeeding are zero',
      () {
    const empty = CheckoutPreviewRates(
      flatRate: 0,
      succeedingRate: 0,
      overnightFee: 100,
      lostTicketFee: 200,
      overnightStart: '01:30',
      overnightEnd: '06:00',
    );
    expect(CheckoutRateResolution.previewParkingRatesEmpty(empty), isTrue);

    const partial = CheckoutPreviewRates(
      flatRate: 150,
      succeedingRate: 0,
      overnightFee: 0,
      lostTicketFee: 0,
      overnightStart: '',
      overnightEnd: '',
    );
    expect(CheckoutRateResolution.previewParkingRatesEmpty(partial), isFalse);
  });

  test('effectiveRates uses full Drift row when preview parking fees are zero', () {
    const preview = CheckoutPreviewRates(
      flatRate: 0,
      succeedingRate: 0,
      overnightFee: 0,
      lostTicketFee: 200,
      overnightStart: '02:00',
      overnightEnd: '05:00',
      flatRateHours: 2,
    );
    const drift = StandardParkingRates(
      flatRatePesos: 180,
      succeedingHourPesos: 40,
      overnightFeePesos: 120,
      lostTicketFeePesos: 250,
    );

    final effective = CheckoutRateResolution.effectiveRates(
      preview: preview,
      drift: drift,
      driftFlatHours: 4,
      driftOvernightStart: '01:30',
      driftOvernightEnd: '06:00',
    );

    expect(effective.flatRate, 180);
    expect(effective.succeedingRate, 40);
    expect(effective.overnightFee, 120);
    expect(effective.lostTicketFee, 250);
    expect(effective.flatRateHours, 4);
    expect(effective.overnightStart, '01:30');
    expect(effective.overnightEnd, '06:00');
  });

  test('effectiveRates keeps preview when parking fees are set', () {
    const preview = CheckoutPreviewRates(
      flatRate: 150,
      succeedingRate: 30,
      overnightFee: 100,
      lostTicketFee: 200,
      overnightStart: '01:30',
      overnightEnd: '06:00',
      flatRateHours: 3,
    );
    const drift = StandardParkingRates(
      flatRatePesos: 999,
      succeedingHourPesos: 99,
      overnightFeePesos: 99,
      lostTicketFeePesos: 99,
    );

    final effective = CheckoutRateResolution.effectiveRates(
      preview: preview,
      drift: drift,
      driftFlatHours: 8,
      driftOvernightStart: '00:00',
      driftOvernightEnd: '23:59',
    );

    expect(effective, preview);
  });

  test('effectiveRates keeps preview zeros when Drift is null', () {
    const preview = CheckoutPreviewRates(
      flatRate: 0,
      succeedingRate: 0,
      overnightFee: 0,
      lostTicketFee: 200,
      overnightStart: '01:30',
      overnightEnd: '06:00',
    );

    final effective = CheckoutRateResolution.effectiveRates(
      preview: preview,
      drift: null,
      driftFlatHours: 3,
      driftOvernightStart: '',
      driftOvernightEnd: '',
    );

    expect(effective, preview);
  });
}
