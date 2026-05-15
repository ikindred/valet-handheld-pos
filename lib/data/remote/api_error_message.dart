import 'dart:convert';

import 'package:dio/dio.dart';

/// Thrown when online login fails (HTTP error from [AuthApi.login]).
class LoginApiFailure implements Exception {
  LoginApiFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// User-facing text from API JSON (`message`, `detail`, `error`) or plain body.
String? messageFromResponseData(dynamic data) {
  if (data == null) return null;

  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return messageFromResponseData(jsonDecode(trimmed));
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['message', 'detail', 'error', 'title']) {
      final raw = map[key];
      if (raw == null) continue;
      if (raw is String) {
        final t = raw.trim();
        if (t.isNotEmpty) return t;
      }
      if (raw is List) {
        final parts = raw
            .map((x) => x.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) return parts.join('\n');
      }
    }
  }

  return null;
}

/// Best-effort user-facing text from a failed Dio call (Nest-style bodies).
String? parseApiErrorUserMessage(DioException e) {
  final fromBody = messageFromResponseData(e.response?.data);
  if (fromBody != null && fromBody.isNotEmpty) return fromBody;

  final msg = e.message?.trim();
  if (msg != null && msg.isNotEmpty) return msg;
  return null;
}

/// Message to show on the login screen for any login failure.
String loginErrorMessage(Object error) {
  if (error is LoginApiFailure) return error.message;
  if (error is DioException) {
    return parseApiErrorUserMessage(error) ??
        'Login failed. Please try again.';
  }
  if (error is StateError) {
    if (error.message == 'DEVICE_NOT_ASSIGNED') {
      return 'This device is not yet assigned to a branch and area.';
    }
  }
  return 'Login failed. Check your credentials and try again.';
}
