import 'dart:async';
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/services/device_id_service.dart';
import '../../core/storage/device_site_prefs.dart';
import '../../core/routing/router_refresh_notifier.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../core/time/unix_timestamp.dart';
import '../local/db/app_database.dart';
import '../remote/auth_api.dart';

/// Local persistence rules (Drift ↔ SQL intent):
///
/// **Open cash for a user** — `SELECT * FROM shifts WHERE user_id = ? AND is_open = 1 LIMIT 1`
/// → [shiftRouteForLocalUser], [_syncShiftFromFlag], [recordOpenCash].
///
/// **Active session (this device)** — `SELECT * FROM sessions WHERE is_active = 1 LIMIT 1`
/// → [getActiveSession].
///
/// **Offline login** — `SELECT * FROM offline_accounts WHERE email = ?`
/// → [loginOffline].
///
/// **Token revalidation** — `UPDATE sessions SET last_verified_at = ? WHERE id = ?`
/// (also sets [authToken] when the API returns a rotated token)
/// → [revalidateActiveSession].
///
/// **Logout only** — `UPDATE sessions SET is_active = 0, logout_at = ? WHERE id = ?` (shifts unchanged)
/// → [logoutOnly].
///
/// **Close cash + logout** — close shift row(s), then end session by id
/// → [logoutAfterCloseCash].
class AuthRepository {
  AuthRepository(
    this._db,
    this._api,
    this._refresh,
  );

  final AppDatabase _db;
  final AuthApi _api;
  final RouterRefreshNotifier _refresh;

