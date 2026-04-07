import '../services/device_id_service.dart';

/// Stable id persisted under [PrefsKeys.deviceId] (same as [DeviceIdService]).
///
/// Used for ticket entropy and analytics.
abstract final class DeviceInstanceId {
  static Future<String> getOrCreate() => DeviceIdService.getOrCreate();
}
