import 'dart:async';
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../../core/services/device_id_service.dart';
import '../../core/storage/device_site_ids.dart';
import '../../core/storage/device_site_prefs.dart';
import '../../core/storage/prefs_keys.dart';
import '../../core/storage/site_display_name.dart';
import '../../core/routing/router_refresh_notifier.dart';
import '../../core/session/cashier_shift_schedule.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../core/time/unix_timestamp.dart';
import '../../data/remote/dashboard_summary.dart';
import '../../features/cash/models/close_cash_shift_stats.dart';
import '../../features/cash/models/open_transaction.dart';
import '../../features/check_in/domain/vehicle_body_type.dart';
import '../local/db/app_database.dart';
import '../remote/api_error_message.dart';
import '../remote/auth_api.dart';
import '../remote/dashboard_api.dart';
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
    this._dashboardApi,
  );

  final AppDatabase _db;
  final AuthApi _api;
  final RouterRefreshNotifier _refresh;
  final ShiftService _shifts;
  final RateService _rates;
  final RateFetchService _rateFetch;
  final DashboardApi _dashboardApi;

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
    if (open == null) return '/cash/open';
    if (await isExpressCashierForLocalUser(localUserId)) {
      return '/express-cashier';
    }
    return '/dashboard';
  }

  /// Whether the logged-in user is in express cashier (manual ticketing) mode.
  Future<bool> isExpressCashierForLocalUser(int localUserId) async {
    final account = await offlineAccountById(localUserId);
    return account?.isExpressCashier ?? false;
  }

  Future<OfflineAccount?> offlineAccountById(int localId) {
    return (_db.select(_db.offlineAccounts)
          ..where((a) => a.id.equals(localId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Server user UUID for a local offline account (login `user.id`).
  Future<String?> serverUserIdForLocalAccount(int localUserId) async {
    final account = await offlineAccountById(localUserId);
    return account?.serverUserId;
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

  /// Server area UUID for REST paths (`/branches/:id/areas/:areaId`). Empty when unknown.
  Future<String> areaUuidForApi() async {
    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = prefs.getString(PrefsKeys.deviceAreaId)?.trim() ?? '';
    if (DeviceSiteIds.isUuid(fromPrefs)) return fromPrefs;

    final identity = await (_db.select(_db.deviceIdentity)..limit(1))
        .getSingleOrNull();
    if (identity != null && DeviceSiteIds.isUuid(identity.areaId)) {
      return identity.areaId.trim();
    }
    return '';
  }

  /// Server branch UUID for REST paths (`/branches/:id`, rates). Empty when unknown.
  Future<String> branchUuidForApi() async {
    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = prefs.getString(PrefsKeys.deviceBranchId)?.trim() ?? '';
    if (DeviceSiteIds.isUuid(fromPrefs)) return fromPrefs;

    final identity = await (_db.select(_db.deviceIdentity)..limit(1))
        .getSingleOrNull();
    if (identity != null && DeviceSiteIds.isUuid(identity.branchId)) {
      return identity.branchId.trim();
    }
    return '';
  }

  /// Branch/area display names: cached prefs (claim) → [device_identity] → legacy [device_info].
  Future<({String branch, String area})> branchAndAreaFromDb() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = DeviceSitePrefs.readSiteNames(prefs);
    if (cached.branch.isNotEmpty && cached.area.isNotEmpty) {
      return cached;
    }

    final identity = await (_db.select(_db.deviceIdentity)..limit(1))
        .getSingleOrNull();
    if (identity != null) {
      final b = SiteDisplayName.sanitizeStored(identity.branch);
      final a = SiteDisplayName.sanitizeStored(identity.area);
      if (b.isNotEmpty && a.isNotEmpty) {
        return (branch: b, area: a);
      }
    }

    final deviceId = await DeviceIdService.getOrCreate();
    final row = await (_db.select(_db.deviceInfo)
          ..where((d) => d.deviceId.equals(deviceId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return (branch: '', area: '');
    return (
      branch: SiteDisplayName.sanitizeStored(row.branch),
      area: SiteDisplayName.sanitizeStored(row.area),
    );
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
        footerLine: DeviceSitePrefs.valetAttendantFooterLine(prefs),
      );
    }
    final p = await branchAndAreaFromDb();
    return (
      canLogin: true,
      footerLine:
          '${p.branch.toUpperCase()} : ${p.area.toUpperCase()} — VALET ATTENDANT',
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

  /// Weekly shift from login, keyed by local [OfflineAccounts.id].
  Future<CashierShiftSchedule?> shiftScheduleForLocalUser(int localUserId) async {
    final row = await offlineAccountById(localUserId);
    if (row == null) return null;
    return CashierShiftSchedule.fromJsonString(row.shiftScheduleJson);
  }

  Future<int> _upsertOfflineAccount({
    required String serverUserId,
    required String email,
    required String passwordHash,
    required String fullName,
    required String role,
    String shiftScheduleJson = '',
    bool isExpressCashier = false,
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
          shiftScheduleJson: Value(shiftScheduleJson),
          isExpressCashier: Value(isExpressCashier),
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
            shiftScheduleJson: Value(shiftScheduleJson),
            isExpressCashier: Value(isExpressCashier),
            lastOnlineLogin: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<StandardParkingRates?> loginOnline({
    required String email,
    required String password,
    String? serverDeviceId,
  }) async {
    ValetLog.debug('AuthRepository.loginOnline', 'begin');
    await requireDeviceSiteAssigned();
    try {
      return await _loginOnlineImpl(
        email: email,
        password: password,
        serverDeviceId: serverDeviceId,
      );
    } on LoginApiFailure {
      rethrow;
    } on DioException catch (e) {
      throw LoginApiFailure(
        parseApiErrorUserMessage(e) ?? 'Login failed. Please try again.',
      );
    }
  }

  Future<StandardParkingRates?> _loginOnlineImpl({
    required String email,
    required String password,
    String? serverDeviceId,
  }) async {
    final res = await _api.login(
      email: email,
      password: password,
      serverDeviceId: serverDeviceId,
    );

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final accountId = await _upsertOfflineAccount(
      serverUserId: res.userId,
      email: email,
      passwordHash: hash,
      fullName: res.fullName,
      role: res.role,
      shiftScheduleJson:
          CashierShiftSchedule.encodeToJsonString(res.shiftSchedule),
      isExpressCashier: res.expressCashier,
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

      await applyServerOpenCashFlag(
        localUserId: accountId,
        isOpenCash: res.isOpenCash,
      );
    });

    if (res.userSite != null) {
      final prefs = await SharedPreferences.getInstance();
      final site = res.userSite!;
      await DeviceSitePrefs.applyLoginUserSite(
        prefs,
        branchName: site.branchName,
        areaName: site.areaName,
        branchId: site.branchId,
        areaId: site.areaId,
      );
    }

    _refresh.notifyAuthChanged();
    await _syncRatesForCurrentBranch(res.standardRates);
    ValetLog.debug(
      'AuthRepository.loginOnline',
      'success localUserId=$accountId',
    );
    return res.standardRates;
  }

  Future<void> _syncRatesForCurrentBranch(StandardParkingRates? fromLogin) async {
    final branchUuid = await branchUuidForApi();
    final areaUuid = await areaUuidForApi();
    if (branchUuid.isEmpty) {
      ValetLog.warning(
        'AuthRepository',
        'skip rate sync — no branch UUID (login/validate must set device_branch_id)',
      );
      final site = await branchAndAreaFromDb();
      await _rates.syncFromAuthIfEmpty(branchId: site.branch, rates: fromLogin);
      return;
    }
    if (areaUuid.isNotEmpty) {
      await _rateFetch.syncRatesForBranchArea(
        branchId: branchUuid,
        areaId: areaUuid,
      );
    } else {
      await _rateFetch.syncRatesForBranch(branchUuid);
    }
    await _rates.syncFromAuthIfEmpty(
      branchId: branchUuid,
      rates: fromLogin,
    );
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
        await applyServerOpenCashFlag(
          localUserId: session.userId,
          isOpenCash: res.isOpenCash,
        );
      }
    });

    _refresh.notifyAuthChanged();
    await _syncRatesForCurrentBranch(res.standardRates);
    return res.standardRates;
  }

  /// `POST /devices/validate` after [revalidateActiveSession] succeeds.
  ///
  /// Returns **true** if splash should continue (valid, or network/parse failure
  /// treated as valid). Returns **false** after [logoutOnly] when the server
  /// reports `valid: false` (cashier must re-login).
  Future<bool> validateDeviceAssignmentAfterTokenOk({
    required SharedPreferences prefs,
    required String deviceId,
    required String serverDeviceId,
    required String authToken,
  }) async {
    if (AppConfig.useStubApi) return true;
    final sid = serverDeviceId.trim();
    final tok = authToken.trim();
    if (sid.isEmpty || tok.isEmpty) return true;

    final DeviceValidateResponse res;
    try {
      res = await _api.validateDevice(token: tok, serverDeviceId: sid);
    } on DioException catch (e) {
      ValetLog.debug(
        'AuthRepository.validateDeviceAssignmentAfterTokenOk',
        'devices/validate skipped (network): ${e.message}',
      );
      return true;
    } catch (e) {
      ValetLog.debug(
        'AuthRepository.validateDeviceAssignmentAfterTokenOk',
        'devices/validate skipped: $e',
      );
      return true;
    }

    if (res.valid) return true;

    if (res.device != null) {
      final d = res.device!;
      await DeviceSitePrefs.applyValidateDeviceAssignment(
        prefs,
        branchName: d.branchName,
        areaName: d.areaName,
        branchId: d.branchId,
        areaId: d.areaId,
      );
      await _updateDeviceIdentitySiteFromValidate(
        serverDeviceId: sid,
        branchName: d.branchName,
        areaName: d.areaName,
        branchId: d.branchId,
        areaId: d.areaId,
      );
      final branchCol = d.branchName.trim().isNotEmpty
          ? d.branchName.trim()
          : d.branchId.trim();
      final areaCol = d.areaName.trim().isNotEmpty
          ? d.areaName.trim()
          : d.areaId.trim();
      await _upsertDeviceInfoRow(
        deviceId: deviceId,
        branch: branchCol,
        area: areaCol,
      );
    }

    await logoutOnly(deviceId: deviceId);
    return false;
  }

  Future<void> _updateDeviceIdentitySiteFromValidate({
    required String serverDeviceId,
    required String branchName,
    required String areaName,
    required String branchId,
    required String areaId,
  }) async {
    await (_db.update(_db.deviceIdentity)
          ..where((d) => d.serverDeviceId.equals(serverDeviceId)))
        .write(
      DeviceIdentityCompanion(
        branch: Value(branchName.trim()),
        area: Value(areaName.trim()),
        branchId: Value(branchId.trim()),
        areaId: Value(areaId.trim()),
      ),
    );
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
    final account = await offlineAccountById(localUserId);
    final shift = await _shifts.createShift(
      userId: uid,
      branchId: bid.isEmpty ? '_' : bid,
      openingFloat: openingFloat,
      notes: openingNotes,
      awaitRemoteStart: true,
      isExpressCashier: account?.isExpressCashier ?? false,
    );
    _refresh.notifyAuthChanged();
    return shift.id;
  }

  /// Pre-open-cash check: returns all currently-parked tickets that the
  /// incoming cashier will need to acknowledge before a shift is created.
  ///
  /// Express cashiers never inherit or adopt tickets. Normal cashiers never
  /// inherit express-cashier tickets.
  ///
  /// Sources (merged, deduplicated by server UUID):
  /// 1. Local Drift DB — all `active` tickets (regardless of shift).
  /// 2. Remote `GET /reports/transactions?status=active` — best-effort; ignored
  ///    on network errors so the flow still works offline.
  Future<List<OpenTransaction>> queryInheritedTransactionsPreCheck({
    required int localUserId,
  }) async {
    if (await isExpressCashierForLocalUser(localUserId)) {
      return const [];
    }

    // 1. Local active tickets (normal cashier only — never express).
    final localTickets = await (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.status.equals('active') &
                t.checkOutAt.isNull() &
                t.isExpressCashier.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.checkInAt)]))
        .get();

    final localServerIds = localTickets
        .map((t) => t.serverTicketId)
        .whereType<String>()
        .toSet();

    final localResult =
        localTickets.map(OpenTransaction.fromTicket).toList();

    // 2. Remote active tickets (best-effort) via dashboard/summary recent list.
    final remoteExtra = <OpenTransaction>[];
    try {
      final session = await getActiveSession();
      final token = session?.authToken?.trim();
      if (token != null && token.isNotEmpty) {
        final summary = await _dashboardApi.fetchSummary(bearerToken: token);
        if (summary != null) {
          for (final row in summary.recent) {
            if (row.isCheckedOutStatus) continue;
            final sid = row.id.trim();
            if (sid.isNotEmpty && localServerIds.contains(sid)) continue;
            remoteExtra.add(OpenTransaction.fromDashboardSummaryRecent(row));
          }
        }
      }
    } catch (_) {
      // Network unavailable or API error — local results are sufficient.
    }

    return [...localResult, ...remoteExtra];
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

  /// Active check-ins from other shifts to optionally adopt into [newShiftId].
  /// Express-cashier tickets are never transferred between shifts.
  Future<List<Ticket>> queryInheritedOpenTickets(String newShiftId) {
    return (_db.select(_db.tickets)
          ..where(
            (t) =>
                t.status.equals('active') &
                t.shiftId.equals(newShiftId).not() &
                t.checkOutAt.isNull() &
                t.isExpressCashier.equals(false),
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

  /// Express cashier tickets on [shiftId] (matches Manual Ticketing list).
  Future<int> countExpressCompletedForShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'completed' AND is_express_cashier = 1
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<double> sumExpressSalesForShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COALESCE(SUM(fee), 0) AS s FROM tickets
WHERE shift_id = ? AND status = 'completed' AND is_express_cashier = 1
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['s'] as num?)?.toDouble() ?? 0.0;
  }

  /// Close-cash stats for [shift]: counts activity since shift open (not only
  /// `shift_id` match — checkouts stay on the ticket's original shift row).
  /// When online, pass [remoteCheckoutCount] / [remoteVehiclesIn] from
  /// `GET /dashboard/summary` so totals match the dashboard.
  Future<CloseCashShiftStats> loadCloseCashStatsForShift(
    Shift shift, {
    int? remoteCheckoutCount,
    int? remoteVehiclesIn,
    Map<String, int>? remoteByVehicleType,
    List<DashboardSummaryRecent>? recentCheckouts,
  }) async {
    final since = shift.openedAt;
    final userId = shift.userId;

    final checkInCount = await _countCheckInsSinceOpen(since, userId);
    var vehiclesIn = await _countActiveOnShift(shift.id);

    late final int checkoutCount;
    late final double totalSales;
    late final Map<String, int> byVehicleType;

    if (shift.isExpressCashier) {
      // Match Manual Ticketing list — ignore dashboard totals that can include
      // extra server rows from failed/partial saves.
      checkoutCount = await countExpressCompletedForShift(shift.id);
      totalSales = await sumExpressSalesForShift(shift.id);
      byVehicleType = const {};
    } else {
      var localCheckoutCount = await _countCompletedSinceOpen(
        since,
        userId,
        shiftId: shift.id,
      );
      var localTotalSales = await _sumCompletedSalesSinceOpen(
        since,
        userId,
        shiftId: shift.id,
      );
      var localByVehicleType = await _completedByVehicleTypeSinceOpen(
        since,
        userId,
        shiftId: shift.id,
      );

      if (remoteCheckoutCount != null &&
          remoteCheckoutCount > localCheckoutCount) {
        localCheckoutCount = remoteCheckoutCount;
      }
      if (remoteVehiclesIn != null) {
        vehiclesIn = remoteVehiclesIn;
      }

      final localTypeTotal =
          localByVehicleType.values.fold<int>(0, (sum, n) => sum + n);
      final remoteTypeTotal = remoteByVehicleType?.values.fold<int>(
            0,
            (sum, n) => sum + n,
          ) ??
          0;
      if (remoteByVehicleType != null &&
          remoteTypeTotal > 0 &&
          (localTypeTotal == 0 || remoteTypeTotal > localTypeTotal)) {
        localByVehicleType = remoteByVehicleType;
      }

      final mergedTypeTotal =
          localByVehicleType.values.fold<int>(0, (sum, n) => sum + n);
      if (mergedTypeTotal == 0 &&
          localCheckoutCount > 0 &&
          recentCheckouts != null &&
          recentCheckouts.isNotEmpty) {
        final fromRecent =
            await _vehicleTypeCountsFromRecentCheckouts(recentCheckouts);
        if (fromRecent.isNotEmpty) {
          localByVehicleType = fromRecent;
        }
      }

      checkoutCount = localCheckoutCount;
      totalSales = localTotalSales;
      byVehicleType = localByVehicleType;
    }

    return CloseCashShiftStats.fromAggregates(
      checkInCount: checkInCount,
      checkoutCount: checkoutCount,
      vehiclesIn: vehiclesIn,
      totalSales: totalSales,
      openingFloat: shift.openingFloat,
      byVehicleType: byVehicleType,
    );
  }

  Future<int> _countCheckInsSinceOpen(String sinceIso, String userId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE user_id = ? AND check_in_at >= ? AND status != 'draft'
''',
      variables: [Variable<String>(userId), Variable<String>(sinceIso)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> _countCompletedSinceOpen(
    String sinceIso,
    String userId, {
    required String shiftId,
  }) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE user_id = ?
  AND status IN ('completed', 'lost')
  AND (
    shift_id = ?
    OR (check_out_at IS NOT NULL AND check_out_at >= ?)
  )
''',
      variables: [
        Variable<String>(userId),
        Variable<String>(shiftId),
        Variable<String>(sinceIso),
      ],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> _countActiveOnShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'active'
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<double> _sumCompletedSalesSinceOpen(
    String sinceIso,
    String userId, {
    required String shiftId,
  }) async {
    final row = await _db.customSelect(
      '''
SELECT COALESCE(SUM(fee), 0) AS s FROM tickets
WHERE user_id = ?
  AND status IN ('completed', 'lost')
  AND (
    shift_id = ?
    OR (check_out_at IS NOT NULL AND check_out_at >= ?)
  )
''',
      variables: [
        Variable<String>(userId),
        Variable<String>(shiftId),
        Variable<String>(sinceIso),
      ],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['s'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, int>> _completedByVehicleTypeSinceOpen(
    String sinceIso,
    String userId, {
    required String shiftId,
  }) async {
    final rows = await _db.customSelect(
      '''
SELECT vehicle_type AS vt, COUNT(*) AS c FROM tickets
WHERE user_id = ?
  AND status IN ('completed', 'lost')
  AND (
    shift_id = ?
    OR (check_out_at IS NOT NULL AND check_out_at >= ?)
  )
GROUP BY vehicle_type
''',
      variables: [
        Variable<String>(userId),
        Variable<String>(shiftId),
        Variable<String>(sinceIso),
      ],
      readsFrom: {_db.tickets},
    ).get();
    final counts = <String, int>{};
    for (final row in rows) {
      final raw = (row.data['vt'] as String?)?.trim() ?? '';
      final key = normalizeVehicleTypeRateKey(raw);
      if (key == null) continue;
      final n = (row.data['c'] as num?)?.toInt() ?? 0;
      counts[key] = (counts[key] ?? 0) + n;
    }
    return counts;
  }

  Future<Map<String, int>> _vehicleTypeCountsFromRecentCheckouts(
    List<DashboardSummaryRecent> recent,
  ) async {
    final counts = <String, int>{};
    for (final row in recent) {
      if (!row.isCheckedOutStatus) continue;

      var key = row.vehicleTypeRateKey;
      if (key == null) {
        final ticket = await _findLocalTicketForSummaryRow(row);
        key = normalizeVehicleTypeRateKey(ticket?.vehicleType);
      }
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<Ticket?> _findLocalTicketForSummaryRow(
    DashboardSummaryRecent row,
  ) async {
    final serverId = row.id.trim();
    if (serverId.isNotEmpty) {
      final byServer = await (_db.select(_db.tickets)
            ..where((t) => t.serverTicketId.equals(serverId))
            ..limit(1))
          .getSingleOrNull();
      if (byServer != null) return byServer;

      final byLocalId = await (_db.select(_db.tickets)
            ..where((t) => t.id.equals(serverId))
            ..limit(1))
          .getSingleOrNull();
      if (byLocalId != null) return byLocalId;
    }

    final ticketNo = row.ticketNumber.trim();
    if (ticketNo.isNotEmpty) {
      return (_db.select(_db.tickets)
            ..where((t) => t.id.equals(ticketNo))
            ..limit(1))
          .getSingleOrNull();
    }
    return null;
  }

  /// Check-ins on [shiftId] (excludes drafts).
  Future<int> countCheckInsForShift(String shiftId) async {
    final row = await _db.customSelect(
      '''
SELECT COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status != 'draft'
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<Shift?> getShiftById(String shiftId) {
    return (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId)))
        .getSingleOrNull();
  }

  /// Completed checkouts grouped by `vehicle_type` for close-cash summary.
  Future<Map<String, int>> countCompletedByVehicleTypeForShift(
    String shiftId,
  ) async {
    final rows = await _db.customSelect(
      '''
SELECT vehicle_type AS vt, COUNT(*) AS c FROM tickets
WHERE shift_id = ? AND status = 'completed'
GROUP BY vehicle_type
''',
      variables: [Variable<String>(shiftId)],
      readsFrom: {_db.tickets},
    ).get();
    final counts = <String, int>{};
    for (final row in rows) {
      final key = (row.data['vt'] as String?)?.trim() ?? '';
      counts[key] = (row.data['c'] as num?)?.toInt() ?? 0;
    }
    return counts;
  }

  /// Reassigns inherited active tickets to [newShiftId].
  ///
  /// Already-synced tickets (on the server) only move locally; unsynced rows are
  /// queued for outbound sync. Express-cashier shifts never adopt tickets.
  Future<void> adoptInheritedTicketsForShift(String newShiftId) async {
    final shift = await (_db.select(_db.shifts)
          ..where((s) => s.id.equals(newShiftId))
          ..limit(1))
        .getSingleOrNull();
    if (shift?.isExpressCashier == true) return;

    final rows = await queryInheritedOpenTickets(newShiftId);
    if (rows.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db.transaction(() async {
      for (final row in rows) {
        final alreadySynced = row.syncStatus == 'synced';
        await (_db.update(_db.tickets)..where((t) => t.id.equals(row.id)))
            .write(
          TicketsCompanion(
            shiftId: Value(newShiftId),
            syncStatus: Value(alreadySynced ? 'synced' : 'pending'),
          ),
        );
        if (alreadySynced) continue;
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
  Future<void> confirmCloseCash({
    required int localUserId,
    required double closingFloat,
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

  /// Reconciles local [shifts] with server `is_open_cash` from login / validate-token.
  ///
  /// Called on every online login and token revalidate. After local storage was
  /// cleared (or close-cash purge removed shift rows), `is_open_cash: true`
  /// recreates an open local shift so [shiftRouteForLocalUser] can resume the
  /// server session; `false` ensures the cashier is sent to Open Cash.
  Future<void> applyServerOpenCashFlag({
    required int localUserId,
    required bool isOpenCash,
  }) async {
    if (isOpenCash) {
      final uid = await _shifts.shiftUserIdForLocalAccount(localUserId);
      final open = await _shifts.getActiveShift(uid);
      if (open != null) return;
      final site = await branchAndAreaFromDb();
      final bid = site.branch.trim().isEmpty ? '_' : site.branch.trim();
      final isExpress = await isExpressCashierForLocalUser(localUserId);
      try {
        await _shifts.createShift(
          userId: uid,
          branchId: bid,
          openingFloat: 0,
          resumeServerSession: true,
          isExpressCashier: isExpress,
        );
      } on StateError catch (_) {
        // Race: shift opened concurrently.
      }
    } else {
      await _shifts.closeActiveShiftForLocalUser(localUserId, 0);
    }
  }
}
