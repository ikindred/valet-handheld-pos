import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/connectivity/internet_reachability.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/parking_layout_service.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'area_parking_slots_dialog.dart';
import 'branch_rates_dialog.dart';
import 'header_sync_status_pill.dart';

/// Rates + Slots pills for cashier headers (dashboard, check-in, checkout, reports, settings).
class BranchRatesSlotsHeaderActions extends StatefulWidget {
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
  State<BranchRatesSlotsHeaderActions> createState() =>
      _BranchRatesSlotsHeaderActionsState();
}

class _BranchRatesSlotsHeaderActionsState
    extends State<BranchRatesSlotsHeaderActions> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await InternetReachability.hasInternet();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 8),
        ],
        if (widget.showRates) ...[
          RatesOutlinePill(
            onPressed: () =>
                BranchRatesSlotsHeaderActions.openRatesDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        if (widget.showSlots) ...[
          ParkingSlotsOutlinePill(
            onPressed: () =>
                BranchRatesSlotsHeaderActions.openSlotsDialog(context),
          ),
          if (widget.trailing != null || widget.showOnlineStatus)
            const SizedBox(width: 8),
        ],
        if (widget.trailing != null) ...[
          widget.trailing!,
          if (widget.showOnlineStatus && _ready) const SizedBox(width: 8),
        ],
        if (widget.showOnlineStatus && _ready) ...[
          const HeaderSyncStatusPill(),
          const SizedBox(width: 8),
          const DashboardStatusPillLive(),
        ],
      ],
    );
  }
}
