/// SharedPreferences: **only** these keys. No auth, user profile, shift, or token data.
abstract final class PrefsKeys {
  /// Final SHA-256 device id (written once). See [DeviceIdService].
  static const deviceId = 'spid_device_id';

  /// Fallback UUID seed for device id (written once). See [DeviceIdService].
  static const deviceUuid = 'spid_device_uuid';

  /// Whether the app is currently treated as offline (no reliable API connectivity).
  static const offlineMode = 'spid_offline_mode';

  /// Site branch from `POST /api/v1/device/register` (response or defaults).
  static const deviceBranch = 'spid_device_branch';

  /// Site area from device register (response or defaults).
  static const deviceArea = 'spid_device_area';
}