  /// `SELECT * FROM sessions WHERE is_active = 1 LIMIT 1`
  Future<Session?> getActiveSession() {
    return (_db.select(_db.sessions)
          ..where((s) => s.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// `SELECT * FROM shifts WHERE user_id = ? AND is_open = 1 LIMIT 1`
  Future<String> shiftRouteForLocalUser(int localUserId) async {
    final open = await (_db.select(_db.shifts)
          ..where((sh) =>
              sh.userId.equals(localUserId) & sh.isOpen.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return open != null ? '/dashboard' : '/cash/open';
  }

  Future<OfflineAccount?> offlineAccountById(int localId) {
    return (_db.select(_db.offlineAccounts)
          ..where((a) => a.id.equals(localId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OfflineAccount?> offlineAccountByServerId(int serverUserId) {
    return (_db.select(_db.offlineAccounts)
          ..where((a) => a.serverUserId.equals(serverUserId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<String?> emailForOfflineAccountId(int localId) async {
    final row = await offlineAccountById(localId);
    return row?.email;
  }

  /// Open shift for user, if any.
  Future<Shift?> getOpenShiftForUser(int localUserId) {
    return (_db.select(_db.shifts)
          ..where(
            (sh) =>
                sh.userId.equals(localUserId) & sh.isOpen.equals(true),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// POST device/register; persists [DeviceRegisterResult.branch] / [area] when present.
  Future<DeviceRegisterResult> registerDevice({
    required String deviceId,
    Map<String, dynamic>? deviceInfo,
    required SharedPreferences prefs,
  }) async {
    final branch = DeviceSitePrefs.requestBranch(prefs);
    final area = DeviceSitePrefs.requestArea(prefs);
    final result = await _api.registerDevice(
      deviceId: deviceId,
      deviceInfo: deviceInfo,
      branch: branch,
      area: area,
    );
    if (result.success) {
      await DeviceSitePrefs.applyRegisterResponse(
        prefs,
        branch: result.branch,
        area: result.area,
      );
      final b = (result.branch ?? '').trim();
      final a = (result.area ?? '').trim();
      await _upsertDeviceInfoRow(
        deviceId: deviceId,
        branch: b,
        area: a,
      );
    }
    return result;
  }

  /// Temporary dev: ensures `device_info` exists for [deviceId] (from [DeviceIdService.getOrCreate]) with [AppConfig.devSeedBranch] / [devSeedArea].
  /// No-op when [AppConfig.devSeedDeviceSiteEnabled] is false or in tests ([AppDatabase] with skip seed).
  Future<void> seedDevDeviceSiteIfNeeded(String deviceId) async {
    if (!AppConfig.devSeedDeviceSiteEnabled) return;
    final b = AppConfig.devSeedBranch;
    final a = AppConfig.devSeedArea;
    if (b.isEmpty || a.isEmpty) return;
    await _db.seedDevDeviceInfoIfNeeded(
      deviceId: deviceId,
      branch: b,
      area: a,
    );
  }

  /// Single row keyed by [deviceId]; updated after successful device/register.
  Future<void> _upsertDeviceInfoRow({
    required String deviceId,
    required String branch,
    required String area,
  }) async {
    final now = unixNowSeconds();
    final existing = await (_db.select(_db.deviceInfo)
          ..where((d) => d.deviceId.equals(deviceId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.deviceInfo)..where((d) => d.id.equals(existing.id)))
          .write(
        DeviceInfoCompanion(
          branch: Value(branch),
          area: Value(area),
          registeredAt: Value(now),
        ),
      );
      return;
    }
    await _db.into(_db.deviceInfo).insert(
          DeviceInfoCompanion.insert(
            deviceId: deviceId,
            branch: Value(branch),
            area: Value(area),
            registeredAt: now,
          ),
        );
  }

  /// Branch/area from local `device_info` only (set after a successful `device/register` response).
  Future<({String branch, String area})> branchAndAreaFromDb() async {
    final deviceId = await DeviceIdService.getOrCreate();
    final row = await (_db.select(_db.deviceInfo)
          ..where((d) => d.deviceId.equals(deviceId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return (branch: '', area: '');
    return (branch: row.branch.trim(), area: row.area.trim());
  }

  /// True when both branch and area are non-empty in `device_info` for this device.
  Future<bool> isDeviceSiteConfigured() async {
    final p = await branchAndAreaFromDb();
    return p.branch.isNotEmpty && p.area.isNotEmpty;
  }

  Future<void> requireDeviceSiteAssigned() async {
    if (!await isDeviceSiteConfigured()) {
      throw StateError('DEVICE_NOT_ASSIGNED');
    }
  }

  /// Login footer text and whether online/offline login is allowed.
  Future<({bool canLogin, String footerLine})> loginGateFooter(
    SharedPreferences prefs,
  ) async {
    final ok = await isDeviceSiteConfigured();
    if (!ok) {
      return (
        canLogin: false,
        footerLine:
            'This device is not yet assigned to a branch and area.',
      );
    }
    final p = await branchAndAreaFromDb();
    final b = p.branch.toUpperCase();
    final a = p.area.toUpperCase();
    return (
      canLogin: true,
      footerLine: '$b : $a — VALET ATTENDANT',
    );
  }

  /// `DATE · Branch : Area` for cash/dashboard headers.
  Future<String> dateAndSiteLine(SharedPreferences prefs, String dateLine) async {
    final p = await branchAndAreaFromDb();
    if (p.branch.isEmpty || p.area.isEmpty) {
      return '$dateLine · — : —';
    }
    return '$dateLine · ${p.branch} : ${p.area}';
  }

  Future<int> _upsertOfflineAccount({
    required int serverUserId,
    required String email,
    required String passwordHash,
    required String fullName,
    required String role,
  }) async {
    final now = unixNowSeconds();
    final existing = await offlineAccountByServerId(serverUserId);
    if (existing != null) {
      await (_db.update(_db.offlineAccounts)
            ..where((a) => a.id.equals(existing.id)))
          .write(
        OfflineAccountsCompanion(
          email: Value(email),
          passwordHash: Value(passwordHash),
          fullName: Value(fullName),
          role: Value(role),
          lastOnlineLogin: Value(now),
          updatedAt: Value(now),
        ),
      );
      return existing.id;
    }
    return _db.into(_db.offlineAccounts).insert(
          OfflineAccountsCompanion.insert(
            serverUserId: serverUserId,
            email: email,
            passwordHash: passwordHash,
            fullName: fullName,
            role: role,
            lastOnlineLogin: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<StandardParkingRates?> loginOnline({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    ValetLog.d('AuthRepository.loginOnline', 'begin');
    await requireDeviceSiteAssigned();
    final res = await _api.login(
      email: email,
      password: password,
      deviceId: deviceId,
    );

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final accountId = await _upsertOfflineAccount(
      serverUserId: res.userId,
      email: email,
      passwordHash: hash,
      fullName: res.fullName,
      role: res.role,
    );

    await _db.transaction(() async {
      await _deactivateAllActiveSessions();
      final sid = await _db.into(_db.sessions).insert(
            SessionsCompanion.insert(
              userId: accountId,
              loginAt: unixNowSeconds(),
              isActive: const Value(true),
              authToken: Value(res.token),
              lastVerifiedAt: Value(unixNowSeconds()),
              isOfflineSession: const Value(false),
            ),
          );

      await _syncShiftFromFlag(
        localUserId: accountId,
        sessionId: sid,
        isOpenCash: res.isOpenCash,
      );
    });

    await _flushSyncQueueForActiveSession();
    _refresh.notifyAuthChanged();
    ValetLog.d(
      'AuthRepository.loginOnline',
      'success localUserId=$accountId',
    );
    return res.standardRates;
  }

  /// `SELECT * FROM offline_accounts WHERE email = ?` then verify bcrypt.
  Future<StandardParkingRates?> loginOffline({
    required String email,
    required String password,
  }) async {
    await requireDeviceSiteAssigned();
    final normalizedEmail = email.trim().toLowerCase();
    final row = await (_db.select(_db.offlineAccounts)
          ..where((a) => a.email.equals(normalizedEmail))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      throw StateError('OFFLINE_ACCOUNT_MISSING');
    }
    if (!BCrypt.checkpw(password, row.passwordHash)) {
      throw StateError('BAD_PASSWORD');
    }

    await _db.transaction(() async {
      await _deactivateAllActiveSessions();
      await _db.into(_db.sessions).insert(
            SessionsCompanion.insert(
              userId: row.id,
              loginAt: unixNowSeconds(),
              isActive: const Value(true),
              lastVerifiedAt: Value(unixNowSeconds()),
              isOfflineSession: const Value(true),
            ),
          );
    });

    _refresh.notifyAuthChanged();
    ValetLog.d(
      'AuthRepository.loginOffline',
      'success localUserId=${row.id}',
    );
    return null;
  }

  /// `UPDATE sessions SET last_verified_at = ?, auth_token = ? WHERE id = ?`
  /// (token updated when API returns one).
  ///
  /// Shift state is only synced from the revalidate response when a **real** API
  /// is configured. With [AppConfig.useStubApi] (`API_BASE_URL` unset in `.env`), we skip
  /// syncing [is_open_cash] so local [shifts] rows are not overwritten by stub
  /// `isOpenCash: false` after reload.
  Future<StandardParkingRates?> revalidateActiveSession({
    required String deviceId,
  }) async {
    final session = await getActiveSession();
    if (session == null) return null;
    final token = session.authToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    final res = await _api.revalidateToken(token: token, deviceId: deviceId);

    if (!res.valid) {
      await (_db.update(_db.sessions)..where((s) => s.id.equals(session.id)))
          .write(
        SessionsCompanion(
          isActive: const Value(false),
          logoutAt: Value(unixNowSeconds()),
          authToken: const Value(null),
        ),
      );
      _refresh.notifyAuthChanged();
      throw StateError('TOKEN_INVALID');
    }

    await _db.transaction(() async {
      await (_db.update(_db.sessions)..where((s) => s.id.equals(session.id)))
          .write(
        SessionsCompanion(
          lastVerifiedAt: Value(unixNowSeconds()),
          authToken: Value(res.token),
        ),
      );
      if (!AppConfig.useStubApi) {
        await _syncShiftFromFlag(
          localUserId: session.userId,
          sessionId: session.id,
          isOpenCash: res.isOpenCash,
        );
      }
    });

    await _flushSyncQueueForActiveSession();
    _refresh.notifyAuthChanged();
    return res.standardRates;
  }

  /// Confirms password before navigating to Close Cash from the logout flow.
  Future<bool> verifyCurrentPassword(String plainPassword) async {
    final session = await getActiveSession();
    if (session == null) return false;
    final row = await offlineAccountById(session.userId);
    if (row == null) return false;
    return BCrypt.checkpw(plainPassword, row.passwordHash);
  }

  Future<void> verifyPasswordForActiveOfflineSession(String password) async {
    await requireDeviceSiteAssigned();
    final session = await getActiveSession();
    if (session == null) throw StateError('NO_SESSION');
    final row = await offlineAccountById(session.userId);
    if (row == null) throw StateError('OFFLINE_ACCOUNT_MISSING');
    if (!BCrypt.checkpw(password, row.passwordHash)) {
      throw StateError('BAD_PASSWORD');
    }
    _refresh.notifyAuthChanged();
  }

  /// Creates an open shift row and enqueues `shift_open`. Returns the new [Shift.id].
  Future<int> recordOpenCash({
    required int localUserId,
    required int sessionId,
    required double openingFloat,
    String branch = '',
    String area = '',
    String? shiftDate,
    String? openingNotes,
  }) async {
    final date =
        shiftDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = unixNowSeconds();
    final shiftId = await _db.transaction<int>(() async {
      final id = await _db.into(_db.shifts).insert(
            ShiftsCompanion.insert(
              userId: localUserId,
              sessionId: sessionId,
              branch: branch,
              area: area,
              shiftDate: date,
              isOpen: const Value(true),
              openingFloat: Value(openingFloat),
              openingNotes: Value(openingNotes),
              openedAt: now,
            ),
          );
      final row = await (_db.select(_db.shifts)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      final payload = jsonEncode({
        'shift': _shiftToJson(row),
        'opening_denominations': <Map<String, dynamic>>[],
      });
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              type: 'shift_open',
              entityId: id,
              payload: payload,
              createdAt: now,
            ),
          );
      return id;
    });
    await _flushSyncQueueForActiveSession();
    _refresh.notifyAuthChanged();
    return shiftId;
  }

  /// Still-checked-in tickets attributed to this shift (for close-cash warning).
  Future<List<ValetTransaction>> queryOpenTransactionsForShiftClose(
    int shiftId,
  ) {
    return (_db.select(_db.valetTransactions)
          ..where(
            (t) =>
                t.checkinShiftId.equals(shiftId) &
                t.timeOut.isNull() &
                t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timeIn)]))
        .get();
  }

  /// Open active tickets from prior shifts that need adopting by [newShiftId].
  Future<List<ValetTransaction>> queryInheritedOpenTransactions(
    int newShiftId,
  ) {
    return (_db.select(_db.valetTransactions)
          ..where(
            (t) =>
                t.timeOut.isNull() &
                t.status.equals('active') &
                t.checkoutShiftId.isNull() &
                t.checkinShiftId.equals(newShiftId).not(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timeIn)]))
        .get();
  }

  /// Sum of [ValetTransactions.totalFee] for sales credited to [checkoutShiftId].
  Future<double> sumSalesForCheckoutShift(int checkoutShiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COALESCE(SUM(total_fee), 0) AS s FROM transactions
WHERE checkout_shift_id = ?
  AND (status = ? OR time_out IS NOT NULL)
''',
      variables: [
        Variable<int>(checkoutShiftId),
        Variable.withString('completed'),
      ],
    ).getSingle();
    return (row.data['s'] as num?)?.toDouble() ?? 0.0;
  }

  /// Count of completed checkouts for [checkoutShiftId] (same filter as [sumSalesForCheckoutShift]).
  Future<int> countCompletedForCheckoutShift(int checkoutShiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM transactions
WHERE checkout_shift_id = ?
  AND (status = ? OR time_out IS NOT NULL)
''',
      variables: [
        Variable<int>(checkoutShiftId),
        Variable.withString('completed'),
      ],
    ).getSingle();
    return (row.data['c'] as int?) ?? (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Sets [checkoutShiftId] on inherited open rows and enqueues `transaction_shift_transfer`.
  Future<void> adoptInheritedTransactionsForShift(int newShiftId) async {
    final rows = await queryInheritedOpenTransactions(newShiftId);
    if (rows.isEmpty) return;
    final now = unixNowSeconds();
    await _db.transaction(() async {
      for (final row in rows) {
        await (_db.update(_db.valetTransactions)
              ..where((t) => t.id.equals(row.id)))
            .write(
          ValetTransactionsCompanion(
            checkoutShiftId: Value(newShiftId),
          ),
        );
        await _db.into(_db.syncQueue).insert(
              SyncQueueCompanion.insert(
                type: 'transaction_shift_transfer',
                entityId: row.id,
                payload: jsonEncode({
                  'transaction_id': row.id,
                  'from_shift_id': row.checkinShiftId,
                  'to_shift_id': newShiftId,
                  'adopted_at': now,
                }),
                createdAt: now,
              ),
            );
      }
    });
    await _flushSyncQueueForActiveSession();
  }

  /// Logout only: end session, clear token; optional remote logout (non-blocking).
  Future<void> logoutOnly({String? deviceId}) async {
    ValetLog.d('AuthRepository.logoutOnly', 'begin');
    final session = await getActiveSession();
    if (session == null) return;
    final token = session.authToken;
    await (_db.update(_db.sessions)..where((s) => s.id.equals(session.id)))
        .write(
      SessionsCompanion(
        isActive: const Value(false),
        logoutAt: Value(unixNowSeconds()),
        authToken: const Value(null),
      ),
    );
    if (deviceId != null && token != null && token.isNotEmpty) {
      unawaited(_api.logout(token: token, deviceId: deviceId));
    }
    _refresh.notifyAuthChanged();
  }

  /// Close cash + logout: persist reconciliation, enqueue sync, flush while token valid, then end session.
  Future<void> confirmCloseCash({
    required int localUserId,
    required double closingFloat,
    String? closingNotes,
    required double totalSales,
    required double expectedCash,
    required double variance,
    required double remittance,
    required int transactionsCount,
  }) async {
    final session = await getActiveSession();
    if (session == null || session.userId != localUserId) return;
    final token = session.authToken;

    final shift = await getOpenShiftForUser(localUserId);
    if (shift == null) return;

    final now = unixNowSeconds();

    await _db.transaction(() async {
      await (_db.update(_db.shifts)..where((s) => s.id.equals(shift.id)))
          .write(
        ShiftsCompanion(
          isOpen: const Value(false),
          closingFloat: Value(closingFloat),
          closingNotes: Value(closingNotes),
          totalSales: Value(totalSales),
          expectedCash: Value(expectedCash),
          variance: Value(variance),
          remittance: Value(remittance),
          transactionsCount: Value(transactionsCount),
          closedAt: Value(now),
        ),
      );
      final updated = await (_db.select(_db.shifts)
            ..where((s) => s.id.equals(shift.id)))
          .getSingle();
      final payload = jsonEncode({
        'shift': _shiftToJson(updated),
        'closing_denominations': <Map<String, dynamic>>[],
      });
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              type: 'shift_close',
              entityId: shift.id,
              payload: payload,
              createdAt: now,
            ),
          );
    });

    if (token != null && token.isNotEmpty) {
      await _flushSyncQueue(token: token);
    }

    await (_db.update(_db.sessions)..where((s) => s.id.equals(session.id)))
        .write(
      SessionsCompanion(
        isActive: const Value(false),
        logoutAt: Value(unixNowSeconds()),
        authToken: const Value(null),
      ),
    );
    _refresh.notifyAuthChanged();
  }

  /// Before inserting a new session (online/offline login): end any prior active sessions.
  Future<void> _deactivateAllActiveSessions() async {
    final now = unixNowSeconds();
    await (_db.update(_db.sessions)..where((s) => s.isActive.equals(true)))
        .write(
      SessionsCompanion(
        isActive: const Value(false),
        logoutAt: Value(now),
      ),
    );
  }

  Future<void> _syncShiftFromFlag({
    required int localUserId,
    required int sessionId,
    required bool isOpenCash,
  }) async {
    if (isOpenCash) {
      final existing = await (_db.select(_db.shifts)
            ..where(
              (sh) =>
                  sh.userId.equals(localUserId) & sh.isOpen.equals(true),
            )
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.shifts)..where((sh) => sh.id.equals(existing.id)))
            .write(
          ShiftsCompanion(sessionId: Value(sessionId)),
        );
      } else {
        final date =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        await _db.into(_db.shifts).insert(
              ShiftsCompanion.insert(
                userId: localUserId,
                sessionId: sessionId,
                branch: '',
                area: '',
                shiftDate: date,
                isOpen: const Value(true),
                openingFloat: const Value(0.0),
                openedAt: unixNowSeconds(),
              ),
            );
      }
    } else {
      await (_db.update(_db.shifts)
            ..where(
              (sh) =>
                  sh.userId.equals(localUserId) & sh.isOpen.equals(true),
            ))
          .write(
        ShiftsCompanion(
          isOpen: const Value(false),
          closedAt: Value(unixNowSeconds()),
        ),
      );
    }
  }

  Future<void> _flushSyncQueueForActiveSession() async {
    final session = await getActiveSession();
    if (session == null) return;
    final token = session.authToken;
    if (token == null || token.isEmpty) return;
    await _flushSyncQueue(token: token);
  }

  /// Public hook after local writes (e.g. offline check-in) to push [SyncQueue] when online.
  Future<void> flushPendingSyncQueue() async {
    ValetLog.d('AuthRepository.flushPendingSyncQueue', 'invoked');
    await _flushSyncQueueForActiveSession();
  }

  Future<void> _flushSyncQueue({required String token}) async {
    final pending = await (_db.select(_db.syncQueue)
          ..where((q) => q.syncedAt.isNull())
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
    ValetLog.d(
      'AuthRepository._flushSyncQueue',
      'pending=${pending.length}',
    );
    if (pending.isEmpty) return;

    pending.sort((a, b) {
      final c = _syncTypeOrder(a.type).compareTo(_syncTypeOrder(b.type));
      if (c != 0) return c;
      return a.createdAt.compareTo(b.createdAt);
    });

    if (AppConfig.useStubApi) {
      ValetLog.d(
        'AuthRepository._flushSyncQueue',
        'stub API: marking ${pending.length} rows synced locally',
      );
      await _applySyncSuccessLocal(pending);
      return;
    }

    final records = pending
        .map(
          (e) => <String, dynamic>{
            'type': e.type,
            'payload': jsonDecode(e.payload) as Object,
          },
        )
        .toList();

    try {
      final response = await _api.syncFlush(token: token, records: records);
      ValetLog.d(
        'AuthRepository._flushSyncQueue',
        'syncFlush ok, resultCount=${response.results.length}',
      );
      final now = unixNowSeconds();
      for (var i = 0; i < response.results.length && i < pending.length; i++) {
        final r = response.results[i];
        final row = pending[i];
        if (r.success) {
          await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id)))
              .write(SyncQueueCompanion(syncedAt: Value(now)));
          await _markEntitySyncedAt(row.type, row.entityId, now);
        } else {
          await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id)))
              .write(
            SyncQueueCompanion(
              retryCount: Value(row.retryCount + 1),
              lastError: Value(r.error ?? 'sync failed'),
            ),
          );
        }
      }
    } catch (e, st) {
      ValetLog.e('AuthRepository._flushSyncQueue', 'syncFlush failed', e, st);
      final err = e.toString();
      for (final row in pending) {
        await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id)))
            .write(
          SyncQueueCompanion(
            retryCount: Value(row.retryCount + 1),
            lastError: Value(err),
          ),
        );
      }
    }
  }

  Future<void> _applySyncSuccessLocal(List<SyncQueueData> pending) async {
    final now = unixNowSeconds();
    for (final row in pending) {
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id)))
          .write(SyncQueueCompanion(syncedAt: Value(now)));
      await _markEntitySyncedAt(row.type, row.entityId, now);
    }
  }

  Future<void> _markEntitySyncedAt(String type, int entityId, int ts) async {
    switch (type) {
      case 'shift_open':
      case 'shift_close':
        await (_db.update(_db.shifts)..where((s) => s.id.equals(entityId)))
            .write(ShiftsCompanion(syncedAt: Value(ts)));
        break;
      case 'transaction':
      case 'transaction_shift_transfer':
        await (_db.update(_db.valetTransactions)
              ..where((t) => t.id.equals(entityId)))
            .write(ValetTransactionsCompanion(syncedAt: Value(ts)));
        break;
      default:
        break;
    }
  }

  int _syncTypeOrder(String t) {
    switch (t) {
      case 'shift_open':
        return 0;
      case 'transaction':
      case 'transaction_shift_transfer':
        return 1;
      case 'shift_close':
        return 2;
      default:
        return 99;
    }
  }

  Map<String, dynamic> _shiftToJson(Shift s) {
    return {
      'id': s.id,
      'session_id': s.sessionId,
      'user_id': s.userId,
      'branch': s.branch,
      'area': s.area,
      'shift_date': s.shiftDate,
      'is_open': s.isOpen,
      'opening_float': s.openingFloat,
      'opening_notes': s.openingNotes,
      'closing_float': s.closingFloat,
      'closing_notes': s.closingNotes,
      'total_sales': s.totalSales,
      'expected_cash': s.expectedCash,
      'variance': s.variance,
      'remittance': s.remittance,
      'transactions_count': s.transactionsCount,
      'opened_at': s.openedAt,
      'closed_at': s.closedAt,
      'synced_at': s.syncedAt,
    };
  }
}
