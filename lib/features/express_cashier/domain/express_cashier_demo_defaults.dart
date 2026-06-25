import '../../../core/config/app_config.dart';

/// Temporary manual-ticketing field prefill while testing flows (e.g. Bluetooth print).
abstract final class ExpressCashierDemoDefaults {
  static bool get enabled => AppConfig.checkInPrefillEnabled;

  static const plateNumber = 'ABC 1234';
  static const driverIn = 'Carlos Mendoza';
  static const driverOut = 'Pedro Santos';
  static const amountText = '150.00';

  /// Unique per open/clear so debug saves do not collide on the server.
  static String uniqueVrNo() {
    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'EP${suffix.toString().padLeft(6, '0')}';
  }
}
