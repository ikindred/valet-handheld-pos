import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:valet_handheld_pos/core/routing/router_refresh_notifier.dart';
import 'package:valet_handheld_pos/core/storage/prefs_keys.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/auth_api.dart';
import 'package:valet_handheld_pos/data/repositories/auth_repository.dart';
import 'package:valet_handheld_pos/data/services/shift_service.dart';

void main() {
  group('AuthRepository', () {
    late AppDatabase db;
    late AuthRepository repo;
    late ShiftService shifts;

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
      shifts = ShiftService(db, Dio(), onShiftMutated: refresh.notifyAuthChanged);
      repo = AuthRepository(db, api, refresh, shifts);
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

    test('confirmCloseCash ends session; shift is closed via ShiftService', () async {
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
      final uid = await shifts.shiftUserIdForLocalAccount(session.userId);
      final openBefore = await shifts.getActiveShift(uid);
      expect(openBefore, isNotNull);

      await shifts.closeActiveShiftForLocalUser(session.userId, 100);

      await repo.confirmCloseCash(
        localUserId: session.userId,
        closingFloat: 100,
        totalSales: 0,
        expectedCash: 100,
        variance: 0,
        remittance: 100,
        transactionsCount: 0,
      );

      expect(await shifts.getActiveShift(uid), isNull);
      expect(await repo.getActiveSession(), isNull);

      final shiftRows = await db.select(db.shifts).get();
      expect(shiftRows, isNotEmpty);
      expect(shiftRows.single.status, 'closed');
      expect(shiftRows.single.closingCash, closeTo(100.0, 0.001));
    });

    test('loginOffline fails when no offline account', () async {
      expect(
        () => repo.loginOffline(email: 'x@test.com', password: 'p'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
