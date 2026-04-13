import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
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

  /// POST [AppConfig.authLogin]
  Future<LoginResponse> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    if (AppConfig.useStubApi) {
      final uid = email.hashCode.abs();
      return LoginResponse(
        token: 'stub_jwt_$uid',
        userId: uid == 0 ? 1 : uid,
        fullName: 'Stub User',
        role: 'staff',
        isOpenCash: false,
        standardRates: const StandardParkingRates(
          flatRatePesos: 150,
          succeedingHourPesos: 30,
          overnightFeePesos: 200,
          lostTicketFeePesos: 200,
        ),
      );
    }
    final res = await _dio.post<Map<String, dynamic>>(
      AppConfig.authLogin,
      data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
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
        userId: 1,
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

int _parseUserId(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return 0;
  return int.tryParse(s) ?? 0;
}

class LoginResponse {
  LoginResponse({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.isOpenCash,
    this.standardRates,
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
    int userId = _parseUserId(json['user_id'] ?? json['userId']);
    var fullName = '';
    var role = '';
    if (user is Map<String, dynamic>) {
      userId = _parseUserId(user['id'] ?? user['user_id']);
      fullName = (user['full_name'] ?? user['fullName'] ?? '').toString();
      role = (user['role'] ?? '').toString();
    }

    return LoginResponse(
      token: (json['token'] ?? json['access_token'] ?? '').toString(),
      userId: userId,
      fullName: fullName,
      role: role,
      isOpenCash: isOpen,
      standardRates: rates,
    );
  }

  final String token;

  /// Canonical server user id (INTEGER).
  final int userId;

  final String fullName;

  final String role;

  final bool isOpenCash;
  final StandardParkingRates? standardRates;
}

class RevalidateResponse {
  RevalidateResponse({
    required this.token,
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
    int userId = _parseUserId(json['user_id'] ?? json['userId']);
    if (user is Map<String, dynamic>) {
      userId = _parseUserId(user['id'] ?? user['user_id']);
    }

    return RevalidateResponse(
      token: (json['token'] ?? json['access_token'] ?? '').toString(),
      userId: userId,
      valid: valid,
      isOpenCash: isOpen,
      standardRates: rates,
    );
  }

  final String token;
  final int userId;
  final bool valid;
  final bool isOpenCash;
  final StandardParkingRates? standardRates;
}
