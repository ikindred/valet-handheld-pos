import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_keys.dart';

/// Read / write [PrefsKeys.offlineMode] only.
abstract final class OfflineModePrefs {
  static bool read(SharedPreferences prefs) =>
      prefs.getBool(PrefsKeys.offlineMode) ?? false;

  static Future<void> write(SharedPreferences prefs, bool value) =>
      prefs.setBool(PrefsKeys.offlineMode, value);
}
