import 'dart:async';
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/services/device_id_service.dart';
import '../../core/storage/device_site_prefs.dart';
import '../../core/routing/router_refresh_notifier.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../core/time/unix_timestamp.dart';
import '../local/db/app_database.dart';
import '../remote/auth_api.dart';
import '../services/rate_fetch_service.dart';
import '../services/rate_service.dart';
import '../services/shift_service.dart';
import '../services/ticket_sync_payload.dart';

/// Local persistence rules (Drift ↔ SQL intent):
///
/// **Open cash for a user** — unified `shifts` open row
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
    this._shifts,
    this._rates,
    this._rateFetch,
  );

  final AppDatabase _db;
  final AuthApi _api;
  final RouterRefreshNotifier _refresh;
  final ShiftService _shifts;
  final RateService _rates;
  final RateFetchService _rateFetch;

  static const _uuid = Uuid();

  /// Seeds `rates` for [device_info.branch] when empty (offline-only; [StandardParkingRates.offlineDefault]).
  Future<void> hydrateLocalRatesIfEmpty() async {
    final site = await branchAndAreaFromDb();
    await _rates.syncFromAuthIfEmpty(branchId: site.branch, rates: null);
  }

  /// `SELECT * FROM sessions WHERE is_active = 1 LIMIT 1`
  Future<Session?> getActiveSession() {
    return (_db.select(_db.sessions)
          ..where((s) => s.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Open `shifts` row for server-linked user id string.
  Future<String> shiftRouteForLocalUser(int localUserId) async {
    final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
    final open = await _shifts.getActiveShift(uid);
    return open != null ? '/dashboard' : '/cash/open';
  }

  Future<OfflineAccount?> offlineAccountById(int localId) {
    return (_db.select(_db.offlineAccounts)
          ..where((a) => a.id.equals(localId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OfflineAccount?> offlineAccountByServerId(String serverUserId) {
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
  Future<Shift?> getOpenShiftForUser(int localUserId) async {
    final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
    return _shifts.getActiveShift(uid);
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
    required String serverUserId,
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
    ValetLog.debug('AuthRepository.loginOnline', 'begin');
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

    _refresh.notifyAuthChanged();
    final site = await branchAndAreaFromDb();
    await _rateFetch.syncRatesForBranch(site.branch);
    await _rates.syncFromAuthIfEmpty(branchId: site.branch, rates: null);
    ValetLog.debug(
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
    await hydrateLocalRatesIfEmpty();
    ValetLog.debug(
      'AuthRepository.loginOffline',
      'success localUserId=${row.id}',
    );
    return null;
  }

  /// `UPDATE sessions SET last_verified_at = ?, auth_token = ? WHERE id = ?`
  /// ([authToken] only when validate-token returns a new JWT; otherwise unchanged.)
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
          authToken: res.token != null && res.token!.trim().isNotEmpty
              ? Value(res.token)
              : const Value.absent(),
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

    _refresh.notifyAuthChanged();
    final site = await branchAndAreaFromDb();
    await _rateFetch.syncRatesForBranch(site.branch);
    await _rates.syncFromAuthIfEmpty(branchId: site.branch, rates: null);
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

  /// Opens a cash shift via [ShiftService] (UUID id). [sessionId] is unused (kept for call sites).
  Future<String> recordOpenCash({
    required int localUserId,
    required int sessionId,
    required double openingFloat,
    String branch = '',
    String area = '',
    String? shiftDate,
    String? openingNotes,
  }) async {
    final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
    final site = await branchAndAreaFromDb();
    final bid = branch.trim().isNotEmpty ? branch.trim() : site.branch.trim();
    final shift = await _shifts.createShift(
      userId: uid,
      branchId: bid.isEmpty ? '_' : bid,
      openingFloat: openingFloat,
    );
    _refresh.notifyAuthChanged();
    return shift.id;
  }

  /// Active tickets on this shift (close-cash warning).
  Future<List<Ticket>> queryOpenTicketsForShiftClose(String shiftId) {
    return (_db.select(_db.tickets)
          ..where(
            (t) => t.shiftId.equals(shiftId) & t.status.equals('active'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.checkInAt)]))
        .get();
  }

  /// Active tickets from other shifts to optionally adopt into [newShiftId].
  Future<List<Ticket>> queryInheritedOpenTickets(String newShiftId) {
    return (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.status.equals('active') & t.shiftId.equals(newShiftId).not(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.checkInAt)]))
        .get();
  }

  /// Sum of completed ticket fees for [shiftId].
  Future<double> sumSalesForCheckoutShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COALESCE(SUM(fee), 0) AS s FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['s'] as num?)?.toDouble() ?? 0.0;
  }

  /// Completed checkouts on [shiftId].
  Future<int> countCompletedForCheckoutShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'completed'
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  /// Reassigns inherited active tickets to [newShiftId] and enqueues outbound sync.
  Future<void> adoptInheritedTicketsForShift(String newShiftId) async {
    final rows = await queryInheritedOpenTickets(newShiftId);
    if (rows.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db.transaction(() async {
      for (final row in rows) {
        await (_db.update(_db.tickets)..where((t) => t.id.equals(row.id)))
            .write(
          TicketsCompanion(
            shiftId: Value(newShiftId),
            syncStatus: const Value('pending'),
          ),
        );
        final updated = await (_db.select(_db.tickets)
              ..where((t) => t.id.equals(row.id)))
            .getSingle();
        await _db.into(_db.syncQueue).insert(
              SyncQueueCompanion.insert(
                id: _uuid.v4(),
                operation: 'update',
                queueTableName: 'tickets',
                recordId: updated.id,
                payload: jsonEncode(ticketSyncPayload(updated)),
                syncStatus: 'pending',
                createdAt: now,
              ),
            );
      }
    });
  }

  /// Logout only: end session, clear token; optional remote logout (non-blocking).
  Future<void> logoutOnly({String? deviceId}) async {
    ValetLog.debug('AuthRepository.logoutOnly', 'begin');
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

  /// Close cash + logout: [ShiftService] has already closed the shift row; flush queue then end session.
  ///
  /// [closingFloat], [closingNotes], and sales fields are accepted for UI parity but not persisted here.
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
      final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
      final open = await _shifts.getActiveShift(uid);
      if (open != null) return;
      final site = await branchAndAreaFromDb();
      final bid = site.branch.trim().isEmpty ? '_' : site.branch.trim();
      try {
        await _shifts.createShift(
          userId: uid,
          branchId: bid,
          openingFloat: 0,
        );
      } on StateError catch (_) {
        // Race: shift opened concurrently.
      }
    } else {
      await _shifts.closeActiveShiftForLocalUser(localUserId, 0);
    }
  }
}
