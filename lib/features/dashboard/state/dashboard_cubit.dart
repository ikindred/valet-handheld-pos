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

/// One row for the dashboard recent-transaction table.
final class DashboardRecentTx extends Equatable {
  const DashboardRecentTx({
    required this.ticketId,
    required this.plate,
    required this.plateNumber,
    required this.ticketNumber,
    required this.line1,
    required this.line2,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.slot = '—',
    this.vrNo = '—',
    this.hasPendingVoid = false,
    this.isVoided = false,
  });

  final String ticketId;
  /// Blue badge label — plate number if available, else ticket number.
  final String plate;
  /// Actual plate number (empty string if unknown); shown in blue badge.
  final String plateNumber;
  /// Formatted ticket number (e.g. TKT-0123); shown in orange badge.
  final String ticketNumber;
  final String line1;
  final String line2;
  final DashboardRecentStatus status;
  final DateTime? timeIn;
  final DateTime? timeOut;
  /// Raw slot code (e.g. "LT101"); "—" when unknown.
  final String slot;

  /// Valet receipt number (`vr_no`); "—" when unset.
  final String vrNo;

  /// True when void-at-intake is queued locally (offline sync pending).
  final bool hasPendingVoid;

  /// True when the transaction is voided.
  final bool isVoided;

  factory DashboardRecentTx.fromSummaryRow(DashboardRecentRow row) {
    return DashboardRecentTx(
      ticketId: row.ticketId,
      plate: row.plate,
      plateNumber: row.plateNumber,
      ticketNumber: row.ticketNumber,
      line1: row.line1,
      line2: row.line2,
      status: row.isCheckedOut
          ? DashboardRecentStatus.checkedOut
          : DashboardRecentStatus.parked,
      vrNo: '—',
    );
  }

  factory DashboardRecentTx.fromSummaryRecent(DashboardSummaryRecent r) {
    final actualPlate =
        r.plateNumber.isNotEmpty && r.plateNumber != '—' ? r.plateNumber : '';
    final badgePlate = actualPlate.isNotEmpty ? actualPlate : r.ticketNumber;
    final upper = r.status.toUpperCase();
    final completed = upper == 'COMPLETED' || upper == 'LOST';
    final line1 = DashboardRecentFormat.vehicleLine(
      brand: r.vehicleBrand,
      color: r.vehicleColor,
    );
    final timeIn = DateTime.tryParse(r.timeIn ?? '')?.toLocal();
    final timeOut = DateTime.tryParse(r.timeOut ?? '')?.toLocal();
    final rawSlot = r.parkingSlot?.trim() ?? '';
    final slot = rawSlot.isEmpty ? '—' : rawSlot;
    final vr = r.vrNo?.trim() ?? '';
    final vrNo = vr.isEmpty ? '—' : vr;

    if (completed) {
      final inn = timeIn ?? DateTime.now();
      final out = timeOut ?? inn;
      return DashboardRecentTx(
        ticketId: r.id,
        plate: badgePlate,
        plateNumber: actualPlate,
        ticketNumber: r.ticketNumber,
        line1: line1,
        line2: DashboardRecentFormat.checkedOutSubline(inn, out),
        status: DashboardRecentStatus.checkedOut,
        timeIn: inn,
        timeOut: out,
        slot: slot,
        vrNo: vrNo,
        hasPendingVoid: r.hasPendingVoid,
        isVoided: r.isVoided,
      );
    }

    final inn = timeIn ?? DateTime.now();
    return DashboardRecentTx(
      ticketId: r.id,
      plate: badgePlate,
      plateNumber: actualPlate,
      ticketNumber: r.ticketNumber,
      line1: line1,
      line2: DashboardRecentFormat.parkedSubline(inn, slot: r.parkingSlot),
      status: DashboardRecentStatus.parked,
      timeIn: inn,
      slot: slot,
      vrNo: vrNo,
      hasPendingVoid: r.hasPendingVoid,
      isVoided: r.isVoided,
    );
  }

  @override
  List<Object?> get props => [
        ticketId,
        plate,
        plateNumber,
        ticketNumber,
        line1,
        line2,
        status,
        timeIn,
        timeOut,
        slot,
        vrNo,
        hasPendingVoid,
        isVoided,
      ];
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
    final keepVisible = state is DashboardReady;
    if (!keepVisible) {
      emit(const DashboardLoading());
    }
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
            final serverUserId =
                await _auth.serverUserIdForLocalAccount(session.userId);
            emit(_readyFromSummary(
              summary,
              checkInsLastHour,
              areaSlots: areaSlots,
              serverUserId: serverUserId,
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
    String? serverUserId,
  }) {
    var remaining = summary.remainingCount;
    var total = summary.totalSlots;
    if (areaSlots != null && areaSlots.total > 0) {
      total = areaSlots.total;
    }
    final filteredRecent = summary.recent
        .where(
          (r) =>
              r.cashierId == null ||
              serverUserId == null ||
              r.cashierId == serverUserId,
        )
        .toList();
    return DashboardReady(
      vehiclesIn: summary.totalVehiclesIn,
      checkedOut: summary.checkedOutTotal,
      checkInsLastHour: checkInsLastHour,
      remainingSlots: remaining,
      totalSlots: total,
      recent: _sortRecentParkedFirst(
        filteredRecent
            .map((r) => DashboardRecentTx.fromSummaryRecent(r))
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
    final actualPlate = t.plateNumber.trim();
    final badgePlate = actualPlate.isNotEmpty ? actualPlate : t.id;
    final line1 = DashboardRecentFormat.vehicleLineFromTicket(t);
    final inLocal =
        DateTime.tryParse(t.checkInAt)?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0);
    final rawSlot = DashboardRecentFormat.slotSuffix(parkingJson: t.parkingInfo);
    final slot = rawSlot == '—'
        ? '—'
        : rawSlot.toLowerCase().startsWith('slot ')
            ? rawSlot.substring(5).trim()
            : rawSlot;
    final vrRaw = t.vrNo?.trim() ?? '';
    final vrNo = vrRaw.isEmpty ? '—' : vrRaw;
    if (t.status == 'completed') {
      final outLocal =
          DateTime.tryParse(t.checkOutAt ?? '')?.toLocal() ?? inLocal;
      return DashboardRecentTx(
        ticketId: t.id,
        plate: badgePlate,
        plateNumber: actualPlate,
        ticketNumber: t.id,
        line1: line1,
        line2: DashboardRecentFormat.checkedOutSubline(inLocal, outLocal),
        status: DashboardRecentStatus.checkedOut,
        timeIn: inLocal,
        timeOut: outLocal,
        slot: slot,
        vrNo: vrNo,
        hasPendingVoid: t.pendingVoidRequest,
        isVoided: t.status == 'void',
      );
    }
    return DashboardRecentTx(
      ticketId: t.id,
      plate: badgePlate,
      plateNumber: actualPlate,
      ticketNumber: t.id,
      line1: line1,
      line2: DashboardRecentFormat.parkedSubline(
        inLocal,
        parkingJson: t.parkingInfo,
      ),
      status: DashboardRecentStatus.parked,
      timeIn: inLocal,
      slot: slot,
      vrNo: vrNo,
      hasPendingVoid: t.pendingVoidRequest,
      isVoided: t.status == 'void',
    );
  }

}
