/// Vehicle body style for check-in step 2 (Figma vehicle type grid).
enum VehicleBodyType { sedan, suv, van, luxury, evPhev }

extension VehicleBodyTypeX on VehicleBodyType {
  String get label => switch (this) {
    VehicleBodyType.sedan => 'Sedan',
    VehicleBodyType.suv => 'SUV',
    VehicleBodyType.van => 'Van',
    VehicleBodyType.luxury => 'Luxury',
    VehicleBodyType.evPhev => 'EV/PHEV',
  };

  String get emoji => switch (this) {
    VehicleBodyType.sedan => '🚘',
    VehicleBodyType.suv => '🚙',
    VehicleBodyType.van => '🚐',
    VehicleBodyType.luxury => '💎',
    VehicleBodyType.evPhev => '⚡',
  };
}
