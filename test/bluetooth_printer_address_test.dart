import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/printing/bluetooth_pos_printer.dart';

void main() {
  group('bluetoothAddressesMatch', () {
    test('matches same MAC with different separators and case', () {
      expect(
        bluetoothAddressesMatch('AA:BB:CC:DD:EE:FF', 'aa-bb-cc-dd-ee-ff'),
        isTrue,
      );
    });

    test('rejects different addresses', () {
      expect(
        bluetoothAddressesMatch('AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'),
        isFalse,
      );
    });

    test('rejects null or blank', () {
      expect(bluetoothAddressesMatch(null, 'AA:BB:CC:DD:EE:FF'), isFalse);
      expect(bluetoothAddressesMatch('', 'AA:BB:CC:DD:EE:FF'), isFalse);
    });
  });
}
