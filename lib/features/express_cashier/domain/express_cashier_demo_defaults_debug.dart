import '../../../core/config/app_config.dart';
import '../../../core/debug/debug_sample_data.dart';

/// Debug-only manual-ticketing field prefill (randomized each open).
abstract final class ExpressCashierDemoDefaults {
  static bool get enabled => AppConfig.checkInPrefillEnabled;

  static String get plateNumber => DebugSampleData.plateNumber();

  static String get driverIn => DebugSampleData.valetDriver();

  static String get driverOut => DebugSampleData.filipinoName();

  static String get amountText => DebugSampleData.expressAmount();

  /// Unique per open/clear so debug saves do not collide on the server.
  static String uniqueVrNo() {
    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'EP${suffix.toString().padLeft(6, '0')}';
  }
}
