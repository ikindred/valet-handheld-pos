import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/branch_config_service.dart';
import '../../../data/services/rate_service.dart';
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
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _DashboardHeaderRow(),
                              const SizedBox(height: 28),
                              _StatsRow(wide: wide, dashboard: dash),
                              const SizedBox(height: 20),
                              _ActionRow(wide: wide),
                              const SizedBox(height: 24),
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
          padding: const EdgeInsets.only(right: 12),
          child: RatesOutlinePill(
            onPressed: () async {
              final auth = context.read<AuthRepository>();
              final rateService = context.read<RateService>();
              final site = await auth.branchAndAreaFromDb();
              final bid = site.branch.trim().isEmpty ? '_' : site.branch.trim();
              final name = branchRatesSubtitle(site);
              if (!context.mounted) return;
              await showBranchRatesDialog(
                context,
                rateService: rateService,
                branchId: bid,
                branchName: name,
              );
            },
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
        height: 160,
        child: Center(child: CircularProgressIndicator()),
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
    final peso = PesoCurrency.currency(decimalDigits: 0);
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
        title: 'Active Slots',
        valueText: '${d.activeSlotsUsed}',
        subtitle: 'of ${d.activeSlotsTotal} Slots',
      ),
      DashboardStatCard(
        title: "Today's Revenue",
        valueText: peso.format(d.todayRevenue),
        subtitle: '${d.revenueCheckoutCount} Transactions',
        valueColor: DashboardStyles.green,
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
              if (i < cards.length - 1) const SizedBox(width: 16),
            ],
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.45,
      children: cards,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final checkIn = DashboardActionTile(
      primary: true,
      title: 'Check in Vehicle',
      subtitle: 'New parking Transaction',
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.27),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      onTap: () {
        context.read<CheckInCubit>().resetSession();
        context.push('/check-in/step-1');
      },
    );

    final checkOut = DashboardActionTile(
      primary: false,
      title: 'Checkout Vehicle',
      subtitle: 'Scan QR Code or  Enter Plate Number',
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: DashboardStyles.railAccentBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.sensor_door_outlined,
          color: DashboardStyles.orange,
          size: 28,
        ),
      ),
      onTap: () => context.push('/check-out'),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: checkIn),
          const SizedBox(width: 16),
          Expanded(child: checkOut),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [checkIn, const SizedBox(height: 12), checkOut],
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      decoration: DashboardStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RECENT TRANSACTION', style: DashboardStyles.sectionTitle()),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _dividerColor),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
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
