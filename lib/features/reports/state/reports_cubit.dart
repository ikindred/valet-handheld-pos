import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../../../core/connectivity/internet_reachability.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';

/// Local open-shift snapshot for the **Today** tab (same sources as Tier 1 dashboard).
class ReportsTodaySnapshot extends Equatable {
  const ReportsTodaySnapshot({
    required this.hasOpenShift,
    this.shiftId,
    this.shiftDate = '',
    this.branch = '',
    this.area = '',
    this.vehiclesIn = 0,
    this.checkedOut = 0,
    this.revenue = 0,
    this.revenueCheckoutCount = 0,
  });

  /// No open shift — metrics are zeroed.
  static const idle = ReportsTodaySnapshot(hasOpenShift: false);

  final bool hasOpenShift;
  final String? shiftId;
  final String shiftDate;
  final String branch;
  final String area;
  final int vehiclesIn;
  final int checkedOut;
  final double revenue;
  final int revenueCheckoutCount;

  @override
  List<Object?> get props => [
        hasOpenShift,
        shiftId,
        shiftDate,
        branch,
        area,
        vehiclesIn,
        checkedOut,
        revenue,
        revenueCheckoutCount,
      ];
}

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

final class ReportsLoaded extends ReportsState {
  const ReportsLoaded({
    required this.tickets,
    required this.todayShift,
    this.isServerSyncing = false,
    this.isOffline = false,
    this.serverError,
  });

  final List<Ticket> tickets;
  final ReportsTodaySnapshot todayShift;
  final bool isServerSyncing;
  final bool isOffline;
  final String? serverError;

  @override
  List<Object?> get props => [
        tickets,
        todayShift,
        isServerSyncing,
        isOffline,
        serverError,
      ];
}

final class ReportsError extends ReportsState {
  const ReportsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({
    required AuthRepository authRepository,
    required TicketService ticketService,
    required TransactionsApi transactionsApi,
  })  : _auth = authRepository,
        _tickets = ticketService,
        _api = transactionsApi,
        super(const ReportsInitial());

  final AuthRepository _auth;
  final TicketService _tickets;
  final TransactionsApi _api;

  bool _firstLocalReadyEmitted = false;

  DateTimeRange _todayRangeLocal() {
    final n = DateTime.now();
    final s = DateTime(n.year, n.month, n.day);
    return DateTimeRange(start: s, end: s.add(const Duration(days: 1)));
  }

  bool _isRangeTodayOnly(DateTimeRange r) {
    final t = _todayRangeLocal();
    return !r.start.isBefore(t.start) && !r.end.isAfter(t.end);
  }

  Future<List<Ticket>> _queryLocal({
    required Session session,
    DateTimeRange? dateRange,
    required bool currentShiftOnly,
  }) async {
    if (currentShiftOnly) {
      final shift = await _auth.getOpenShiftForUser(session.userId);
      if (shift == null) return [];
      return _tickets.ticketsForShift(shift.id);
    }
    final r = dateRange ?? _todayRangeLocal();
    return _tickets.ticketsWithCheckInInRange(
      start: r.start,
      end: r.end,
    );
  }

  Future<int> _cashierIdForSession(Session session) async {
    final acct = await _auth.offlineAccountById(session.userId);
    final sid = acct?.serverUserId;
    if (sid != null && sid > 0) return sid;
    return session.userId;
  }

  Future<ReportsTodaySnapshot> _buildTodaySnapshot(Session session) async {
    final shift = await _auth.getOpenShiftForUser(session.userId);
    if (shift == null) return ReportsTodaySnapshot.idle;
    final id = shift.id;
    final site = await _auth.branchAndAreaFromDb();
    final vehiclesIn = await _tickets.countActiveTicketsForShift(id);
    final checkedOut = await _tickets.countCompletedCheckoutsForShift(id);
    final revenue = await _auth.sumSalesForCheckoutShift(id);
    final revenueCheckoutCount =
        await _auth.countCompletedForCheckoutShift(id);
    final opened = DateTime.tryParse(shift.openedAt);
    return ReportsTodaySnapshot(
      hasOpenShift: true,
      shiftId: id,
      shiftDate: opened != null
          ? '${opened.year}-${opened.month.toString().padLeft(2, '0')}-${opened.day.toString().padLeft(2, '0')}'
          : '',
      branch: site.branch,
      area: site.area,
      vehiclesIn: vehiclesIn,
      checkedOut: checkedOut,
      revenue: revenue,
      revenueCheckoutCount: revenueCheckoutCount,
    );
  }

  /// Tier 2 load: local first, then optional background GET (server rows are not merged locally).
  Future<void> load({
    DateTimeRange? dateRange,
    bool currentShiftOnly = false,
  }) async {
    final session = await _auth.getActiveSession();
    if (session == null) {
      emit(const ReportsError('No active session.'));
      return;
    }

    if (!_firstLocalReadyEmitted) {
      emit(const ReportsLoading());
    }

    List<Ticket> localRows;
    try {
      localRows = await _queryLocal(
        session: session,
        dateRange: dateRange,
        currentShiftOnly: currentShiftOnly,
      );
    } catch (e) {
      emit(ReportsError('Could not read local tickets: $e'));
      return;
    }

    var todayShift = await _buildTodaySnapshot(session);

    _firstLocalReadyEmitted = true;
    emit(
      ReportsLoaded(
        tickets: localRows,
        todayShift: todayShift,
        isServerSyncing: false,
        isOffline: false,
        serverError: null,
      ),
    );

    final online = await InternetReachability.hasInternet();
    if (!online) {
      emit(
        ReportsLoaded(
          tickets: localRows,
          todayShift: todayShift,
          isServerSyncing: false,
          isOffline: true,
          serverError: null,
        ),
      );
      return;
    }

    final token = session.authToken;
    if (token == null || token.isEmpty || session.isOfflineSession) {
      return;
    }

    final effectiveRange = dateRange ?? _todayRangeLocal();
    if (currentShiftOnly || _isRangeTodayOnly(effectiveRange)) {
      return;
    }

    emit(
      ReportsLoaded(
        tickets: localRows,
        todayShift: todayShift,
        isServerSyncing: true,
        isOffline: false,
        serverError: null,
      ),
    );

    final dateFromUnix = effectiveRange.start.millisecondsSinceEpoch ~/ 1000;
    final dateToUnix = effectiveRange.end.millisecondsSinceEpoch ~/ 1000;

    try {
      final cashierId = await _cashierIdForSession(session);
      final site = await _auth.branchAndAreaFromDb();
      await _api.fetchTransactions(
        token: token,
        cashierId: cashierId,
        branch: site.branch,
        area: site.area,
        dateFromUnix: dateFromUnix,
        dateToUnix: dateToUnix,
      );
      todayShift = await _buildTodaySnapshot(session);
      emit(
        ReportsLoaded(
          tickets: localRows,
          todayShift: todayShift,
          isServerSyncing: false,
          isOffline: false,
          serverError: null,
        ),
      );
    } catch (_) {
      todayShift = await _buildTodaySnapshot(session);
      emit(
        ReportsLoaded(
          tickets: localRows,
          todayShift: todayShift,
          isServerSyncing: false,
          isOffline: false,
          serverError:
              'Could not load historical data — showing local records only.',
        ),
      );
    }
  }
}
