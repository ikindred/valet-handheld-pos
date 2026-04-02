import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../storage/prefs_keys.dart';

class DeviceIdService {
  const DeviceIdService(this._prefs);

  final SharedPreferences _prefs;

  String getOrCreate() {
    final existing = _prefs.getString(PrefsKeys.deviceId);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final created = const Uuid().v4();
    _prefs.setString(PrefsKeys.deviceId, created);
    return created;
  }
}

