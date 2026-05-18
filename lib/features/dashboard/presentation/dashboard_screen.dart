import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/branch_config_service.dart';
import '../../../data/services/rate_fetch_service.dart';
import '../../../data/services/rate_service.dart';
import '../../../shared/widgets/area_parking_slots_dialog.dart';
import '../../../shared/widgets/branch_rates_dialog.dart';
import '../../auth/state/auth_bloc.dart';
import '../../check_in/state/check_in_cubit.dart';
import '../state/dashboard_cubit.dart';
import 'widgets/dashboard_widgets.dart';

/// Home after [OpenCashScreen] — layout from Figma
/// [Valet Parking / Dashboard](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-453).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static String greetingWord() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<BranchConfigService>().syncFromServerForDeviceBranch());
      unawaited(context.read<DashboardCubit>().refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, next) {
        if (prev is AuthAuthenticated && next is AuthAuthenticated) {
          return prev.cashSessionStatus != next.cashSessionStatus ||
              prev.userId != next.userId;
        }
        return prev.runtimeType != next.runtimeType;
      },
      listener: (context, _) {
        final c = context.read<DashboardCubit>();
        if (c.state is! DashboardInitial) {
          unawaited(c.refresh());
        }
      },
      child: Scaffold(
        backgroundColor: DashboardStyles.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardLeftRail(),
            Expanded(
              child: SafeArea(
                left: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    return BlocBuilder<DashboardCubit, DashboardState>(
                      builder: (context, dash) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _DashboardHeaderRow(),
                              const SizedBox(height: 12),
                              _StatsRow(wide: wide, dashboard: dash),
                              const SizedBox(height: 12),
                              _ActionRow(wide: wide),
                              const SizedBox(height: 12),
                              _RecentTransactionsCard(dashboard: dash),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _firstNameFromFullName(String fullName) {
  final t = fullName.trim();
  if (t.isEmpty) return '';
  return t.split(RegExp(r'\s+')).first;
}

class _DashboardHeaderRow extends StatefulWidget {
  const _DashboardHeaderRow();

  @override
  State<_DashboardHeaderRow> createState() => _DashboardHeaderRowState();
}

class _DashboardHeaderRowState extends State<_DashboardHeaderRow> {
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
          firstName = _firstNameFromFullName(acct.fullName);
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
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final namePart = _firstName.isEmpty ? '…' : _firstName;
    final sub = _siteSubtitle.isEmpty
        ? '$dateLabel · — : —'
        : _siteSubtitle;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, next) =>
          prev is AuthAuthenticated != next is AuthAuthenticated ||
          (prev is AuthAuthenticated &&
              next is AuthAuthenticated &&
              prev.userId != next.userId),
      listener: (context, state) => unawaited(_refresh()),
      child: _HeaderRow(
        greeting: '${DashboardScreen.greetingWord()}, $namePart',
        subtitle: sub,
      ),
    );
  }
}

Future<void> _openBranchAreaDialog(
  BuildContext context, {
  required bool ratesOnly,
}) async {
  final auth = context.read<AuthRepository>();
  final site = await auth.branchAndAreaFromDb();
  final name = branchRatesSubtitle(site);
  if (!context.mounted) return;
  final rateFetch = context.read<RateFetchService>();
  final rateService = context.read<RateService>();
  if (ratesOnly) {
    await showBranchRatesDialog(
      context,
      authRepository: auth,
      rateFetchService: rateFetch,
      rateService: rateService,
      branchName: name,
    );
  } else {
    await showAreaParkingSlotsDialog(
      context,
      authRepository: auth,
      rateFetchService: rateFetch,
      rateService: rateService,
      branchName: name,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.greeting,
    required this.subtitle,
  });

  final String greeting;
  final String subtitle;

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
              Text(greeting, style: DashboardStyles.greeting()),
              const SizedBox(height: 3),
              Text(subtitle, style: DashboardStyles.headerSubtitle()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: RatesOutlinePill(
            onPressed: () => _openBranchAreaDialog(
              context,
              ratesOnly: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ParkingSlotsOutlinePill(
            onPressed: () => _openBranchAreaDialog(
              context,
              ratesOnly: false,
            ),
          ),
        ),
        const DashboardStatusPillLive(),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.wide, required this.dashboard});

  final bool wide;
  final DashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard is DashboardLoading || dashboard is DashboardInitial) {
      return const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (dashboard is DashboardError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          (dashboard as DashboardError).message,
          style: DashboardStyles.statHint(),
        ),
      );
    }
    final d = dashboard as DashboardReady;
    final delta = d.checkInsLastHour > 0 ? '+${d.checkInsLastHour} this hour' : null;
    final cards = [
      DashboardStatCard(
        title: 'Vehicles In',
        valueText: '${d.vehiclesIn}',
        deltaText: delta,
        valueColor: DashboardStyles.orange,
      ),
      DashboardStatCard(
        title: 'Checked Out',
        valueText: '${d.checkedOut}',
        subtitle: 'This shift',
      ),
      DashboardStatCard(
        title: 'Remaining Slots',
        valueText: '${d.remainingSlots}',
        subtitle: 'of ${d.totalSlots} Slots',
      ),
    ];

    if (wide) {
      // Finite row height under unbounded scroll constraints so stretch is valid.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: cards,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    const checkIn = _CheckInVehicleActionTile();

    final checkOut = DashboardActionTile(
      primary: false,
      title: 'Checkout Vehicle',
      subtitle: 'Scan QR Code or Enter Plate Number',
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DashboardStyles.railAccentBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.sensor_door_outlined,
          color: DashboardStyles.orange,
          size: 22,
        ),
      ),
      onTap: () => context.push('/check-out'),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: checkIn),
          const SizedBox(width: 10),
          Expanded(child: checkOut),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [checkIn, const SizedBox(height: 8), checkOut],
    );
  }
}

