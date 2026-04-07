import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] (via [GoRouter.refreshListenable]) when auth/session/shift
/// persistence changes so redirects re-run.
class RouterRefreshNotifier extends ChangeNotifier {
  void notifyAuthChanged() => notifyListeners();
}
