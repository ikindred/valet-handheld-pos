import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/config/app_config.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/logging/valet_log.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/area_detail.dart';
import '../../../data/remote/dashboard_api.dart';
import '../../../data/remote/dashboard_summary.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/rate_fetch_service.dart';
import '../../../data/services/ticket_service.dart';
import '../domain/dashboard_recent_format.dart';

/// Parked vs checked out for recent-transaction rows (UI maps to [TransactionStatusKind]).
enum DashboardRecentStatus { parked, checkedOut }

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard metrics from `GET /dashboard/summary` when online, else local SQLite.
final class DashboardReady extends DashboardState {
  const DashboardReady({
    required this.vehiclesIn,
    required this.checkedOut,
    required this.checkInsLastHour,
    required this.remainingSlots,
    required this.totalSlots,
    required this.recent,
  });

  final int vehiclesIn;
  final int checkedOut;

  /// Check-ins on this shift in the last rolling hour (`check_in_at`), local only.
  final int checkInsLastHour;

  /// Open slots (`remaining_count` from API, or derived offline).
  final int remainingSlots;

  /// Area capacity (`total_slots` from API, or default offline).
  final int totalSlots;

  final List<DashboardRecentTx> recent;

  @override
  List<Object?> get props => [
        vehiclesIn,
        checkedOut,
        checkInsLastHour,
        remainingSlots,
        totalSlots,
        recent,
      ];
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// One row for [DashboardTransactionRow] (API summary or local [Ticket]).
final class DashboardRecentTx extends Equatable {
  const DashboardRecentTx({
    required this.ticketId,
    required this.plate,
    required this.line1,
    required this.line2,
    required this.status,
  });

  final String ticketId;
  final String plate;
  final String line1;
  final String line2;
  final DashboardRecentStatus status;

  factory DashboardRecentTx.fromSummaryRow(DashboardRecentRow row) {
    return DashboardRecentTx(
      ticketId: row.ticketId,
      plate: row.plate,
      line1: row.line1,
      line2: row.line2,
      status: row.isCheckedOut
          ? DashboardRecentStatus.checkedOut
          : DashboardRecentStatus.parked,
    );
  }

