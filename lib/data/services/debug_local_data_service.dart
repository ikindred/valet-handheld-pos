import 'package:flutter/foundation.dart' show kDebugMode;

import '../local/db/app_database.dart';
import '../../core/sync/local_sync_notifier.dart';

class DebugClearTransactionsResult {
  const DebugClearTransactionsResult({
    required this.deletedTickets,
    required this.deletedQueueRows,
  });

  final int deletedTickets;
  final int deletedQueueRows;

  int get totalDeleted => deletedTickets + deletedQueueRows;
}

/// Debug-only helpers for wiping local Drift transaction data.
class DebugLocalDataService {
  DebugLocalDataService(
    this._db, {
    LocalSyncNotifier? localSyncNotifier,
  }) : _localSyncNotifier = localSyncNotifier;

  final AppDatabase _db;
  final LocalSyncNotifier? _localSyncNotifier;

  /// Removes all local tickets and sync queue rows. Debug builds only.
  Future<DebugClearTransactionsResult> clearLocalTransactions() async {
    assert(kDebugMode, 'clearLocalTransactions is debug-only');
    final result = await _db.transaction(() async {
      final deletedQueueRows = await _db.delete(_db.syncQueue).go();
      final deletedTickets = await _db.delete(_db.tickets).go();
      return DebugClearTransactionsResult(
        deletedTickets: deletedTickets,
        deletedQueueRows: deletedQueueRows,
      );
    });
    _localSyncNotifier?.notifyLocalQueueChanged();
    return result;
  }
}
