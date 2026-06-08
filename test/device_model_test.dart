import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/device_setup/cubit/device_setup_state.dart';

void main() {
  group('DeviceModel.fromJson', () {
    test('prefers display_name for device label', () {
      final model = DeviceModel.fromJson({
        'id': 'dev-1',
        'display_name': 'Front Desk POS',
        'device_label': 'legacy-label',
        'serial_number': 'SN-001',
        'branch_name': 'Main',
        'area_name': 'Lobby',
      });

      expect(model.deviceLabel, 'Front Desk POS');
      expect(model.serialNumber, 'SN-001');
    });
  });
}
