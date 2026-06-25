import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'branch_rates_slots_header_actions.dart';

/// Dashboard / settings-style page header: title, subtitle, sync + online pills.
class CashierGreetingHeader extends StatelessWidget {
  const CashierGreetingHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showRates = true,
    this.showSlots = true,
    this.showOnlineStatus = true,
  });

  final String title;
  final String subtitle;
  final bool showRates;
  final bool showSlots;
  final bool showOnlineStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: DashboardStyles.greetingOf(context)),
              const SizedBox(height: 3),
              Text(subtitle, style: DashboardStyles.headerSubtitleOf(context)),
            ],
          ),
        ),
        BranchRatesSlotsHeaderActions(
          showRates: showRates,
          showSlots: showSlots,
          showOnlineStatus: showOnlineStatus,
        ),
      ],
    );
  }
}
