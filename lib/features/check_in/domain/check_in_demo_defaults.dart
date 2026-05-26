import '../../../core/config/app_config.dart';
import '../state/check_in_cubit.dart';
import 'vehicle_body_type.dart';
import 'vehicle_damage.dart';

/// Temporary check-in field prefill while testing flows (e.g. Bluetooth print).
abstract final class CheckInDemoDefaults {
  static bool get enabled => AppConfig.checkInPrefillEnabled;

  static CheckInState initial() {
    final now = DateTime.now();
    return CheckInState(
      customerFullName: 'Juan dela Cruz',
      contactNumber: '09171234567',
      assignedValetDriver: 'Miguel Santos',
      specialInstructions: 'Fragile items in trunk — handle with care.',
      dateTimeIn: now,
      valetServiceType: ValetServiceType.standardValet,
      plateNumber: 'ABC 1234',
      vehicleModel: 'Vios',
      vehicleBrandMake: 'Toyota',
      vehicleColor: 'White',
      vehicleYear: '2024',
      vehicleBodyType: VehicleBodyType.sedan,
      parkingLevel: 'Level 1',
      parkingSlot: 'Slot #1',
      selectedBelongings: const [
        'iPad',
        'Cellphone / Charger',
        'Other Valuables',
      ],
      otherBelongings: 'Garage remote',
      selectedDamageType: DamageType.dent,
      vehicleDamageEntries: const [
        VehicleDamageEntry(
          id: 'demo-damage-1',
          normalizedX: 0.48,
          normalizedY: 0.32,
          type: DamageType.dent,
          zoneLabel: 'Front hood',
        ),
        VehicleDamageEntry(
          id: 'demo-damage-2',
          normalizedX: 0.72,
          normalizedY: 0.55,
          type: DamageType.scratch,
          zoneLabel: 'Rear door',
        ),
      ],
    );
  }
}
