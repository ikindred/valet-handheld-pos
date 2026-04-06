/// Vehicle body style for check-in step 2 (Figma vehicle type grid).
enum VehicleBodyType { sedan, suv, van, truck, bus, motorcycle }

extension VehicleBodyTypeX on VehicleBodyType {
  String get label => switch (this) {
    VehicleBodyType.sedan => 'Sedan',
    VehicleBodyType.suv => 'SUV',
    VehicleBodyType.van => 'Van',
    VehicleBodyType.truck => 'Truck',
    VehicleBodyType.bus => 'Bus',
    VehicleBodyType.motorcycle => 'Motorcycle',
  };

  String get emoji => switch (this) {
    VehicleBodyType.sedan => '🚘',
    VehicleBodyType.suv => '🚙',
    VehicleBodyType.van => '🚐',
    VehicleBodyType.truck => '🚚',
    VehicleBodyType.bus => '🚌',
    VehicleBodyType.motorcycle => '🏍️',
  };
}