  @override
  List<Object?> get props => [ticketId, plate, line1, line2, status];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AuthRepository authRepository,
    required TicketService ticketService,
    required DashboardApi dashboardApi,
    required RateFetchService rateFetchService,
  })  : _auth = authRepository,
        _tickets = ticketService,
        _dashboardApi = dashboardApi,
        _rateFetch = rateFetchService,
        super(const DashboardInitial());

  final AuthRepository _auth;
  final TicketService _tickets;
  final DashboardApi _dashboardApi;
  final RateFetchService _rateFetch;

  /// Default slot capacity when API / area config is unavailable offline.
  static const int defaultAreaSlotCapacity = kDefaultDashboardTotalSlots;

  /// Reload dashboard: remote summary when online, else Drift.
  Future<void> refresh() async {
    emit(const DashboardLoading());
    try {
      final session = await _auth.getActiveSession();
      if (session == null) {
        emit(const DashboardError('No active session.'));
        return;
      }

      final token = session.authToken?.trim() ?? '';
      final hasInternet = await InternetReachability.hasInternet();

      if (hasInternet && !AppConfig.useStubApi && token.isNotEmpty) {
        try {
          final summary = await _dashboardApi.fetchSummary(bearerToken: token);
          if (summary != null) {
            final checkInsLastHour = await _checkInsLastHourForActiveShift(
              session.userId,
            );
            final areaSlots = await _slotCountsFromArea();
            emit(_readyFromSummary(
              summary,
              checkInsLastHour,
              areaSlots: areaSlots,
            ));
            return;
          }
        } catch (e, st) {
          ValetLog.error(
            'DashboardCubit.refresh',
            'dashboard/summary failed — using local',
            e,
            st,
          );
        }
      }

      await _refreshLocal(session.userId);
    } catch (e) {
      emit(DashboardError('Could not load dashboard: $e'));
    }
  }

  DashboardReady _readyFromSummary(
    DashboardSummary summary,
    int checkInsLastHour, {
    AreaSlotCounts? areaSlots,
  }) {
    var remaining = summary.remainingCount;
    var total = summary.totalSlots;
    if (areaSlots != null && areaSlots.total > 0) {
      total = areaSlots.total;
    }
    return DashboardReady(
      vehiclesIn: summary.totalVehiclesIn,
      checkedOut: summary.checkedOutTotal,
      checkInsLastHour: checkInsLastHour,
      remainingSlots: remaining,
      totalSlots: total,
      recent: _sortRecentParkedFirst(
        summary.recent
            .map((r) => DashboardRecentTx.fromSummaryRow(r.toRecentRow()))
            .toList(),
      ),
    );
  }

  /// Parked rows first; checked-out order preserved within each group.
  static List<DashboardRecentTx> _sortRecentParkedFirst(
    List<DashboardRecentTx> items,
  ) {
    final parked = <DashboardRecentTx>[];
    final checkedOut = <DashboardRecentTx>[];
    for (final tx in items) {
      if (tx.status == DashboardRecentStatus.parked) {
        parked.add(tx);
      } else {
        checkedOut.add(tx);
      }
    }
    return [...parked, ...checkedOut];
  }

  /// Slot capacity from area `levels[]` when branch/area UUIDs are set.
  Future<AreaSlotCounts?> _slotCountsFromArea() async {
    try {
      final branchUuid = await _auth.branchUuidForApi();
      final areaUuid = await _auth.areaUuidForApi();
      if (branchUuid.isEmpty || areaUuid.isEmpty) return null;
      final detail = await _rateFetch.fetchAreaDetail(
        branchId: branchUuid,
        areaId: areaUuid,
      );
      if (detail == null || detail.levels.isEmpty) return null;
      return detail.slotCounts;
    } catch (e, st) {
      ValetLog.error(
        'DashboardCubit._slotCountsFromArea',
        'area detail slots failed',
        e,
        st,
      );
      return null;
    }
  }

  Future<int> _checkInsLastHourForActiveShift(int localUserId) async {
    final shift = await _auth.getOpenShiftForUser(localUserId);
    if (shift == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final since = now - 3600;
    final sinceIso =
        DateTime.fromMillisecondsSinceEpoch(since * 1000).toIso8601String();
    return _tickets.countCheckInsOnShiftSince(
      shiftId: shift.id,
      sinceIso8601: sinceIso,
    );
  }

  Future<void> _refreshLocal(int localUserId) async {
    final shift = await _auth.getOpenShiftForUser(localUserId);
    if (shift == null) {
      emit(
        const DashboardReady(
          vehiclesIn: 0,
          checkedOut: 0,
          checkInsLastHour: 0,
          remainingSlots: defaultAreaSlotCapacity,
          totalSlots: defaultAreaSlotCapacity,
          recent: [],
        ),
      );
      return;
    }
    final shiftId = shift.id;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final since = now - 3600;
    final sinceIso =
        DateTime.fromMillisecondsSinceEpoch(since * 1000).toIso8601String();

    final vehiclesIn = await _tickets.countActiveTicketsForShift(shiftId);
    final checkedOut =
        await _tickets.countCompletedCheckoutsForShift(shiftId);
    final checkInsLastHour = await _tickets.countCheckInsOnShiftSince(
      shiftId: shiftId,
      sinceIso8601: sinceIso,
    );
    final rawRecent = await _tickets.recentTicketsForShift(shiftId, limit: 10);
    final recent = _sortRecentParkedFirst(
      rawRecent.map(_recentFromTicket).toList(),
    );

    final areaSlots = await _slotCountsFromArea();
    final total = areaSlots != null && areaSlots.total > 0
        ? areaSlots.total
        : defaultAreaSlotCapacity;
    final remaining = areaSlots != null && areaSlots.total > 0
        ? areaSlots.available
        : (total - vehiclesIn).clamp(0, total);

    emit(
      DashboardReady(
        vehiclesIn: vehiclesIn,
        checkedOut: checkedOut,
        checkInsLastHour: checkInsLastHour,
        remainingSlots: remaining,
        totalSlots: total,
        recent: recent,
      ),
    );
  }

  static DashboardRecentTx _recentFromTicket(Ticket t) {
    final plate =
        t.plateNumber.trim().isNotEmpty ? t.plateNumber.trim() : t.id;
    final line1 = DashboardRecentFormat.vehicleLineFromTicket(t);
    final inLocal =
        DateTime.tryParse(t.checkInAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
    if (t.status == 'completed') {
      final outLocal = DateTime.tryParse(t.checkOutAt ?? '') ?? inLocal;
      return DashboardRecentTx(
        ticketId: t.id,
        plate: plate,
        line1: line1,
        line2: DashboardRecentFormat.checkedOutSubline(outLocal, t.fee),
        status: DashboardRecentStatus.checkedOut,
      );
    }
    return DashboardRecentTx(
      ticketId: t.id,
      plate: plate,
      line1: line1,
      line2: DashboardRecentFormat.parkedSubline(
        inLocal,
        parkingJson: t.parkingInfo,
      ),
      status: DashboardRecentStatus.parked,
    );
  }
}
