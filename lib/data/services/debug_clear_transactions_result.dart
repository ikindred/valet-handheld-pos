class DebugClearTransactionsResult {
  const DebugClearTransactionsResult({
    required this.deletedTickets,
    required this.deletedQueueRows,
  });

  final int deletedTickets;
  final int deletedQueueRows;

  int get totalDeleted => deletedTickets + deletedQueueRows;
}
