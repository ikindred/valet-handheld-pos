import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';

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

/// Tier 1 dashboard metrics — **local SQLite only** (no HTTP).
final class DashboardReady extends DashboardState {
  const DashboardReady({
    required this.vehiclesIn,
    required this.checkedOut,
    required this.checkInsLastHour,
    required this.todayRevenue,
    required this.revenueCheckoutCount,
    required this.activeSlotsUsed,
    required this.activeSlotsTotal,
    required this.recent,
  });

  final int vehiclesIn;
  final int checkedOut;

  /// Check-ins on this shift in the last rolling hour (`check_in_at`).
  final int checkInsLastHour;

  final double todayRevenue;
  final int revenueCheckoutCount;

  /// Occupied slots (here: same as [vehiclesIn]).
  final int activeSlotsUsed;

  /// Total capacity — not on `device_info` yet; default until area config exists.
  final int activeSlotsTotal;

  final List<DashboardRecentTx> recent;

  @override
  List<Object?> get props => [
        vehiclesIn,
        checkedOut,
        checkInsLastHour,
        todayRevenue,
        revenueCheckoutCount,
        activeSlotsUsed,
        activeSlotsTotal,
        recent,
      ];
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// One row for [DashboardTransactionRow] (derived from [Ticket] locally).
final class DashboardRecentTx extends Equatable {
  const DashboardRecentTx({
    required this.ticketId,
    required this.plate,
    required this.line1,
    required this.line2,
    required this.status,
  });

  /// Drift `tickets.id` (e.g. `TKT-0001`).
  final String ticketId;
  final String plate;
  final String line1;
  final String line2;
  final DashboardRecentStatus status;

  @override
  List<Object?> get props => [ticketId, plate, line1, line2, status];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AuthRepository authRepository,
    required TicketService ticketService,
  })  : _auth = authRepository,
        _tickets = ticketService,
        super(const DashboardInitial());

  final AuthRepository _auth;
  final TicketService _tickets;

  /// Default slot capacity until branch/area config exposes a real total (cached at login).
  static const int defaultAreaSlotCapacity = 30;

  /// Reload all dashboard metrics from Drift (no network).
  Future<void> refresh() async {
    emit(const DashboardLoading());
    try {
      final session = await _auth.getActiveSession();
      if (session == null) {
        emit(const DashboardError('No active session.'));
        return;
      }
      final shift = await _auth.getOpenShiftForUser(session.userId);
      if (shift == null) {
        emit(
          const DashboardReady(
            vehiclesIn: 0,
            checkedOut: 0,
            checkInsLastHour: 0,
            todayRevenue: 0,
            revenueCheckoutCount: 0,
            activeSlotsUsed: 0,
            activeSlotsTotal: defaultAreaSlotCapacity,
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
      final todayRevenue = await _auth.sumSalesForCheckoutShift(shiftId);
      final revenueCheckoutCount =
          await _auth.countCompletedForCheckoutShift(shiftId);
      final rawRecent = await _tickets.recentTicketsForShift(shiftId, limit: 10);
      final recent = rawRecent.map(_recentFromTicket).toList();

      emit(
        DashboardReady(
          vehiclesIn: vehiclesIn,
          checkedOut: checkedOut,
          checkInsLastHour: checkInsLastHour,
          todayRevenue: todayRevenue,
          revenueCheckoutCount: revenueCheckoutCount,
          activeSlotsUsed: vehiclesIn,
          activeSlotsTotal: defaultAreaSlotCapacity,
          recent: recent,
        ),
      );
    } catch (e) {
      emit(DashboardError('Could not load dashboard: $e'));
    }
  }

  static DashboardRecentTx _recentFromTicket(Ticket t) {
    final timeFmt = DateFormat.jm();
    final plate =
        t.plateNumber.trim().isNotEmpty ? t.plateNumber.trim() : t.id;
    final parts = <String>[
      if (t.vehicleBrand.trim().isNotEmpty) t.vehicleBrand.trim(),
      if (t.vehicleColor.trim().isNotEmpty) t.vehicleColor.trim(),
      if (t.vehicleType.trim().isNotEmpty) t.vehicleType.trim(),
    ];
    final line1 = parts.isEmpty ? '—' : parts.join(' · ');
    final inLocal =
        DateTime.tryParse(t.checkInAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
    if (t.status == 'completed') {
      final fee = t.fee;
      final feeStr =
          fee != null
              ? '${PesoCurrency.symbol}${NumberFormat('#,##0').format(fee)}'
              : '—';
      final outLocal = DateTime.tryParse(t.checkOutAt ?? '') ?? inLocal;
      return DashboardRecentTx(
        ticketId: t.id,
        plate: plate,
        line1: line1,
        line2: 'Out at ${timeFmt.format(outLocal)} — $feeStr',
        status: DashboardRecentStatus.checkedOut,
      );
    }
    return DashboardRecentTx(
      ticketId: t.id,
      plate: plate,
      line1: line1,
      line2: 'In at ${timeFmt.format(inLocal)} — ${t.id}',
      status: DashboardRecentStatus.parked,
    );
  }
}
