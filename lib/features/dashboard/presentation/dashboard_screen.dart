import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/session/standard_parking_rates.dart';
import '../../auth/state/auth_bloc.dart';
import 'dashboard_standard_rates_sheet.dart';
import 'widgets/dashboard_widgets.dart';

/// Home after [OpenCashScreen] — layout from Figma
/// [Valet Parking / Dashboard](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-453).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static String _greetingWord() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    const branch = 'Jazz Mall';
    const firstName = 'Carlo';

    return Scaffold(
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderRow(
                          greeting: '${_greetingWord()}, $firstName',
                          subtitle: '$dateLabel · $branch',
                        ),
                        const SizedBox(height: 28),
                        _StatsRow(wide: wide),
                        const SizedBox(height: 20),
                        _ActionRow(wide: wide),
                        const SizedBox(height: 24),
                        const _RecentTransactionsCard(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.greeting, required this.subtitle});

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
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, next) {
            StandardParkingRates? rates(AuthState s) =>
                s is AuthAuthenticated ? s.standardRates : null;
            return rates(prev) != rates(next);
          },
          builder: (context, state) {
            final rates = state is AuthAuthenticated
                ? state.standardRates
                : null;
            if (rates == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: () =>
                      showStandardRatesSheet(context, rates: rates),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.center,
                    backgroundColor: DashboardStyles.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'View rate',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const DashboardOnlinePill(),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      DashboardStatCard(
        title: 'Vehicles In',
        valueText: '24',
        deltaText: '+3 this hour',
        valueColor: DashboardStyles.orange,
      ),
      const DashboardStatCard(
        title: 'Checked Out',
        valueText: '18',
        subtitle: 'Today',
      ),
      const DashboardStatCard(
        title: 'Active Slots',
        valueText: '6',
        subtitle: 'of 30 Slots',
      ),
      const DashboardStatCard(
        title: "Today's Revenue",
        valueText: '₱ 3,420',
        subtitle: '18 Transactions',
        valueColor: DashboardStyles.green,
      ),
    ];

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
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
      onTap: () => context.push('/check-in/step-1'),
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
  const _RecentTransactionsCard();

  static const _dividerColor = Color(0x21000000);

  @override
  Widget build(BuildContext context) {
    const rows = <(String, String, String, TransactionStatusKind)>[
      (
        'ABC 1234',
        'Toyota Vios · White',
        'In at 09:32 AM — Slot B-04',
        TransactionStatusKind.parked,
      ),
      (
        'XYZ 5678',
        'Honda City · Silver',
        'In at 09:15 AM — Slot A-11',
        TransactionStatusKind.parked,
      ),
      (
        'DEF 9012',
        'Mitsubishi Montero · Black',
        'Out at 08:58 AM — ₱180.00',
        TransactionStatusKind.checkedOut,
      ),
      (
        'DEF 9012',
        'Mitsubishi Montero · Black',
        'In at 05:15 AM — Slot A-16',
        TransactionStatusKind.parked,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      decoration: DashboardStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RECENT TRANSACTION', style: DashboardStyles.sectionTitle()),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _dividerColor),
          for (var i = 0; i < rows.length; i++) ...[
            DashboardTransactionRow(
              plate: rows[i].$1,
              line1: rows[i].$2,
              line2: rows[i].$3,
              status: rows[i].$4,
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, color: _dividerColor),
          ],
        ],
      ),
    );
  }
}
