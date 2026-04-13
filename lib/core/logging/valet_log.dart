import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Structured app logging with scoped identifiers.
///
/// Format: `valet_log-[scope]: message` where [scope] is a page or function label.
abstract final class ValetLog {
  ValetLog._();

  static final Logger _logger = Logger(
    level: kDebugMode ? Level.trace : Level.off,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: false,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static String _line(String scope, String message) =>
      'valet_log-[$scope]: $message';

  static void trace(String scope, String message) {
    _logger.t(_line(scope, message));
  }

  static void debug(String scope, String message) {
    _logger.d(_line(scope, message));
  }

  static void info(String scope, String message) {
    _logger.i(_line(scope, message));
  }

  static void warning(String scope, String message) {
    _logger.w(_line(scope, message));
  }

  static void error(
    String scope,
    String message,
    Object err, [
    StackTrace? stackTrace,
  ]) {
    _logger.e(_line(scope, message), error: err, stackTrace: stackTrace);
  }

}
