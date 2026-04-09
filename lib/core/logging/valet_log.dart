import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Debug-oriented logging with a stable prefix and scoped identifiers.
///
/// Format: `valet_log-[scope]: message` where [scope] is a page or function label.
abstract final class ValetLog {
  ValetLog._();

  static const String _name = 'valet_log';

  static String _line(String scope, String message) =>
      'valet_log-[$scope]: $message';

  /// Routine activity (debug builds only).
  static void d(String scope, String message) {
    if (!kDebugMode) return;
    developer.log(_line(scope, message), name: _name);
  }

  /// Failures and exceptions (debug builds only).
  static void e(
    String scope,
    String message,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    developer.log(
      _line(scope, message),
      name: _name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
