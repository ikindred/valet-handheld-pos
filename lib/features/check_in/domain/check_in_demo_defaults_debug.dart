import '../../../core/config/app_config.dart';
import '../../../core/debug/debug_sample_data.dart';
import '../state/check_in_cubit.dart';
import 'vehicle_body_type.dart';
import 'vehicle_damage.dart';

/// Debug-only check-in field prefill (randomized each session).
abstract final class CheckInDemoDefaults {
  static bool get enabled => AppConfig.checkInPrefillEnabled;

  static CheckInState initial() {
    final now = DateTime.now();
    final bodyType = DebugSampleData.pick(VehicleBodyType.values);
    final primaryDamage = DebugSampleData.pick(DamageType.values);
    final damageCount = DebugSampleData.pick(const [1, 2]);

    return CheckInState(
      customerFullName: DebugSampleData.filipinoName(),
      contactNumber: DebugSampleData.mobileNumber(),
      assignedValetDriver: DebugSampleData.valetDriver(),
      specialInstructions: DebugSampleData.specialInstruction(),
      dateTimeIn: now,
      valetServiceType: ValetServiceType.standardValet,
      plateNumber: DebugSampleData.plateNumber(),
      vehicleBrand: DebugSampleData.vehicleDescription(),
      vehicleColor: DebugSampleData.vehicleColor(),
      vehicleBodyType: bodyType,
      parkingLevel: 'Level 1',
      parkingSlot: 'Slot #1',
      selectedBelongings: DebugSampleData.belongings(),
      otherBelongings: DebugSampleData.otherBelonging(),
      selectedDamageType: primaryDamage,
      vehicleDamageEntries: List.generate(damageCount, (i) {
        final type = i == 0
            ? primaryDamage
            : DebugSampleData.pick(DamageType.values);
        return VehicleDamageEntry(
          id: 'demo-damage-$i-${now.microsecondsSinceEpoch}',
          normalizedX: DebugSampleData.normalizedCoord(),
          normalizedY: DebugSampleData.normalizedCoord(),
          type: type,
          zoneLabel: DebugSampleData.damageZone(),
        );
      }),
    );
  }
}
