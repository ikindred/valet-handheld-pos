import '../../features/reports/domain/reports_format.dart';
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

  /// True when a local row should replace the matching server row (offline edits).
  static bool localOverridesServer(
    ReportsTicketRow local,
    ReportsTicketRow server,
  ) {
    if (local.isVoided && !server.isVoided) return true;
    if (local.hasPendingVoid && !server.isVoided) return true;
    if (local.status == ReportsTicketRowStatus.checkedOut &&
        server.status == ReportsTicketRowStatus.parked) {
      return true;
    }
    return false;
  }

  /// Merges local Drift rows with server lists; offline mutations win on conflict.
  static List<ReportsTicketRow> mergeReportsRows({
    required List<ReportsTicketRow> server,
    required List<ReportsTicketRow> local,
  }) {
    final extras = <ReportsTicketRow>[];
    final suppressServerKeys = <String>{};

    for (final row in local) {
      ReportsTicketRow? serverRow;
      for (final s in server) {
        if (reportsRowsMatch(row, s)) {
          serverRow = s;
          break;
        }
      }

      if (serverRow != null && localOverridesServer(row, serverRow)) {
        extras.add(row);
        for (final key in [row.ticketId, row.serverTransactionId]) {
          final trimmed = key?.trim() ?? '';
          if (trimmed.isNotEmpty) suppressServerKeys.add(trimmed);
        }
        continue;
      }

      if (row.isSynced) continue;
      if (serverRow != null) continue;
      extras.add(row);
    }

    bool suppressServer(ReportsTicketRow s) {
      for (final key in suppressServerKeys) {
        if (_normEq(key, s.ticketId) || _normEq(key, s.serverTransactionId)) {
          return true;
        }
      }
      return false;
    }

    final merged = [
      ...extras,
      ...server.where((s) => !suppressServer(s)),
    ];
    merged.sort((a, b) => b.timeIn.compareTo(a.timeIn));
    return merged;
  }
}
