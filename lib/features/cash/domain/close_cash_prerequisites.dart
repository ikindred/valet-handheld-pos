/// Pre-close validation for close-cash (internet, online mode, full sync).
abstract final class CloseCashPrerequisites {
  static Future<String?> blockingReason({
    required String shiftId,
    required Future<bool> Function() hasInternet,
    required Future<bool> Function() offlineModeEnabled,
    required Future<bool> Function() offlineSession,
    required Future<void> Function() flushSync,
    required Future<int> Function() pendingSyncCount,
    required Future<int> Function() failedSyncCount,
    required Future<int> Function(String userId) pendingTicketSyncCount,
    required String cashierUserId,
    bool flushBeforeCheck = true,
  }) async {
    if (!await hasInternet()) {
      return 'Connect to the internet and sync all transactions before closing cash.';
    }
    if (await offlineModeEnabled() || await offlineSession()) {
      return 'Close cash is not available in offline mode. Connect online and try again.';
    }
    if (flushBeforeCheck) {
      await flushSync();
    }
    final pending = await pendingSyncCount();
    if (pending > 0) {
      return 'Sync $pending pending transaction${pending == 1 ? '' : 's'} before closing cash.';
    }
    final failed = await failedSyncCount();
    if (failed > 0) {
      return 'Resolve $failed failed sync item${failed == 1 ? '' : 's'} before closing cash.';
    }
    final ticketPending = await pendingTicketSyncCount(cashierUserId);
    if (ticketPending > 0) {
      return 'Sync $ticketPending unsynced check-in or checkout'
          '${ticketPending == 1 ? '' : 's'} before closing cash.';
    }
    return null;
  }
}
