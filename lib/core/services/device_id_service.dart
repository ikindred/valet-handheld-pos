import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../storage/prefs_keys.dart';

/// Single source of truth for `spid_device_id`: ANDROID_ID + fallback UUID, SHA-256 hashed.
///
/// Raw ANDROID_ID is never exposed outside this class.
class DeviceIdService {
  DeviceIdService._();

  /// SHA-256 hex digest of **raw** ANDROID_ID only (for server `android_id_hash` / device claim).
  /// Empty string when unavailable (non-Android or error).
  static Future<String> sha256RawAndroidId() async {
    if (!Platform.isAndroid) return '';
    try {
      final raw = await const AndroidId().getId();
      if (raw == null || raw.isEmpty) return '';
      return sha256.convert(utf8.encode(raw)).toString();
    } catch (_) {
      return '';
    }
  }

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(PrefsKeys.deviceId);
    if (cached != null && cached.isNotEmpty) return cached;

    String? androidId;
    if (Platform.isAndroid) {
      try {
        androidId = await const AndroidId().getId();
      } catch (_) {
        androidId = null;
      }
    }
    if (androidId != null && androidId.isEmpty) androidId = null;

    String fallback = prefs.getString(PrefsKeys.deviceUuid) ?? '';
    if (fallback.isEmpty) {
      fallback = const Uuid().v4();
      await prefs.setString(PrefsKeys.deviceUuid, fallback);
    }

    final raw = (androidId != null && androidId.isNotEmpty)
        ? '$androidId:$fallback'
        : fallback;

    final deviceId = sha256.convert(utf8.encode(raw)).toString();

    await prefs.setString(PrefsKeys.deviceId, deviceId);

    return deviceId;
  }
}
