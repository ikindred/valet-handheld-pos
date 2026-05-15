import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'prefs_keys.dart';
import 'site_display_name.dart';

/// Branch / area for this device: defaults → `POST .../device/register` request & response.
abstract final class DeviceSitePrefs {
  static String? readBranch(SharedPreferences prefs) {
    final raw = prefs.getString(PrefsKeys.deviceBranch);
    final name = SiteDisplayName.sanitizeStored(raw);
    return name.isEmpty ? null : name;
  }

  static String? readArea(SharedPreferences prefs) {
    final raw = prefs.getString(PrefsKeys.deviceArea);
    final name = SiteDisplayName.sanitizeStored(raw);
    return name.isEmpty ? null : name;
  }

  /// Branch and area display names from claim / validate (SharedPreferences).
  static ({String branch, String area}) readSiteNames(SharedPreferences prefs) {
    return (
      branch: readBranch(prefs) ?? '',
      area: readArea(prefs) ?? '',
    );
  }

  static bool hasSiteNames(SharedPreferences prefs) {
    final p = readSiteNames(prefs);
    return p.branch.isNotEmpty && p.area.isNotEmpty;
  }

  /// Login footer: `BRANCH : AREA — VALET ATTENDANT` (uppercase names).
  static String valetAttendantFooterLine(SharedPreferences prefs) {
    final p = readSiteNames(prefs);
    if (!hasSiteNames(prefs)) {
      return 'This device is not yet assigned to a branch and area.';
    }
    return '${p.branch.toUpperCase()} : ${p.area.toUpperCase()} — VALET ATTENDANT';
  }

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

  /// Persists branch/area/ids from `POST /devices/validate` when assignment changed.
  static Future<void> applyValidateDeviceAssignment(
    SharedPreferences prefs, {
    required String branchName,
    required String areaName,
    required String branchId,
    required String areaId,
  }) async {
    final b = SiteDisplayName.sanitizeStored(branchName);
    final a = SiteDisplayName.sanitizeStored(areaName);
    final bid = branchId.trim();
    final aid = areaId.trim();
    if (b.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranch, b);
    } else {
      await prefs.remove(PrefsKeys.deviceBranch);
    }
    if (a.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceArea, a);
    } else {
      await prefs.remove(PrefsKeys.deviceArea);
    }
    if (bid.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranchId, bid);
    } else {
      await prefs.remove(PrefsKeys.deviceBranchId);
    }
    if (aid.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceAreaId, aid);
    } else {
      await prefs.remove(PrefsKeys.deviceAreaId);
    }
  }

  /// Persists branch/area from register response; clears keys when the API omits or returns empty strings.
  static Future<void> applyRegisterResponse(
    SharedPreferences prefs, {
    String? branch,
    String? area,
  }) async {
    final b = SiteDisplayName.sanitizeStored(branch);
    if (b.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceBranch, b);
    } else {
      await prefs.remove(PrefsKeys.deviceBranch);
    }
    final a = SiteDisplayName.sanitizeStored(area);
    if (a.isNotEmpty) {
      await prefs.setString(PrefsKeys.deviceArea, a);
    } else {
      await prefs.remove(PrefsKeys.deviceArea);
    }
  }
}
