import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../../../core/config/app_config.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/time/philippine_time.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/rate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_out/domain/checkout_pricing.dart';
import '../domain/reports_date_query.dart';
import '../domain/reports_format.dart';
import '../domain/reports_models.dart';
import '../domain/reports_row_builder.dart';
import '../../../shared/domain/transaction_list_merge.dart';

/// Lightweight shift context for reports (flat-block hours, open-shift gate).
class ReportsShiftContext extends Equatable {
  const ReportsShiftContext({
    required this.hasOpenShift,
    this.flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
  });

  static const idle = ReportsShiftContext(hasOpenShift: false);

  final bool hasOpenShift;
  final int flatBlockHours;

  @override
  List<Object?> get props => [hasOpenShift, flatBlockHours];
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
    required this.rows,
    required this.shift,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.limit,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isOffline = false,
    this.serverError,
    this.usedLocalFallback = false,
  });

  final List<ReportsTicketRow> rows;
  final ReportsShiftContext shift;
  final int total;
  final int page;
  final int totalPages;
  final int limit;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isOffline;
  final String? serverError;

  /// True when list came from Drift instead of `GET /reports/transactions`.
  final bool usedLocalFallback;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [
        rows,
        shift,
        total,
        page,
        totalPages,
        limit,
        isLoadingMore,
        isRefreshing,
        isOffline,
        serverError,
        usedLocalFallback,
      ];
}

final class ReportsError extends ReportsState {
  const ReportsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Filter bundle for [ReportsCubit.load].
class ReportsListQuery extends Equatable {
  const ReportsListQuery({
    this.search = '',
    this.statusFilter = 'All Status',
    this.dateRange,
    this.page = 1,
    this.limit = 20,
  });

  final String search;
  final String statusFilter;
  final DateTimeRange? dateRange;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [search, statusFilter, dateRange, page, limit];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({
    required AuthRepository authRepository,
    required TicketService ticketService,
    required TransactionsApi transactionsApi,
    required RateService rateService,
  })  : _auth = authRepository,
        _tickets = ticketService,
        _api = transactionsApi,
        _rates = rateService,
        super(const ReportsInitial());

  final AuthRepository _auth;
  final TicketService _tickets;
  final TransactionsApi _api;
  final RateService _rates;

  /// Maps Reports filter labels to Swagger `status` values on
  /// `GET /api/v1/reports/transactions`.
  static String? apiStatusFromUiFilter(String filter) {
    return switch (filter) {
      'Parked' => 'active',
      'Long Stay' => 'long_stay',
      'Checked Out' => 'completed',
      _ => null,
    };
  }

  Future<ReportsShiftContext> _shiftContext(Session session) async {
    final shift = await _auth.getOpenShiftForUser(session.userId);
    if (shift == null) return ReportsShiftContext.idle;
    var flatBlockHours = CheckoutPricing.defaultFlatBlockHours;
    final branchId = shift.branchId.trim();
    final resolved = await _rates.checkoutRatesResolved(
      branchId: branchId.isEmpty ? '_' : branchId,
    );
    if (resolved != null) {
      flatBlockHours = resolved.flatBlockHours;
    }
    return ReportsShiftContext(
      hasOpenShift: true,
      flatBlockHours: flatBlockHours,
    );
  }

  List<ReportsTicketRow> _filterLocalRows({
    required List<ReportsTicketRow> rows,
    required ReportsListQuery query,
  }) {
    final needle = query.search.trim().toLowerCase();
    return rows
        .where((r) {
          if (needle.isEmpty) return true;
          return r.ticketId.toLowerCase().contains(needle) ||
              r.plate.toLowerCase().contains(needle) ||
              r.vehicle.toLowerCase().contains(needle);
        })
        .where((r) => _matchesUiStatus(r, query.statusFilter))
        .where((r) {
          final range = query.dateRange;
          if (range == null) return true;
          return ReportsDateQuery.containsCheckIn(r.timeIn, range);
        })
        .toList(growable: false);
  }

