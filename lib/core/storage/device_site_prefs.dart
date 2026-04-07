import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'prefs_keys.dart';

/// Branch / area for this device: defaults → `POST .../device/register` request & response.
abstract final class DeviceSitePrefs {
  static String? readBranch(SharedPreferences prefs) =>
      prefs.getString(PrefsKeys.deviceBranch);

  static String? readArea(SharedPreferences prefs) =>
      prefs.getString(PrefsKeys.deviceArea);

  /// Values for `POST /device/register` body when prefs are empty (optional `.env` overrides).
  static String requestBranch(SharedPreferences prefs) {
    final v = readBranch(prefs);
    if (v != null && v.trim().isNotEmpty) return v.trim();
    return AppConfig.defaultDeviceBranch;
  }

  static String requestArea(SharedPreferences prefs) {
    final v = readArea(prefs);
    if (v != null && v.trim().isNotEmpty) return v.trim();
    return AppConfig.defaultDeviceArea;
  }

  /// Persists branch/area from register response; clears keys when the API omits or returns empty strings.
  static Future<void> applyRegisterResponse(
    SharedPreferences prefs, {
    String? branch,
    String? area,
  }) async {
    if (branch != null && branch.trim().isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranch, branch.trim());
    } else {
      await prefs.remove(PrefsKeys.deviceBranch);
    }
    if (area != null && area.trim().isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceArea, area.trim());
    } else {
      await prefs.remove(PrefsKeys.deviceArea);
    }
  }
}
