import 'package:flutter_test/flutter_test.dart';

import 'package:valet_handheld_pos/features/check_in/domain/vehicle_damage.dart';
import 'package:valet_handheld_pos/features/check_in/state/check_in_cubit.dart';

void main() {
  group('CheckInCubit vehicle damage', () {
    test('addDamageAt appends entry; removeDamage clears it', () {
      final cubit = CheckInCubit();
      cubit.selectDamageType(DamageType.scratch);
      cubit.addDamageAt(0.1, 0.2);
      expect(cubit.state.vehicleDamageEntries.length, 1);
      expect(cubit.state.vehicleDamageEntries.first.type, DamageType.scratch);
      expect(cubit.state.vehicleDamageEntries.first.normalizedX, 0.1);
      expect(cubit.state.vehicleDamageEntries.first.normalizedY, 0.2);
      final id = cubit.state.vehicleDamageEntries.first.id;
      cubit.removeDamage(id);
      expect(cubit.state.vehicleDamageEntries, isEmpty);
    });

    test('resetSession clears damage entries', () {
      final cubit = CheckInCubit();
      cubit.addDamageAt(0.5, 0.5);
      expect(cubit.state.vehicleDamageEntries.length, 1);
      cubit.resetSession();
      expect(cubit.state.vehicleDamageEntries, isEmpty);
    });

    test('setCustomerSignatureCaptured and resetSession', () {
      final cubit = CheckInCubit();
      expect(cubit.state.hasCustomerSignature, isFalse);
      cubit.setCustomerSignatureCaptured(true);
      expect(cubit.state.hasCustomerSignature, isTrue);
      cubit.resetSession();
      expect(cubit.state.hasCustomerSignature, isFalse);
    });

    test('clearLoggedDamage removes all entries', () {
      final cubit = CheckInCubit();
      cubit.addDamageAt(0.1, 0.2);
      cubit.addDamageAt(0.3, 0.4);
      expect(cubit.state.vehicleDamageEntries.length, 2);
      cubit.clearLoggedDamage();
      expect(cubit.state.vehicleDamageEntries, isEmpty);
    });
  });
}
