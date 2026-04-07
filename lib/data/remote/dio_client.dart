import 'package:dio/dio.dart';

/// HTTP client. Request URLs are resolved via [AppConfig] (absolute URLs per call).
Dio createAppDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
