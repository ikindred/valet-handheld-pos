import 'package:flutter_test/flutter_test.dart';

import 'package:valet_handheld_pos/features/check_out/domain/checkout_valet_type.dart';

void main() {
  group('CheckoutValetType', () {
    test('isSelfPark recognizes API values', () {
      expect(CheckoutValetType.isSelfPark('self_park'), isTrue);
      expect(CheckoutValetType.isSelfPark('self park'), isTrue);
      expect(CheckoutValetType.isSelfPark('standard_valet'), isFalse);
      expect(CheckoutValetType.isSelfPark(null), isFalse);
    });

    test('fromDriverOutMeta reads valet_type JSON', () {
      const meta = '{"valet_type":"self_park","customer_name":"Ana"}';
      expect(CheckoutValetType.fromDriverOutMeta(meta), 'self_park');
      expect(CheckoutValetType.isSelfParkFromDriverOutMeta(meta), isTrue);
    });

    test('fromDriverOutMeta ignores plain driver name', () {
      expect(CheckoutValetType.fromDriverOutMeta('Carlos Mendoza'), isNull);
    });
  });
}
