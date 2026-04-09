import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valet_handheld_pos/core/routing/router_refresh_notifier.dart';
import 'package:valet_handheld_pos/core/storage/prefs_keys.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/auth_api.dart';
import 'package:valet_handheld_pos/data/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late AppDatabase db;
    late AuthRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        PrefsKeys.deviceId: 'dev-1',
      });
      db = AppDatabase.memory();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.into(db.deviceInfo).insert(
            DeviceInfoCompanion.insert(
              deviceId: 'dev-1',
              branch: const Value('Test Branch'),
              area: const Value('Area 1'),
              registeredAt: now,
            ),
          );
      final api = AuthApi(Dio());
      final refresh = RouterRefreshNotifier();
      repo = AuthRepository(db, api, refresh);
    });

    tearDown(() async {
      await db.close();
    });

    test('loginOnline creates active session and offline account row', () async {
      await repo.loginOnline(
        email: 'a@test.com',
        password: 'secret',
        deviceId: 'dev-1',
      );
      final s = await repo.getActiveSession();
      expect(s, isNotNull);
      expect(s!.isActive, true);
      expect(s.authToken, isNotEmpty);
      final acct = await repo.offlineAccountById(s.userId);
      expect(acct, isNotNull);
      expect(acct!.email, 'a@test.com');
    });

    test('logoutOnly sets is_active, logout_at, and clears auth token', () async {
      await repo.loginOnline(
        email: 'b@test.com',
        password: 'secret',
        deviceId: 'dev-1',
      );
      await repo.logoutOnly(deviceId: 'dev-1');
      expect(await repo.getActiveSession(), isNull);
      final rows = await db.select(db.sessions).get();
      expect(rows.length, 1);
      expect(rows.single.isActive, false);
      expect(rows.single.logoutAt, isNotNull);
      expect(rows.single.authToken, isNull);
    });

    test('confirmCloseCash closes shift with reconciliation and session', () async {
      await repo.loginOnline(
        email: 'c@test.com',
        password: 'secret',
        deviceId: 'dev-1',
      );
      final session = await repo.getActiveSession();
      expect(session, isNotNull);
      await repo.recordOpenCash(
        localUserId: session!.userId,
        sessionId: session.id,
        openingFloat: 100,
      );
      final openBefore = await (db.select(db.shifts)
            ..where((sh) => sh.isOpen.equals(true)))
          .get();
      expect(openBefore, isNotEmpty);

      await repo.confirmCloseCash(
        localUserId: session.userId,
        closingFloat: 100,
        totalSales: 0,
        expectedCash: 100,
        variance: 0,
        remittance: 100,
        transactionsCount: 0,
      );

      final openAfter = await (db.select(db.shifts)
            ..where((sh) => sh.isOpen.equals(true)))
          .get();
      expect(openAfter, isEmpty);
      expect(await repo.getActiveSession(), isNull);

      final shifts = await db.select(db.shifts).get();
      final closed = shifts.single;
      expect(closed.isOpen, false);
      expect(closed.expectedCash, 100.0);
      expect(closed.variance, 0.0);
      expect(closed.remittance, 100.0);
      expect(closed.totalSales, 0.0);
      expect(closed.transactionsCount, 0);
    });

    test('loginOffline fails when no offline account', () async {
      expect(
        () => repo.loginOffline(email: 'x@test.com', password: 'p'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
