import 'package:flutter/foundation.dart';

/// Notifies UI (e.g. header sync pill) when local tickets or sync_queue change.
class LocalSyncNotifier extends ChangeNotifier {
  void notifyLocalQueueChanged() => notifyListeners();
}
