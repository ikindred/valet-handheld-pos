import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/receipt_print_format.dart';
import 'package:valet_handheld_pos/features/check_out/models/checkout_preview_rates.dart';

void main() {
  group('ReceiptPrintFormat overnight labels', () {
    test('overnightWindowLabel shows start and end', () {
      expect(
        ReceiptPrintFormat.overnightWindowLabel(
          startHhMm24: '01:30',
          endHhMm24: '06:00',
        ),
        '1:30 AM – 6:00 AM',
      );
    });

    test('overnightWindowLabel shows after start when end missing', () {
      expect(
        ReceiptPrintFormat.overnightWindowLabel(startHhMm24: '01:30'),
        'after 1:30 AM',
      );
    });

    test('overnightFeeRowLabel without configured window', () {
      expect(
        ReceiptPrintFormat.overnightFeeRowLabel(startHhMm24: ''),
        'Overnight Fee',
      );
    });
  });

  test('CheckoutPreviewRates leaves overnight times empty when API omits them',
      () {
    final rates = CheckoutPreviewRates.fromJson({
      'flat_rate': 150,
      'succeeding_rate': 30,
      'overnight_fee': 500,
    });
    expect(rates, isNotNull);
    expect(rates!.overnightStart, isEmpty);
    expect(rates.overnightEnd, isEmpty);
  });
}
