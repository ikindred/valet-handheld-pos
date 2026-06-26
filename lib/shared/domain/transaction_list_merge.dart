import '../../features/reports/domain/reports_models.dart';

/// Merges local Drift rows with server lists without duplicates.
abstract final class TransactionListMerge {
  static bool _normEq(String? a, String? b) {
    final x = a?.trim().toLowerCase() ?? '';
    final y = b?.trim().toLowerCase() ?? '';
    return x.isNotEmpty && x == y;
  }

  static bool reportsRowsMatch(ReportsTicketRow local, ReportsTicketRow server) {
    if (_normEq(local.ticketId, server.ticketId)) return true;
    if (_normEq(local.ticketId, server.serverTransactionId)) return true;
    if (_normEq(local.serverTransactionId, server.serverTransactionId)) {
      return true;
    }
    if (_normEq(local.serverTransactionId, server.ticketId)) return true;
    return false;
  }

  /// Prepends unsynced local rows that are not already on [server].
  static List<ReportsTicketRow> mergeReportsRows({
    required List<ReportsTicketRow> server,
    required List<ReportsTicketRow> local,
  }) {
    final extras = <ReportsTicketRow>[];
    for (final row in local) {
      if (row.isSynced) continue;
      if (server.any((s) => reportsRowsMatch(row, s))) continue;
      extras.add(row);
    }
    final merged = [...extras, ...server];
    merged.sort((a, b) => b.timeIn.compareTo(a.timeIn));
    return merged;
  }
}
