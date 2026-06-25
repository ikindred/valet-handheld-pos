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

  /// Server branch id from device claim (UUID/slug).
  static const deviceBranchId = 'spid_device_branch_id';

  /// Server area id from device claim (UUID/slug).
  static const deviceAreaId = 'spid_device_area_id';

  /// Server-claimed POS terminal identity key; splash routes to login only when set.
  static const deviceIdentityKey = 'device_identity_key';

  /// Paired Bluetooth thermal printer (MAC / address).
  static const printerAddress = 'spid_printer_bt_address';

  /// Display name of paired printer.
  static const printerName = 'spid_printer_bt_name';

  /// Receipt width: `mm58` or `mm80`.
  static const printerPaperWidth = 'spid_printer_paper_width';

  /// `true` when the saved printer uses Bluetooth Low Energy.
  static const printerUseBle = 'spid_printer_use_ble';

  /// Auto-sync offline queue when connectivity is restored (default on).
  static const autoSyncOnConnect = 'spid_auto_sync_on_connect';
}