  static bool _matchesUiStatus(ReportsTicketRow r, String filter) {
    return switch (filter) {
      'Parked' => r.status == ReportsTicketRowStatus.parked,
      'Long Stay' => r.status == ReportsTicketRowStatus.longStay,
      'Checked Out' => r.status == ReportsTicketRowStatus.checkedOut,
      _ => true,
    };
  }

  Future<List<ReportsTicketRow>> _localRows({
    required Session session,
    required ReportsShiftContext shift,
    required ReportsListQuery query,
  }) async {
    final openShift = await _auth.getOpenShiftForUser(session.userId);
    List<Ticket> tickets;
    if (openShift != null) {
      tickets = await _tickets.ticketsForShift(openShift.id);
    } else {
      final range = query.dateRange ?? _todayRange();
      tickets = await _tickets.ticketsWithCheckInInRange(
        start: range.start,
        end: range.end,
      );
    }
    final built = tickets
        .map(
          (t) => ReportsRowBuilder.fromTicket(
            t,
            flatBlockHours: shift.flatBlockHours,
          ),
        )
        .toList(growable: false);
    return _filterLocalRows(rows: built, query: query);
  }

  DateTimeRange _todayRange() {
    final ph = PhilippineTime.now();
    final s = DateTime(ph.year, ph.month, ph.day);
    return DateTimeRange(start: s, end: s.add(const Duration(days: 1)));
  }

  /// Loads transactions from `GET /reports/transactions` when online; else local Drift.
  Future<void> load(ReportsListQuery query, {bool append = false}) async {
    final session = await _auth.getActiveSession();
    if (session == null) {
      emit(const ReportsError('No active session.'));
      return;
    }

    final shift = await _shiftContext(session);
    if (!shift.hasOpenShift) {
      emit(
        ReportsLoaded(
          rows: const [],
          shift: shift,
          total: 0,
          page: 1,
          totalPages: 0,
          limit: query.limit,
          serverError: 'Open a cash shift to view transactions.',
        ),
      );
      return;
    }

    final openShift = await _auth.getOpenShiftForUser(session.userId);
    if (openShift != null) {
      await _tickets.purgeOrphanedDrafts(openShift.id);
    }

    final prev = state;
    if (append && prev is ReportsLoaded) {
      emit(prev.copyWith(isLoadingMore: true, serverError: null));
    } else if (prev is! ReportsLoaded) {
      emit(const ReportsLoading());
    } else {
      emit(prev.copyWith(isRefreshing: true, serverError: null));
    }

    final online = await InternetReachability.hasInternet();
    final token = session.authToken?.trim() ?? '';
    final canUseApi = online &&
        token.isNotEmpty &&
        !session.isOfflineSession &&
        !AppConfig.useStubApi;

    if (canUseApi) {
      try {
        final range = query.dateRange;
        final dateBounds =
            range != null ? ReportsDateQuery.apiBounds(range) : null;
        final page = await _api.fetchReportsTransactions(
          token: token,
          search: query.search,
          status: apiStatusFromUiFilter(query.statusFilter),
          dateFrom: dateBounds?.dateFrom,
          dateTo: dateBounds?.dateTo,
          limit: query.limit,
          page: query.page,
        );

        final serverUserId =
            await _auth.serverUserIdForLocalAccount(session.userId);
        final filteredRows = page.rows
            .where(
              (r) =>
                  r.cashierId == null ||
                  serverUserId == null ||
                  r.cashierId == serverUserId,
            )
            .toList();

        if (openShift != null) {
          final cacheRows = filteredRows
              .map(_reportsRowCacheJson)
              .where((m) => (m['id']?.toString().trim().isNotEmpty ?? false))
              .toList();
          if (cacheRows.isNotEmpty) {
            await _tickets.cacheTransactionsFromServerJsonList(
              rows: cacheRows,
              shiftId: openShift.id,
            );
          }
        }

        List<ReportsTicketRow> merged;
        var adjustedTotal = page.total;
        if (append && prev is ReportsLoaded) {
          merged = [...prev.rows, ...filteredRows];
        } else {
          final local = await _localRows(
            session: session,
            shift: shift,
            query: query,
          );
          merged = TransactionListMerge.mergeReportsRows(
            server: filteredRows,
            local: local,
          );
          final extras = merged.length - filteredRows.length;
          if (extras > 0) adjustedTotal = page.total + extras;
        }

        emit(
          ReportsLoaded(
            rows: merged,
            shift: shift,
            total: adjustedTotal,
            page: page.page,
            totalPages: page.totalPages,
            limit: page.limit,
            isOffline: false,
            usedLocalFallback: false,
          ),
        );
        return;
      } catch (e) {
        if (!append) {
          final local = await _localRows(
            session: session,
            shift: shift,
            query: query,
          );
          emit(
            ReportsLoaded(
              rows: local,
              shift: shift,
              total: local.length,
              page: 1,
              totalPages: 1,
              limit: query.limit,
              isOffline: !online,
              serverError: online
                  ? 'Could not reach server — showing local records.'
                  : null,
              usedLocalFallback: true,
            ),
          );
          return;
        }
        if (prev is ReportsLoaded) {
          emit(
            prev.copyWith(
              isLoadingMore: false,
              serverError: 'Could not load more: $e',
            ),
          );
        }
        return;
      }
    }

    final local = await _localRows(
      session: session,
      shift: shift,
      query: query,
    );
    emit(
      ReportsLoaded(
        rows: local,
        shift: shift,
        total: local.length,
        page: 1,
        totalPages: 1,
        limit: query.limit,
        isOffline: !online,
        usedLocalFallback: true,
      ),
    );
  }

