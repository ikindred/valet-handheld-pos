import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/parking_layout_service.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'area_parking_slots_dialog.dart';
import 'branch_rates_dialog.dart';
import 'header_sync_status_pill.dart';

/// Rates + Slots pills for cashier headers (dashboard, check-in, checkout, reports, settings).
class BranchRatesSlotsHeaderActions extends StatelessWidget {
  const BranchRatesSlotsHeaderActions({
    super.key,
    this.leading,
    this.trailing,
    this.showRates = true,
    this.showSlots = true,
    this.showOnlineStatus = true,
  });

  /// Widget before Rates (e.g. ticket pill, sync spinner).
  final Widget? leading;

  /// Widget after Slots, before Online (e.g. extra actions).
  final Widget? trailing;

  final bool showRates;
  final bool showSlots;
  final bool showOnlineStatus;

  static Future<void> openRatesDialog(BuildContext context) async {
    final auth = context.read<AuthRepository>();
    final site = await auth.branchAndAreaFromDb();
    final name = branchRatesSubtitle(site);
    if (!context.mounted) return;
    await showBranchRatesDialog(
      context,
      authRepository: auth,
      rateFetchService: context.read<RateFetchService>(),
      rateService: context.read<RateService>(),
      parkingLayoutService: context.read<ParkingLayoutService>(),
      branchName: name,
    );
  }

  static Future<void> openSlotsDialog(BuildContext context) async {
    final auth = context.read<AuthRepository>();
    final site = await auth.branchAndAreaFromDb();
    final name = branchRatesSubtitle(site);
    if (!context.mounted) return;
    await showAreaParkingSlotsDialog(
      context,
      authRepository: auth,
      rateFetchService: context.read<RateFetchService>(),
      rateService: context.read<RateService>(),
      parkingLayoutService: context.read<ParkingLayoutService>(),
      branchName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        if (showRates) ...[
          RatesOutlinePill(onPressed: () => openRatesDialog(context)),
          const SizedBox(width: 8),
        ],
        if (showSlots) ...[
          ParkingSlotsOutlinePill(onPressed: () => openSlotsDialog(context)),
          if (trailing != null || showOnlineStatus) const SizedBox(width: 8),
        ],
        if (trailing != null) ...[
          trailing!,
          if (showOnlineStatus) const SizedBox(width: 8),
        ],
        if (showOnlineStatus) ...[
          const HeaderSyncStatusPill(),
          const SizedBox(width: 8),
          const DashboardStatusPillLive(),
        ],
      ],
    );
  }
}
