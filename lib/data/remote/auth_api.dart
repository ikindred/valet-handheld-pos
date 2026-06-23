import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/session/cashier_shift_schedule.dart';
import '../../core/session/standard_parking_rates.dart';

/// Remote auth + device registration. Uses stubs when [AppConfig.useStubApi] is true.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// POST [AppConfig.deviceRegister] — body includes [branch] and [area].
  Future<DeviceRegisterResult> registerDevice({
    required String deviceId,
    Map<String, dynamic>? deviceInfo,
    required String branch,
    required String area,
  }) async {
    final model = deviceInfo?['model']?.toString() ??
        deviceInfo?['manufacturer']?.toString() ??
        'unknown';
    final osVersion = deviceInfo?['system_version']?.toString() ??
        deviceInfo?['sdk_int']?.toString() ??
        deviceInfo?['os']?.toString() ??
        '';
    if (AppConfig.useStubApi) {
      return DeviceRegisterResult(
        success: true,
        branch: branch,
        area: area,
      );
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        AppConfig.deviceRegister,
        data: {
          'device_id': deviceId,
          'device_model': model,
          'os_version': osVersion,
          'branch': branch,
          'area': area,
        },
      );
      return DeviceRegisterResult.fromJson(res.data ?? {});
    } catch (_) {
      return const DeviceRegisterResult(success: false);
    }
  }

  /// POST [AppConfig.authLogin] — body: `email`, `password`, `server_device_id` (no legacy `device_id`).
  Future<LoginResponse> login({
    required String email,
    required String password,
    String? serverDeviceId,
  }) async {
    if (AppConfig.useStubApi) {
      final uid = email.hashCode.abs();
      final sid = uid == 0 ? '1' : 'stub-$uid';
      return LoginResponse(
        token: 'stub_jwt_$uid',
        userId: sid,
        fullName: 'Stub User',
        role: 'staff',
        isOpenCash: false,
        expressCashier: false,
        shiftSchedule: const [],
        standardRates: const StandardParkingRates(
          flatRatePesos: 150,
          succeedingHourPesos: 30,
          overnightFeePesos: 200,
          lostTicketFeePesos: 200,
        ),
      );
    }
    final sid = serverDeviceId?.trim();
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.authLogin,
      data: {
        'email': email,
        'password': password,
        'server_device_id': (sid == null || sid.isEmpty) ? null : sid,
      },
    );
    final data = res.data ?? {};
    return LoginResponse.fromJson(data);
  }

  /// POST [AppConfig.authValidateToken] — `Authorization: Bearer <token>`.
  Future<RevalidateResponse> revalidateToken({
    required String token,
    required String deviceId,
  }) async {
    if (AppConfig.useStubApi) {
      return RevalidateResponse(
        token: token,
        userId: 'stub-1',
        valid: true,
        isOpenCash: false,
        standardRates: StandardParkingRates.fromLoginResponseJson(const {
          'standard_rates': {
            'flat_rate': 150,
            'succeeding_hour': 30,
            'overnight_fee': 200,
            'lost_ticket_fee': 200,
          },
        }),
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.authValidateToken,
      data: {'device_id': deviceId},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final data = res.data ?? {};
    return RevalidateResponse.fromJson(data);
  }

  /// POST [AppConfig.devicesValidateUrl] — `Authorization: Bearer <token>`,
  /// body `{ "server_device_id": "<uuid>" }`.
  Future<DeviceValidateResponse> validateDevice({
    required String token,
    required String serverDeviceId,
  }) async {
    if (AppConfig.useStubApi) {
      return const DeviceValidateResponse(valid: true);
    }
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.devicesValidateUrl,
      data: <String, dynamic>{'server_device_id': serverDeviceId},
      options: Options(
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );
    return DeviceValidateResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// POST [AppConfig.authLogout] — fire-and-forget; swallow errors.
  Future<void> logout({
    required String token,
    required String deviceId,
  }) async {
    if (AppConfig.useStubApi) return;
    try {
      await _dio.post<Map<String, dynamic>>(
        AppConfig.authLogout,
        data: {'device_id': deviceId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (_) {}
  }
}

/// Parsed body from `POST /api/v1/devices/validate`.
class DeviceValidateResponse {
  const DeviceValidateResponse({
    required this.valid,
    this.reason,
    this.device,
  });

  factory DeviceValidateResponse.fromJson(Map<String, dynamic> json) {
    var valid = true;
    if (json.containsKey('valid')) {
      final v = json['valid'];
      if (v is bool) {
        valid = v;
      } else if (v != null) {
        valid =
            v.toString().toLowerCase() == 'true' || v.toString().trim() == '1';
      }
    }
    final reason = json['reason']?.toString().trim();
    final raw = json['device'];
    DeviceValidateDevicePayload? device;
    if (raw is Map<String, dynamic>) {
      device = DeviceValidateDevicePayload.fromJson(raw);
    } else if (raw is Map) {
      device = DeviceValidateDevicePayload.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
    return DeviceValidateResponse(
      valid: valid,
      reason: reason != null && reason.isEmpty ? null : reason,
      device: device,
    );
  }

  final bool valid;
  final String? reason;
  final DeviceValidateDevicePayload? device;
}

class DeviceValidateDevicePayload {
  const DeviceValidateDevicePayload({
    required this.branchId,
    required this.branchName,
    required this.areaId,
    required this.areaName,
  });

  factory DeviceValidateDevicePayload.fromJson(Map<String, dynamic> json) {
    String s(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return '';
      final t = v.toString().trim();
      return t;
    }

    return DeviceValidateDevicePayload(
      branchId: s('branchId', 'branch_id'),
      branchName: s('branchName', 'branch_name'),
      areaId: s('areaId', 'area_id'),
      areaName: s('areaName', 'area_name'),
    );
  }

  final String branchId;
  final String branchName;
  final String areaId;
  final String areaName;
}

class DeviceRegisterResult {
  const DeviceRegisterResult({
    required this.success,
    this.branch,
    this.area,
  });

  factory DeviceRegisterResult.fromJson(Map<String, dynamic> json) {
    final ok = json['success'] == true ||
        json['success']?.toString().toLowerCase() == 'true';
    String? s(dynamic k) {
      final v = json[k];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return DeviceRegisterResult(
      success: ok,
      branch: s('branch'),
      area: s('area'),
    );
  }

  final bool success;
  final String? branch;
  final String? area;
}

/// JWT from auth responses — prefer [accessToken] (current API), then legacy keys.
String _parseAccessToken(Map<String, dynamic> json) {
  final v = json['accessToken'] ??
      json['access_token'] ??
      json['token'] ??
      '';
  return v.toString().trim();
}

/// Rotated JWT from validate-token; null when the server omits a new token.
String? _parseRotatedAccessToken(Map<String, dynamic> json) {
  final t = _parseAccessToken(json);
  return t.isEmpty ? null : t;
}

/// Server user id from nested `user` or top-level keys; UUID string when present.
String _parseServerUserId(Map<String, dynamic> json) {
  final user = json['user'];
  if (user is Map<String, dynamic>) {
    final v = user['id'] ?? user['user_id'] ?? user['userId'];
    if (v != null) return v.toString().trim();
  }
  final v = json['user_id'] ?? json['userId'];
  return v?.toString().trim() ?? '';
}

String _fullNameFromUser(Map<String, dynamic> user) {
  final direct = (user['full_name'] ?? user['fullName'])?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;
  final a = (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
  final b = (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
  if (a.isEmpty && b.isEmpty) return '';
  return '$a $b'.trim();
}

List<ShiftScheduleEntry> _parseShiftScheduleFromLoginJson(
  Map<String, dynamic> json,
) {
  final user = json['user'];
  if (user is Map<String, dynamic>) {
    return CashierShiftSchedule.parseList(user['shiftSchedule']);
  }
  return CashierShiftSchedule.parseList(json['shiftSchedule']);
}

/// Branch/area from login `user` object (UUIDs for API paths, names for UI).
class LoginUserSite {
  const LoginUserSite({
    required this.branchId,
    required this.areaId,
    required this.branchName,
    required this.areaName,
  });

  final String branchId;
  final String areaId;
  final String branchName;
  final String areaName;

  static LoginUserSite? fromUserJson(Map<String, dynamic>? user) {
    if (user == null) return null;
    final branch = user['branch'];
    final area = user['area'];
    return LoginUserSite(
      branchId: _idFromNested(branch),
      areaId: _idFromNested(area),
      branchName: _nameFromNested(branch),
      areaName: _nameFromNested(area),
    );
  }

  static String _idFromNested(dynamic node) {
    if (node is Map) {
      return (node['id'] ?? node['branch_id'] ?? node['area_id'] ?? '')
          .toString()
          .trim();
    }
    return '';
  }

  static String _nameFromNested(dynamic node) {
    if (node is Map) {
      return (node['name'] ?? node['code'] ?? '').toString().trim();
    }
    return '';
  }
}

class LoginResponse {
  LoginResponse({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.isOpenCash,
    required this.expressCashier,
    required this.shiftSchedule,
    this.standardRates,
    this.userSite,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rates = StandardParkingRates.fromLoginResponseJson(json);
    final open = json['is_open_cash'] ?? json['isOpenCash'];
    var isOpen = false;
    if (open is bool) {
      isOpen = open;
    } else if (open != null) {
      isOpen = open.toString() == '1' || open.toString().toLowerCase() == 'true';
    }

    final user = json['user'];
    var fullName = '';
    var role = '';
    var userId = _parseServerUserId(json);
    var expressCashier = false;
    LoginUserSite? userSite;
    if (user is Map<String, dynamic>) {
      userId = _parseServerUserId({'user': user});
      fullName = _fullNameFromUser(user);
      role = (user['role'] ?? '').toString();
      userSite = LoginUserSite.fromUserJson(user);
      final express = user['express_cashier'] ?? user['expressCashier'];
      if (express is bool) {
        expressCashier = express;
      } else if (express != null) {
        expressCashier =
            express.toString() == '1' || express.toString().toLowerCase() == 'true';
      }
    }

    return LoginResponse(
      token: _parseAccessToken(json),
      userId: userId,
      fullName: fullName,
      role: role,
      isOpenCash: isOpen,
      expressCashier: expressCashier,
      shiftSchedule: _parseShiftScheduleFromLoginJson(json),
      standardRates: rates,
      userSite: userSite,
    );
  }

  /// JWT from `accessToken` (stored in session as bearer token).
  final String token;

  /// Server user id (UUID when returned by API).
  final String userId;

  final String fullName;

  final String role;

  final bool isOpenCash;

  /// From login `user.express_cashier` — manual ticketing mode.
  final bool expressCashier;

  final List<ShiftScheduleEntry> shiftSchedule;

  final StandardParkingRates? standardRates;

  final LoginUserSite? userSite;
}

class RevalidateResponse {
  RevalidateResponse({
    this.token,
    required this.userId,
    required this.valid,
    required this.isOpenCash,
    this.standardRates,
  });

  factory RevalidateResponse.fromJson(Map<String, dynamic> json) {
    final rates = StandardParkingRates.fromLoginResponseJson(json);
    final open = json['is_open_cash'] ?? json['isOpenCash'];
    var isOpen = false;
    if (open is bool) {
      isOpen = open;
    } else if (open != null) {
      isOpen = open.toString() == '1' || open.toString().toLowerCase() == 'true';
    }

    var valid = true;
    if (json.containsKey('valid')) {
      final v = json['valid'];
      if (v is bool) {
        valid = v;
      } else if (v != null) {
        valid = v.toString().toLowerCase() == 'true' || v.toString() == '1';
      }
    }

    final user = json['user'];
    var userId = _parseServerUserId(json);
    if (user is Map<String, dynamic>) {
      userId = _parseServerUserId({'user': user});
    }

    return RevalidateResponse(
      token: _parseRotatedAccessToken(json),
      userId: userId,
      valid: valid,
      isOpenCash: isOpen,
      standardRates: rates,
    );
  }

  /// New JWT when the server rotates the token; null means keep the existing session token.
  final String? token;

  final String userId;

  final bool valid;
  final bool isOpenCash;
  final StandardParkingRates? standardRates;
}
