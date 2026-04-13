import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Small wrapper so Cubits do not depend on widget-layer connectivity code.
abstract final class InternetReachability {
  /// Whether the device can reach the public internet (short timeout).
  static Future<bool> hasInternet() async {
    try {
      return await InternetConnection()
          .hasInternetAccess
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }
}
