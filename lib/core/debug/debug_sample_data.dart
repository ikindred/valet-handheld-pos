import 'dart:math';

/// Random QA sample values for debug prefill only (not linked in release builds).
abstract final class DebugSampleData {
  DebugSampleData._();

  static final _rng = Random();

  static T pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  static List<T> pickSome<T>(List<T> items, {int min = 1, int max = 3}) {
    if (items.isEmpty) return const [];
    final count = min + _rng.nextInt(max - min + 1);
    final shuffled = List<T>.from(items)..shuffle(_rng);
    return shuffled.take(count.clamp(0, items.length)).toList();
  }

  static double normalizedCoord() =>
      0.15 + _rng.nextDouble() * 0.7; // keep away from diagram edges

  static String filipinoName() => '${pick(_firstNames)} ${pick(_lastNames)}';

  static String mobileNumber() {
    final prefix = pick(_mobilePrefixes);
    final suffix = _rng.nextInt(10000000).toString().padLeft(7, '0');
    return '$prefix$suffix';
  }

  static String plateNumber() {
    final letters = String.fromCharCodes(
      List.generate(3, (_) => 65 + _rng.nextInt(26)),
    );
    final digits = _rng.nextInt(10000).toString().padLeft(4, '0');
    return '$letters $digits';
  }

  static String vehicleDescription() => pick(_vehicles);

  static String vehicleColor() => pick(_colors);

  static String valetDriver() => pick(_valetDrivers);

  static String specialInstruction() => pick(_instructions);

  static String otherBelonging() => pick(_otherBelongings);

  static String expressAmount() {
    final amount = (pick(_expressAmounts) + _rng.nextInt(50)).clamp(50, 999);
    return amount.toDouble().toStringAsFixed(2);
  }

  static const _firstNames = [
    'Juan',
    'Maria',
    'Jose',
    'Ana',
    'Carlos',
    'Rosa',
    'Miguel',
    'Elena',
    'Pedro',
    'Liza',
    'Ramon',
    'Carmen',
  ];

  static const _lastNames = [
    'dela Cruz',
    'Santos',
    'Reyes',
    'Garcia',
    'Mendoza',
    'Torres',
    'Ramos',
    'Flores',
    'Bautista',
    'Aquino',
    'Villanueva',
    'Castillo',
  ];

  static const _mobilePrefixes = [
    '0917',
    '0918',
    '0919',
    '0920',
    '0921',
    '0922',
    '0927',
    '0935',
    '0936',
    '0945',
    '0956',
    '0998',
  ];

  static const _vehicles = [
    'Toyota Vios',
    'Honda City',
    'Mitsubishi Mirage',
    'Toyota Fortuner',
    'Nissan Almera',
    'Hyundai Tucson',
    'Mazda 3',
    'Ford Ranger',
    'Kia Sportage',
    'Toyota Innova',
    'Honda Civic',
    'Suzuki Ertiga',
  ];

  static const _colors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Pearl White',
    'Midnight Blue',
  ];

  static const _valetDrivers = [
    'Miguel Santos',
    'Carlos Mendoza',
    'Pedro Reyes',
    'Antonio Garcia',
    'Rico Villanueva',
    'Marco Dela Rosa',
  ];

  static const _instructions = [
    'Fragile items in trunk — handle with care.',
    'Customer will pick up after 6 PM.',
    'VIP guest — priority retrieval.',
    'Child seat installed in rear.',
    'Electric vehicle — charge not required.',
    'Leave air freshener as found.',
  ];

  static const _belongingOptions = [
    'iPad',
    'Cellphone / Charger',
    'Laptop / Notebook',
    'Sunglasses',
    'Other Valuables',
  ];

  static const _otherBelongings = [
    'Garage remote',
    'Umbrella',
    'Golf clubs',
    'Shopping bags',
    'Dash cam',
    'Car documents',
  ];

  static const _damageZones = [
    'Front hood',
    'Rear door',
    'Front bumper',
    'Side mirror — left',
    'Trunk',
    'Windshield',
  ];

  static const _expressAmounts = [100, 120, 150, 180, 200, 250, 300];

  static List<String> belongings() => pickSome(_belongingOptions, min: 1, max: 3);

  static String damageZone() => pick(_damageZones);
}
