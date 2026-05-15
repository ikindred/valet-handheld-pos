import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/logging/valet_log.dart';

const _dioLogScope = 'Dio';
const _maxLogChars = 6000;

String _truncate(String s, [int max = _maxLogChars]) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…(+${s.length - max} chars)';
}

String _fmtBody(dynamic data) {
  if (data == null) return 'null';
  try {
    if (data is Map || data is List) {
      return _truncate(jsonEncode(data));
    }
    if (data is FormData) {
      return 'FormData(fields: ${data.fields.length}, files: ${data.files.length})';
    }
    return _truncate(data.toString());
  } catch (_) {
    return _truncate(data.toString());
  }
}

Map<String, dynamic> _headersForLog(Map<String, dynamic> headers) {
  final out = <String, dynamic>{};
  for (final e in headers.entries) {
    final key = e.key;
    if (key.toLowerCase() == 'authorization') {
      out[key] = '(redacted)';
    } else {
      out[key] = e.value;
    }
  }
  return out;
}

/// HTTP client. Request URLs are resolved via [AppConfig] (absolute URLs per call).
Dio createAppDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        ValetLog.debug(
          _dioLogScope,
          '→ ${options.method} ${options.uri} | '
          'headers: ${_truncate(_headersForLog(options.headers).toString(), 1200)} | '
          'data: ${_fmtBody(options.data)}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        ValetLog.debug(
          _dioLogScope,
          '← ${response.statusCode} ${response.requestOptions.uri} | '
          'data: ${_fmtBody(response.data)}',
        );
        handler.next(response);
      },
      onError: (err, handler) {
        final res = err.response;
        ValetLog.error(
          _dioLogScope,
          '✗ ${err.requestOptions.method} ${err.requestOptions.uri} | '
          'status: ${res?.statusCode} | message: ${err.message} | '
          'response: ${_fmtBody(res?.data)}',
          err,
          err.stackTrace,
        );
        handler.next(err);
      },
    ),
  );

  return dio;
}
