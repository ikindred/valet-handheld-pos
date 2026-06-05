/// Vehicle body style for check-in step 2 (Figma vehicle type grid).
enum VehicleBodyType { sedan, suv, van, luxury, evPhev, motorcycle }

/// Drift / API `vehicle_type` key (aligned with check-out and [RateFetchService]).
extension VehicleBodyTypeRateKey on VehicleBodyType {
  String get rateKey => switch (this) {
        VehicleBodyType.sedan => 'sedan',
        VehicleBodyType.suv => 'suv',
        VehicleBodyType.van => 'van',
        VehicleBodyType.luxury => 'luxury',
        VehicleBodyType.evPhev => 'ev_phev',
        VehicleBodyType.motorcycle => 'motorcycle',
      };
}

extension VehicleBodyTypeX on VehicleBodyType {
  String get label => switch (this) {
    VehicleBodyType.sedan => 'Sedan/Crossover',
    VehicleBodyType.suv => 'SUV',
    VehicleBodyType.van => 'Van',
    VehicleBodyType.luxury => 'Luxury',
    VehicleBodyType.evPhev => 'EV/PHEV',
    VehicleBodyType.motorcycle => 'Motorcycle',
  };

  String get emoji => switch (this) {
    VehicleBodyType.sedan => '🚘',
    VehicleBodyType.suv => '🚙',
    VehicleBodyType.van => '🚐',
    VehicleBodyType.luxury => '💎',
    VehicleBodyType.evPhev => '⚡',
    VehicleBodyType.motorcycle => '🏍️',
  };
}
