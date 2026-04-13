import 'package:flutter/material.dart';

import '../../../../core/formatting/peso_currency.dart';
import '../../state/reports_cubit.dart';

/// **Today** tab — open shift metrics from local DB (Tier 1).
class TodayShiftSummaryPanel extends StatelessWidget {
  const TodayShiftSummaryPanel({super.key, required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ReportsInitial() => const SizedBox.shrink(),
      ReportsLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ReportsError(:final message) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ReportsLoaded(:final todayShift) => _SummaryBody(snapshot: todayShift),
    };
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.snapshot});

  final ReportsTodaySnapshot snapshot;

  static String _shiftTitle(ReportsTodaySnapshot s) {
    final id = s.shiftId;
    if (id == null || id.isEmpty) return '—';
    final short = id.length > 12 ? '${id.substring(0, 8)}…' : id;
    final date = s.shiftDate.trim();
    if (date.isEmpty) return 'Shift $short';
    return 'Shift $short · $date';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peso = PesoCurrency.currency(decimalDigits: 0);

    if (!snapshot.hasOpenShift) {
      return Text(
        'No open cash shift. Open a shift to see live counts for the current day.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final site = [snapshot.branch.trim(), snapshot.area.trim()]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    final siteLine = site.isEmpty ? '—' : site;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Open shift', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          _shiftTitle(snapshot),
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(siteLine, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        _metricRow(context, 'Vehicles in', '${snapshot.vehiclesIn}'),
        _metricRow(context, 'Checked out (this shift)', '${snapshot.checkedOut}'),
        _metricRow(
          context,
          'Revenue (checkout shift)',
          peso.format(snapshot.revenue),
        ),
        _metricRow(
          context,
          'Checkout transactions',
          '${snapshot.revenueCheckoutCount}',
        ),
      ],
    );
  }

  static Widget _metricRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
