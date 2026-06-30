import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_format.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_models.dart';
import 'package:valet_handheld_pos/shared/domain/transaction_list_merge.dart';

void main() {
  group('TransactionListMerge.mergeReportsRows', () {
    final serverRow = ReportsTicketRow(
      ticketId: 'TKT-260626-AAAA',
      serverTransactionId: 'uuid-server-1',
      plate: 'ABC1234',
      vehicle: 'Toyota Vios · White',
      timeIn: DateTime(2026, 6, 26, 9, 0),
      duration: const Duration(minutes: 5),
      slot: 'L01',
      status: ReportsTicketRowStatus.parked,
      isSynced: true,
    );

  test('adds unsynced local row missing from server', () {
      final localRow = ReportsTicketRow(
        ticketId: 'TKT-260626-BBBB',
        plate: 'XYZ9999',
        vehicle: 'Honda City · Black',
        timeIn: DateTime(2026, 6, 26, 9, 10),
        duration: const Duration(minutes: 1),
        slot: 'L02',
        status: ReportsTicketRowStatus.parked,
        isSynced: false,
      );

      final merged = TransactionListMerge.mergeReportsRows(
        server: [serverRow],
        local: [localRow],
      );

      expect(merged, hasLength(2));
      expect(merged.first.ticketId, 'TKT-260626-BBBB');
      expect(merged.last.ticketId, 'TKT-260626-AAAA');
    });

      test('skips synced local rows and server duplicates', () {
      final syncedLocal = ReportsTicketRow(
        ticketId: 'TKT-260626-AAAA',
        serverTransactionId: 'uuid-server-1',
        plate: 'ABC1234',
        vehicle: 'Toyota Vios · White',
        timeIn: DateTime(2026, 6, 26, 9, 0),
        duration: const Duration(minutes: 5),
        slot: 'L01',
        status: ReportsTicketRowStatus.parked,
        isSynced: true,
      );
      final pendingDuplicate = ReportsTicketRow(
        ticketId: 'TKT-260626-AAAA',
        plate: 'ABC1234',
        vehicle: 'Toyota Vios · White',
        timeIn: DateTime(2026, 6, 26, 9, 0),
        duration: const Duration(minutes: 5),
        slot: 'L01',
        status: ReportsTicketRowStatus.parked,
        isSynced: false,
      );

      final merged = TransactionListMerge.mergeReportsRows(
        server: [serverRow],
        local: [syncedLocal, pendingDuplicate],
      );

      expect(merged, hasLength(1));
      expect(merged.single.ticketId, 'TKT-260626-AAAA');
    });

    test('prefers local void over active server row', () {
      final voidedLocal = ReportsTicketRow(
        ticketId: 'TKT-260626-AAAA',
        serverTransactionId: 'uuid-server-1',
        plate: 'ABC1234',
        vehicle: 'Toyota Vios · White',
        timeIn: DateTime(2026, 6, 26, 9, 0),
        duration: const Duration(minutes: 5),
        slot: 'L01',
        status: ReportsTicketRowStatus.parked,
        isVoided: true,
        isSynced: false,
      );

      final merged = TransactionListMerge.mergeReportsRows(
        server: [serverRow],
        local: [voidedLocal],
      );

      expect(merged, hasLength(1));
      expect(merged.single.isVoided, isTrue);
      expect(merged.single.ticketId, 'TKT-260626-AAAA');
    });

    test('prefers local checkout over parked server row', () {
      final checkedOutLocal = ReportsTicketRow(
        ticketId: 'TKT-260626-AAAA',
        serverTransactionId: 'uuid-server-1',
        plate: 'ABC1234',
        vehicle: 'Toyota Vios · White',
        timeIn: DateTime(2026, 6, 26, 9, 0),
        timeOut: DateTime(2026, 6, 26, 10, 0),
        duration: const Duration(hours: 1),
        slot: 'L01',
        status: ReportsTicketRowStatus.checkedOut,
        isSynced: false,
      );

      final merged = TransactionListMerge.mergeReportsRows(
        server: [serverRow],
        local: [checkedOutLocal],
      );

      expect(merged, hasLength(1));
      expect(merged.single.status, ReportsTicketRowStatus.checkedOut);
    });
  });
}
