import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/philippine_time.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/offline_data_banner.dart';
import '../../auth/state/auth_bloc.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../domain/reports_models.dart';
import '../state/reports_cubit.dart';
import 'widgets/reports_date_range_picker.dart';
import 'widgets/reports_widgets.dart';

/// Reports — `GET /api/v1/reports/transactions` (Figma node 76-2680).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'All Status';
  DateTimeRange? _dateRange;
  Timer? _searchDebounce;

  ReportsListQuery get _query => ReportsListQuery(
        search: _searchCtrl.text,
        statusFilter: _statusFilter,
        dateRange: _dateRange,
      );

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  void _reload() {
    if (!mounted) return;
    unawaited(context.read<ReportsCubit>().load(_query));
  }

  Future<void> _pickDateRange() async {
    final ph = PhilippineTime.now();
    final today = DateTime(ph.year, ph.month, ph.day);
    final result = await showReportsDateRangePicker(
      context,
      initialRange: _dateRange,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (!mounted) return;
    switch (result) {
      case null:
      case ReportsDateRangePickerCancelled():
        return;
      case ReportsDateRangePickerCleared():
        setState(() => _dateRange = null);
      case ReportsDateRangePickerApplied(:final range):
        setState(() {
          _dateRange = DateTimeRange(
            start: DateTime(range.start.year, range.start.month, range.start.day),
            end: DateTime(range.end.year, range.end.month, range.end.day)
                .add(const Duration(days: 1)),
          );
        });
    }
    _reload();
  }

  void _clearDateRange() {
    if (_dateRange == null) return;
    setState(() => _dateRange = null);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardLeftRail(),
          Expanded(
            child: SafeArea(
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _ReportsHeaderRow(
                      showSyncSpinner: _isRefreshing(context),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ReportsTransactionsTabStrip(),
                  ),
                  Expanded(
                    child: BlocBuilder<ReportsCubit, ReportsState>(
                      builder: (context, state) {
                        return switch (state) {
                          ReportsInitial() =>
                            const Center(child: SizedBox.shrink()),
                          ReportsLoading() => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ReportsError(:final message) =>
                            Center(child: Text(message)),
                          ReportsLoaded() => _ReportsTransactionsBody(
                              state: state,
                              searchController: _searchCtrl,
                              statusFilter: _statusFilter,
                              dateRangeLabel: _dateRangeLabel(),
                              onStatusFilterChanged: (v) {
                                setState(() => _statusFilter = v);
                                _reload();
                              },
                              onDateRangeTap: _pickDateRange,
                              onDateRangeClear: _clearDateRange,
                              onRowTap: (row) => _openTransactionDetail(context, row),
                              onLoadMore: state.hasMore && !state.isLoadingMore
                                  ? () => unawaited(
                                        context.read<ReportsCubit>().loadMore(_query),
                                      )
                                  : null,
                            ),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _dateRangeLabel() {
    final r = _dateRange;
    if (r == null) return null;
    final fmt = DateFormat('MM/dd/yyyy');
    final endInclusive = r.end.subtract(const Duration(days: 1));
    return '${fmt.format(r.start)} - ${fmt.format(endInclusive)}';
  }

  static bool _isRefreshing(BuildContext context) {
    final s = context.read<ReportsCubit>().state;
    return s is ReportsLoaded && s.isRefreshing;
  }

  static void _openTransactionDetail(BuildContext context, ReportsTicketRow row) {
    final id = row.detailId.trim();
    if (id.isEmpty) return;
    context.push('/dashboard/ticket/${Uri.encodeComponent(id)}');
  }
}

class _ReportsHeaderRow extends StatefulWidget {
  const _ReportsHeaderRow({required this.showSyncSpinner});

  final bool showSyncSpinner;

  @override
  State<_ReportsHeaderRow> createState() => _ReportsHeaderRowState();
}

class _ReportsHeaderRowState extends State<_ReportsHeaderRow> {
  String _firstName = '';
  String _siteSubtitle = '';

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthBloc>().state;
    final repo = context.read<AuthRepository>();
    var firstName = '';
    final prefs = await SharedPreferences.getInstance();
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    var siteLine = await repo.dateAndSiteLine(prefs, dateLabel);
    if (auth is AuthAuthenticated && auth.userId != null) {
      final id = int.tryParse(auth.userId!);
      if (id != null) {
        final acct = await repo.offlineAccountById(id);
        if (!mounted) return;
        if (acct != null) {
          final parts = acct.fullName.trim().split(RegExp(r'\s+'));
          firstName = parts.isEmpty ? '' : parts.first;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _firstName = firstName;
      _siteSubtitle = siteLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    final namePart = _firstName.isEmpty ? '…' : _firstName;
    final sub = _siteSubtitle.isEmpty
        ? '${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())} · —'
        : _siteSubtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DashboardScreen.greetingWord()}, $namePart',
                style: DashboardStyles.greetingOf(context),
              ),
              const SizedBox(height: 3),
              Text(sub, style: DashboardStyles.headerSubtitleOf(context)),
            ],
          ),
        ),
        if (widget.showSyncSpinner) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ],
        const DashboardStatusPillLive(),
      ],
    );
  }
}

class _ReportsTransactionsBody extends StatelessWidget {
  const _ReportsTransactionsBody({
    required this.state,
    required this.searchController,
    required this.statusFilter,
    required this.dateRangeLabel,
    required this.onStatusFilterChanged,
    required this.onDateRangeTap,
    this.onDateRangeClear,
    required this.onRowTap,
    this.onLoadMore,
  });

  final ReportsLoaded state;
  final TextEditingController searchController;
  final String statusFilter;
  final String? dateRangeLabel;
  final ValueChanged<String> onStatusFilterChanged;
  final VoidCallback onDateRangeTap;
  final VoidCallback? onDateRangeClear;
  final void Function(ReportsTicketRow row) onRowTap;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final countLabel = state.usedLocalFallback ? state.rows.length : state.total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isOffline || state.serverError != null) ...[
            OfflineDataBanner(
              isOffline: state.isOffline,
              serverError: state.serverError,
            ),
            const SizedBox(height: 10),
          ],
          ReportsTransactionsFilterBar(
            searchController: searchController,
            statusFilter: statusFilter,
            dateRangeLabel: dateRangeLabel,
            onStatusFilterChanged: onStatusFilterChanged,
            onDateRangeTap: onDateRangeTap,
            onDateRangeClear: onDateRangeClear,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportsTransactionsTableCard(
                    rowCount: countLabel,
                    rows: state.rows,
                    onRowTap: onRowTap,
                  ),
                  if (onLoadMore != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: state.isLoadingMore ? null : onLoadMore,
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Load more (page ${state.page} of ${state.totalPages})',
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