class _CheckInVehicleActionTile extends StatefulWidget {
  const _CheckInVehicleActionTile();

  @override
  State<_CheckInVehicleActionTile> createState() =>
      _CheckInVehicleActionTileState();
}

class _CheckInVehicleActionTileState extends State<_CheckInVehicleActionTile> {
  bool _reserving = false;

  Future<void> _onTap() async {
    if (_reserving) return;
    setState(() => _reserving = true);
    final cubit = context.read<CheckInCubit>();
    final ok = await cubit.prepareNewCheckInSession();
    if (!mounted) return;
    setState(() => _reserving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reserve a ticket number. Open a cash shift and try again.',
          ),
        ),
      );
      return;
    }
    context.push('/check-in/step-1');
  }

  @override
  Widget build(BuildContext context) {
    return DashboardActionTile(
      primary: true,
      title: 'Check in Vehicle',
      subtitle: _reserving ? 'Reserving ticket…' : 'New parking Transaction',
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.27),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _reserving
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
      onTap: _reserving ? () {} : () => unawaited(_onTap()),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.dashboard});

  final DashboardState dashboard;

  static const _dividerColor = Color(0x21000000);

  static TransactionStatusKind _mapStatus(DashboardRecentStatus s) =>
      s == DashboardRecentStatus.parked
          ? TransactionStatusKind.parked
          : TransactionStatusKind.checkedOut;

  @override
  Widget build(BuildContext context) {
    final rows = switch (dashboard) {
      DashboardReady(:final recent) => recent,
      _ => const <DashboardRecentTx>[],
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: DashboardStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RECENT TRANSACTION', style: DashboardStyles.sectionTitle()),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _dividerColor),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                dashboard is DashboardLoading
                    ? 'Loading…'
                    : 'No recent transactions for this shift.',
                style: DashboardStyles.statHint(),
                textAlign: TextAlign.center,
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              DashboardTransactionRow(
                plate: rows[i].plate,
                line1: rows[i].line1,
                line2: rows[i].line2,
                status: _mapStatus(rows[i].status),
                onTap: () => context.push(
                  '/dashboard/ticket/${Uri.encodeComponent(rows[i].ticketId)}',
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: _dividerColor),
            ],
        ],
      ),
    );
  }
}
