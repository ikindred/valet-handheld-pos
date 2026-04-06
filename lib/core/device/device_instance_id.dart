import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable per-install id (not a hardware device id). Used for local ticket
/// entropy and future analytics.
///
/// **Note:** True hardware device identifiers are restricted on iOS/Android;
/// this is a random id persisted in [SharedPreferences].
abstract final class DeviceInstanceId {
  static const _key = 'device_instance_id_v1';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_key, id);
    return id;
  }
}
