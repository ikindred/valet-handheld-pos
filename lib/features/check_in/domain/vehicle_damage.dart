import 'package:equatable/equatable.dart';

/// Damage category shown on the vehicle diagram and in the logged list.
enum DamageType { crack, scratch, dent }

extension DamageTypeUi on DamageType {
  String get label {
    switch (this) {
      case DamageType.crack:
        return 'Crack';
      case DamageType.scratch:
        return 'Scratch';
      case DamageType.dent:
        return 'Dent';
    }
  }

  /// Single-letter badge on the diagram (Figma-style).
  String get badgeLetter {
    switch (this) {
      case DamageType.crack:
        return 'C';
      case DamageType.scratch:
        return 'S';
      case DamageType.dent:
        return 'D';
    }
  }
}

/// One logged damage point on the top-down car image, using normalized
/// coordinates in \[0, 1\] relative to the bitmap.
class VehicleDamageEntry extends Equatable {
  const VehicleDamageEntry({
    required this.id,
    required this.normalizedX,
    required this.normalizedY,
    required this.type,
    this.zoneLabel,
  });

  final String id;
  final double normalizedX;
  final double normalizedY;
  final DamageType type;

  /// Optional human-readable zone from [lookupVehicleZoneLabel].
  final String? zoneLabel;

  @override
  List<Object?> get props => [id, normalizedX, normalizedY, type, zoneLabel];
}
