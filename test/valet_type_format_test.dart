import 'package:flutter_test/flutter_test.dart';

import 'package:valet_handheld_pos/core/formatting/valet_type_format.dart';

void main() {
  group('ValetTypeFormat', () {
    test('labels API values', () {
      expect(ValetTypeFormat.label('self_park'), 'Self-Park');
      expect(ValetTypeFormat.label('standard_valet'), 'Standard Valet');
      expect(ValetTypeFormat.label(null), '—');
    });

    test('reads from transaction JSON', () {
      expect(
        ValetTypeFormat.rawFromTransaction({'valet_type': 'self_park'}),
        'self_park',
      );
    });

    test('reads from driverOut meta JSON', () {
      const meta = '{"valet_type":"standard_valet"}';
      expect(ValetTypeFormat.fromDriverOutMeta(meta), 'standard_valet');
      expect(ValetTypeFormat.isSelfPark('self_park'), isTrue);
    });
  });
}
