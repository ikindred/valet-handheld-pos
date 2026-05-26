import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/db/app_database.dart';
import '../../features/device_setup/cubit/device_setup_state.dart';
import '../services/device_id_service.dart';
import 'prefs_keys.dart';
import 'site_display_name.dart';

/// Restores [PrefsKeys.deviceIdentityKey] from Drift when claim succeeded but prefs were lost.
abstract final class DeviceClaimRestore {
  /// Returns a [DeviceModel] when local claim data exists and was synced to prefs.
  static Future<DeviceModel?> tryRestoreFromDatabase(AppDatabase db) async {
    final row = await (db.select(db.deviceIdentity)..limit(1)).getSingleOrNull();
    if (row == null) return null;

    final serverDeviceId = row.serverDeviceId.trim();
    if (serverDeviceId.isEmpty) return null;

    final hash = await DeviceIdService.sha256RawAndroidId();
    if (hash.isNotEmpty &&
        row.androidIdHash.trim().isNotEmpty &&
        row.androidIdHash.trim() != hash) {
      return null;
    }

    final device = DeviceModel(
      serverDeviceId: serverDeviceId,
      deviceLabel: row.deviceLabel,
      branchName: SiteDisplayName.sanitizeStored(row.branch),
      areaName: SiteDisplayName.sanitizeStored(row.area),
      serialNumber: row.serialNumber,
      branchId: row.branchId,
      areaId: row.areaId,
      isActive: row.isActive,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.deviceIdentityKey, serverDeviceId);

    final b = device.branchName;
    final a = device.areaName;
    if (b.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranch, b);
    }
    if (a.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceArea, a);
    }
    if (device.branchId.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranchId, device.branchId);
    }
    if (device.areaId.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceAreaId, device.areaId);
    }

    return device;
  }
}
