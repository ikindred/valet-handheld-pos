import '../local/db/app_database.dart';
import '../../core/sync/local_sync_notifier.dart';
import 'debug_clear_transactions_result.dart';

/// Release/profile stub — clear-local-transactions is not available.
class DebugLocalDataService {
  DebugLocalDataService(
    this._db, {
    LocalSyncNotifier? localSyncNotifier,
  });

  final AppDatabase _db;

  Future<DebugClearTransactionsResult> clearLocalTransactions() async {
    return const DebugClearTransactionsResult(
      deletedTickets: 0,
      deletedQueueRows: 0,
    );
  }
}
