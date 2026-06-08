import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/cash/domain/close_cash_prerequisites.dart';

void main() {
  const shiftId = 'shift-1';
  const cashierUserId = 'user-1';

  group('CloseCashPrerequisites', () {
    test('blocks when offline from internet', () async {
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => false,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {},
        pendingSyncCount: () async => 0,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
        flushBeforeCheck: false,
      );

      expect(reason, contains('internet'));
    });

    test('blocks when offline mode pref is set', () async {
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => true,
        offlineSession: () async => false,
        flushSync: () async {},
        pendingSyncCount: () async => 0,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
        flushBeforeCheck: false,
      );

      expect(reason, contains('offline mode'));
    });

    test('blocks when sync queue has pending items', () async {
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {},
        pendingSyncCount: () async => 2,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
        flushBeforeCheck: false,
      );

      expect(reason, contains('2 pending'));
    });

    test('blocks when sync queue has failed items', () async {
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {},
        pendingSyncCount: () async => 0,
        failedSyncCount: () async => 1,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
        flushBeforeCheck: false,
      );

      expect(reason, contains('failed'));
    });

    test('blocks when tickets still pending sync', () async {
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {},
        pendingSyncCount: () async => 0,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 3,
        cashierUserId: cashierUserId,
        flushBeforeCheck: false,
      );

      expect(reason, contains('3 unsynced check-in or checkout'));
    });

    test('returns null when all prerequisites pass', () async {
      var flushed = false;
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {
          flushed = true;
        },
        pendingSyncCount: () async => 0,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
      );

      expect(reason, isNull);
      expect(flushed, isTrue);
    });

    test('allows close after flush reconciles orphan pending queue entry', () async {
      var pending = 1;
      final reason = await CloseCashPrerequisites.blockingReason(
        shiftId: shiftId,
        hasInternet: () async => true,
        offlineModeEnabled: () async => false,
        offlineSession: () async => false,
        flushSync: () async {
          pending = 0;
        },
        pendingSyncCount: () async => pending,
        failedSyncCount: () async => 0,
        pendingTicketSyncCount: (_) async => 0,
        cashierUserId: cashierUserId,
      );

      expect(reason, isNull);
      expect(pending, 0);
    });
  });
}
