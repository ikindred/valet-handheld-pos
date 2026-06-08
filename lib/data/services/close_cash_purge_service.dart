import 'package:drift/drift.dart';

import '../local/db/app_database.dart';

/// Counts of rows removed during [CloseCashPurgeService.purgeAfterCloseCash].
class CloseCashPurgeResult {
  const CloseCashPurgeResult({
    required this.deletedTickets,
    required this.deletedQueueRows,
    required this.deletedShifts,
    required this.deletedSessions,
  });

  final int deletedTickets;
  final int deletedQueueRows;
  final int deletedShifts;
  final int deletedSessions;

  int get totalDeleted =>
      deletedTickets + deletedQueueRows + deletedShifts + deletedSessions;
}

/// Removes synced checkout history and closed shifts after close-cash.
///
/// Preserves: device tables, offline accounts, active check-in tickets,
/// rates, branch_config, parking_area_layouts.
class CloseCashPurgeService {
  CloseCashPurgeService(this._db);

  final AppDatabase _db;

  /// Purges local checkout data after a successful close-cash + sync flush.
  Future<CloseCashPurgeResult> purgeAfterCloseCash({String? closedShiftId}) async {
    return _db.transaction(() async {
      final deletedTickets = await _db.customUpdate(
        '''
DELETE FROM tickets
WHERE status = 'draft'
   OR (status IN ('completed', 'lost', 'void') AND sync_status = 'synced')
''',
        updates: {_db.tickets},
      );

      final deletedQueueRows = await _db.customUpdate(
        '''
DELETE FROM sync_queue
WHERE sync_status IN ('synced', 'failed')
   OR record_id NOT IN (SELECT id FROM tickets)
   OR (table_name = 'shifts' AND record_id NOT IN (SELECT id FROM shifts))
''',
        updates: {_db.syncQueue},
      );

      final deletedShifts = await _db.customUpdate(
        '''
DELETE FROM shifts
WHERE status = 'closed'
  AND sync_status = 'synced'
  AND id NOT IN (SELECT shift_id FROM tickets WHERE status = 'active')
''',
        updates: {_db.shifts},
      );

      return CloseCashPurgeResult(
        deletedTickets: deletedTickets,
        deletedQueueRows: deletedQueueRows,
        deletedShifts: deletedShifts,
        deletedSessions: 0,
      );
    });
  }

  /// Removes ended session rows (call after [AuthRepository.confirmCloseCash]).
  Future<int> purgeEndedSessions() {
    return _db.customUpdate(
      '''
DELETE FROM sessions
WHERE is_active = 0
''',
      updates: {_db.sessions},
    );
  }

  /// Non-draft tickets for [userId] still marked pending sync (check-ins + checkouts).
  Future<int> countPendingSyncTicketsForUser(String userId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE user_id = ? AND sync_status = 'pending' AND status != 'draft'
''',
      variables: [Variable<String>(userId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }
}
