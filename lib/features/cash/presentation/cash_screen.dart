import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/offline_data_banner.dart';
import '../../reports/presentation/widgets/today_shift_summary_panel.dart';
import '../../reports/state/reports_cubit.dart';

/// Cash area placeholder with **Today** / **Transactions** tabs (Tier-2 banner only on Transactions).
///
/// Open / close cash flows stay on dedicated routes; this screen is for a future shell or deep link.
class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ReportsCubit>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cash'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Today'),
              Tab(
                child: BlocBuilder<ReportsCubit, ReportsState>(
                  buildWhen: (p, n) =>
                      _syncing(p) != _syncing(n) || p.runtimeType != n.runtimeType,
                  builder: (context, state) {
                    return OfflineDataTabTitle(
                      label: 'Transactions',
                      showSpinner: _syncing(state),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                BlocBuilder<ReportsCubit, ReportsState>(
                  builder: (context, state) {
                    return TodayShiftSummaryPanel(state: state);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Use Transactions for the ticket list and optional background sync.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, state) {
                return switch (state) {
                  ReportsInitial() => const Center(child: SizedBox.shrink()),
                  ReportsLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  ReportsError(:final message) => Center(child: Text(message)),
                  ReportsLoaded(
                    :final tickets,
                    :final isOffline,
                    :final serverError,
                  ) =>
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        OfflineDataBanner(
                          isOffline: isOffline,
                          serverError: serverError,
                        ),
                        Text(
                          '${tickets.length} ticket(s)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...tickets.take(50).map(
                              (t) => ListTile(
                                dense: true,
                                title: Text(t.id),
                                subtitle: Text(t.plateNumber),
                              ),
                            ),
                      ],
                    ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }

  static bool _syncing(ReportsState s) =>
      s is ReportsLoaded && s.isServerSyncing;
}