  Future<void> loadMore(ReportsListQuery query) async {
    final s = state;
    if (s is! ReportsLoaded || !s.hasMore || s.isLoadingMore || s.usedLocalFallback) {
      return;
    }
    await load(
      query.copyWithPage(s.page + 1),
      append: true,
    );
  }

  static Map<String, dynamic> _reportsRowCacheJson(ReportsTicketRow row) {
    final serverId = row.serverTransactionId?.trim() ?? '';
    final status = switch (row.status) {
      ReportsTicketRowStatus.parked => 'parked',
      ReportsTicketRowStatus.longStay => 'long_stay',
      ReportsTicketRowStatus.checkedOut => 'completed',
    };
    return <String, dynamic>{
      'id': serverId,
      'ticket_number': row.ticketId,
      'status': status,
      if (row.fee != null) 'amount': row.fee,
      'time_in': row.timeIn.toIso8601String(),
      if (row.timeOut != null) 'time_out': row.timeOut!.toIso8601String(),
      'vehicle': <String, dynamic>{
        'plate_number': row.plate,
        if (row.vehicle.trim().isNotEmpty) 'brand': row.vehicle.trim(),
      },
      if (row.vrNo.trim().isNotEmpty && row.vrNo != '—') 'vr_no': row.vrNo,
      'parking': <String, dynamic>{'slot': row.slot},
    };
  }
}

extension on ReportsListQuery {
  ReportsListQuery copyWithPage(int page) {
    return ReportsListQuery(
      search: search,
      statusFilter: statusFilter,
      dateRange: dateRange,
      page: page,
      limit: limit,
    );
  }
}

extension on ReportsLoaded {
  ReportsLoaded copyWith({
    List<ReportsTicketRow>? rows,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? serverError,
  }) {
    return ReportsLoaded(
      rows: rows ?? this.rows,
      shift: shift,
      total: total,
      page: page,
      totalPages: totalPages,
      limit: limit,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline,
      serverError: serverError,
      usedLocalFallback: usedLocalFallback,
    );
  }
}
