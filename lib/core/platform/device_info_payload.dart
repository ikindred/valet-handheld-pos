import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Lightweight device payload for POST /devices/register.
Future<Map<String, dynamic>> buildDeviceInfoPayload() async {
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await plugin.androidInfo;
      return {
        'os': 'android',
        'model': a.model,
        'manufacturer': a.manufacturer,
        'sdk_int': a.version.sdkInt,
        // Used by [AuthApi.registerDevice] for `os_version` (Android release).
        'system_version': a.version.release,
      };
    }
    if (Platform.isIOS) {
      final i = await plugin.iosInfo;
      return {
        'os': 'ios',
        'model': i.utsname.machine,
        'system_version': i.systemVersion,
      };
    }
    return {'os': Platform.operatingSystem};
  } catch (_) {
    return {'os': Platform.operatingSystem};
  }
}
