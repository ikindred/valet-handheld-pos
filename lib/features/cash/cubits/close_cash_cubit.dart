import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/printing/close_cash_receipt_data.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../data/remote/dashboard_api.dart';
import '../../../data/remote/dashboard_summary.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/close_cash_purge_service.dart';
import '../../../data/services/shift_service.dart';
import '../../sync/state/sync_cubit.dart';
import '../domain/close_cash_prerequisites.dart';
import '../models/open_transaction.dart';
import 'close_cash_state.dart';

class CloseCashCubit extends Cubit<CloseCashState> {
  CloseCashCubit(
    this._auth,
    this._shifts,
    this._sync,
    this._dashboardApi,
    this._purge,
  ) : super(const CloseCashInitial());

  final AuthRepository _auth;
  final ShiftService _shifts;
  final SyncCubit _sync;
  final DashboardApi _dashboardApi;
  final CloseCashPurgeService _purge;

  CloseCashLoaded? _loaded;

  CloseCashLoaded? get lastLoaded => _loaded;

  Future<void> loadShift(int localUserId) async {
    emit(const CloseCashLoading());
    try {
      final shift = await _auth.getOpenShiftForUser(localUserId);
      if (shift == null) {
        emit(const CloseCashError('No open shift found.'));
        return;
      }
      final openRows = await _auth.queryOpenTicketsForShiftClose(shift.id);
      final openTx = openRows.map(OpenTransaction.fromTicket).toList();

      int? remoteCheckouts;
      int? remoteVehiclesIn;
      Map<String, int>? remoteByVehicleType;
      List<DashboardSummaryRecent>? recentCheckouts;
      final session = await _auth.getActiveSession();
      final token = session?.authToken?.trim() ?? '';
      if (token.isNotEmpty &&
          !AppConfig.useStubApi &&
          await InternetReachability.hasInternet()) {
        try {
          final summary =
              await _dashboardApi.fetchSummary(bearerToken: token);
          if (summary != null) {
            remoteCheckouts = summary.checkedOutTotal;
            remoteVehiclesIn = summary.totalVehiclesIn;
            remoteByVehicleType = summary.checkoutCountsByVehicleRateKey();
            recentCheckouts = summary.recent;
          }
        } catch (_) {
          // Fall back to local Drift stats.
        }
      }

      final stats = await _auth.loadCloseCashStatsForShift(
        shift,
        remoteCheckoutCount: remoteCheckouts,
        remoteVehiclesIn: remoteVehiclesIn,
        remoteByVehicleType: remoteByVehicleType,
        recentCheckouts: recentCheckouts,
      );

      final loaded = CloseCashLoaded(
        shift: shift,
        actualCash: 0,
        openTransactions: openTx,
        stats: stats,
      );
      _loaded = loaded;
      emit(loaded);
    } catch (e) {
      emit(CloseCashError(e.toString()));
    }
  }

  void updateActualCash(double amount) {
    final cur = _loaded;
    if (cur == null) return;
    final next = cur.copyWith(actualCash: amount);
    _loaded = next;
    emit(next);
  }

  Future<void> attemptCloseShift(int localUserId) async {
    final cur = _loaded;
    if (cur == null) return;
    final blocked = await _blockingReasonForClose(
      cur.shift.id,
      cur.shift.userId,
    );
    if (blocked != null) {
      emit(CloseCashBlocked(blocked));
      return;
    }
    await _executeCloseShift(localUserId);
  }

  Future<void> _executeCloseShift(int localUserId) async {
    final cur = _loaded;
    if (cur == null) return;

    final blockedBefore = await _blockingReasonForClose(
      cur.shift.id,
      cur.shift.userId,
    );
    if (blockedBefore != null) {
      emit(CloseCashBlocked(blockedBefore));
      return;
    }

    emit(const CloseCashConfirming());
    try {
      final site = await _auth.branchAndAreaFromDb();
      final acct = await _auth.offlineAccountById(localUserId);
      final closedShift = await _shifts.closeShift(
        shiftId: cur.shift.id,
        closingCash: cur.actualCash,
        awaitRemoteClose: true,
      );
      final blockedAfter = await _blockingReasonForClose(
        cur.shift.id,
        cur.shift.userId,
      );
      if (blockedAfter != null) {
        emit(CloseCashBlocked(blockedAfter));
        return;
      }

      final purgeResult = await _purge.purgeAfterCloseCash(
        closedShiftId: cur.shift.id,
      );
      ValetLog.debug(
        'CloseCashCubit',
        'purge after close: tickets=${purgeResult.deletedTickets} '
        'queue=${purgeResult.deletedQueueRows} shifts=${purgeResult.deletedShifts} '
        'sessions=${purgeResult.deletedSessions}',
      );

      final prefs = await SharedPreferences.getInstance();
      await OfflineModePrefs.write(prefs, false);

      final receipt = CloseCashReceiptData.fromClose(
        branch: site.branch,
        area: site.area,
        cashierName: acct?.fullName ?? acct?.email ?? '—',
        openedAtIso: cur.shift.openedAt,
        closedAtIso: closedShift.closedAt ?? closedShift.openedAt,
        stats: cur.stats,
        activeCheckInCount: cur.openTransactions.length,
        actualCash: cur.actualCash,
        isExpressCashier: cur.shift.isExpressCashier,
      );
      await _auth.confirmCloseCash(
        localUserId: localUserId,
        closingFloat: cur.actualCash,
      );
      await _purge.purgeEndedSessions();
      emit(CloseCashSuccess(receipt: receipt));
    } catch (e) {
      emit(CloseCashError(e.toString()));
    }
  }

  Future<String?> _blockingReasonForClose(
    String shiftId,
    String cashierUserId,
  ) {
    return CloseCashPrerequisites.blockingReason(
      shiftId: shiftId,
      hasInternet: InternetReachability.hasInternet,
      offlineModeEnabled: () async {
        final prefs = await SharedPreferences.getInstance();
        return OfflineModePrefs.read(prefs);
      },
      offlineSession: () async {
        final session = await _auth.getActiveSession();
        return session?.isOfflineSession ?? false;
      },
      flushSync: () => _sync.flush(),
      pendingSyncCount: () => _sync.pendingCount(),
      failedSyncCount: () => _sync.failedCount(),
      pendingTicketSyncCount: _purge.countPendingSyncTicketsForUser,
      cashierUserId: cashierUserId,
    );
  }

  void restoreLoadedAfterError() {
    if (_loaded != null) emit(_loaded!);
  }

  void dismissBlockedWarning() {
    if (_loaded != null) emit(_loaded!);
  }
}
