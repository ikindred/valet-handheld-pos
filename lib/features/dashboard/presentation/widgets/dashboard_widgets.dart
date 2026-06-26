import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/connectivity/internet_reachability.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/logout_flow.dart';

/// Typography aligned with Figma dashboard ([Valet Parking](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-453)).
abstract final class DashboardStyles {
  static const Color bg = Color(0xFFF4F5F7);
  static const Color orange = Color(0xFFF68D00);
  static const Color green = Color(0xFF27AE60);
  static const Color plateBlue = Color(0xFF0068D3);
  static const Color plateBg = Color(0xFFECF3FF);
  static const Color grey500 = Color(0xFF6C7688);

  /// Active nav icon background from Figma export.
  static const Color railAccentBg = Color(0xFFFFEED8);

  /// Checkout action subtitle: orange @ ~70% opacity.
  static const Color checkoutSubtitle = Color(0xB2F68D00);

  static const List<String> _pesoFallback = ['Noto Sans', 'Roboto'];

  /// Compact tablet layout (aligned with login / open cash).
  static TextStyle greeting() => GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle headerSubtitle() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: const Color(0x990A1B39),
    height: 1.2,
  );

  static TextStyle statTitle() => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    color: AppColors.textSecondary,
  );

  static TextStyle statValue({Color? color}) => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.05,
    color: color ?? AppColors.textPrimary,
  ).copyWith(fontFamilyFallback: _pesoFallback);

  static TextStyle statHint() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: grey500,
    height: 1.25,
  );

  static TextStyle statDeltaGreen() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: green,
    height: 1.25,
  );

  static TextStyle actionTitle({required bool primary}) => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: primary ? Colors.white : orange,
    height: 1.2,
  );

  static TextStyle actionSubtitlePrimary() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.75),
    height: 1.25,
  );

  static TextStyle actionSubtitleCheckout() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: checkoutSubtitle,
    height: 1.25,
  );

  static TextStyle sectionTitle() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static TextStyle plateBadge() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: plateBlue,
    height: 1.2,
  );

  static TextStyle transactionLine() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle transactionLinePrimary() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle transactionLineSecondary() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.25,
  ).copyWith(fontFamilyFallback: _pesoFallback);

  static TextStyle statusParked() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: green,
  );

  static TextStyle statusCheckedOut() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF6E7584),
  );

  static TextStyle headerPillLabel() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C000000),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  // ── Context-aware variants ──────────────────────────────────────────────────

  static TextStyle greetingOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      height: 1.2,
    );
  }

  static TextStyle headerSubtitleOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: c.textSubtitleMuted,
      height: 1.2,
    );
  }

  static TextStyle sectionTitleOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: c.textSecondary,
    );
  }

  static TextStyle statTitleOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.35,
      color: c.textSecondary,
    );
  }

  static TextStyle statValueOf(BuildContext context, {Color? color}) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.05,
      color: color ?? c.textPrimary,
    ).copyWith(fontFamilyFallback: _pesoFallback);
  }

  static TextStyle statHintOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      height: 1.25,
    );
  }

  static TextStyle transactionLinePrimaryOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      height: 1.2,
    );
  }

  static TextStyle transactionLineSecondaryOf(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      height: 1.25,
    ).copyWith(fontFamilyFallback: _pesoFallback);
  }

  static BoxDecoration cardDecorationOf(BuildContext context, {Color? color}) {
    final c = AppThemeColors.of(context);
    return BoxDecoration(
      color: color ?? c.cardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C000000),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }
}

/// Side nav for express cashier: Manual Ticketing + Settings only.
class ExpressCashierLeftRail extends StatelessWidget {
  const ExpressCashierLeftRail({super.key});

  static const _width = 72.0;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    final tc = AppThemeColors.of(context);
    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: tc.railBg,
        border: Border(
          right: BorderSide(color: tc.railBorder),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tc.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: tc.cardBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/spid_logo1.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RailIcon(
                            selected: path == '/express-cashier',
                            icon: Icons.space_dashboard_rounded,
                            onTap: () => context.go('/express-cashier'),
                            accentSelection: true,
                          ),
                          const SizedBox(height: 10),
                          _RailIcon(
                            selected: path == '/settings',
                            icon: Icons.settings_rounded,
                            onTap: () => context.go('/settings'),
                            accentSelection: false,
                          ),
                        ],
                      ),
                      _RailIcon(
                        selected: false,
                        icon: Icons.logout_rounded,
                        onTap: () => showLogoutFlow(context),
                        accentSelection: false,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DashboardLeftRail extends StatelessWidget {
  const DashboardLeftRail({super.key});

  static const _width = 72.0;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    final tc = AppThemeColors.of(context);
    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: tc.railBg,
        border: Border(
          right: BorderSide(color: tc.railBorder),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tc.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: tc.cardBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/spid_logo1.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RailIcon(
                            selected: path == '/dashboard',
                            icon: Icons.space_dashboard_rounded,
                            onTap: () => context.go('/dashboard'),
                            accentSelection: true,
                          ),
                          const SizedBox(height: 10),
                          _RailIcon(
                            selected: path == '/reports',
                            icon: Icons.bar_chart_rounded,
                            onTap: () => context.go('/reports'),
                            accentSelection: true,
                          ),
                          const SizedBox(height: 10),
                          _RailIcon(
                            selected: path == '/settings',
                            icon: Icons.settings_rounded,
                            onTap: () => context.go('/settings'),
                            accentSelection: false,
                          ),
                        ],
                      ),
                      _RailIcon(
                        selected: false,
                        icon: Icons.logout_rounded,
                        onTap: () => showLogoutFlow(context),
                        accentSelection: false,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.selected,
    required this.icon,
    required this.onTap,
    required this.accentSelection,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final bool accentSelection;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isDark = AppThemeColors.isDark(context);
    final accent = accentSelection && selected;
    final bg = accent
        ? (isDark
              ? DashboardStyles.orange.withValues(alpha: 0.18)
              : DashboardStyles.railAccentBg)
        : (selected
              ? tc.textPrimary.withValues(alpha: 0.08)
              : Colors.transparent);
    final fg = accent
        ? DashboardStyles.orange
        : (selected ? tc.textPrimary : tc.textSecondary);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }
}

/// Live connectivity pill; rebuilds when network changes or app resumes.
class DashboardStatusPillLive extends StatefulWidget {
  const DashboardStatusPillLive({super.key});

  @override
  State<DashboardStatusPillLive> createState() => _DashboardStatusPillLiveState();
}

class _DashboardStatusPillLiveState extends State<DashboardStatusPillLive>
    with WidgetsBindingObserver {
  bool? _hasInternet;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refresh());
    });
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final hasInternet = await InternetReachability.hasInternet();
    if (!mounted) return;
    setState(() => _hasInternet = hasInternet);
  }

  @override
  Widget build(BuildContext context) {
    final hasInternet = _hasInternet;
    if (hasInternet == null) return const SizedBox.shrink();
    return DashboardStatusPill(hasInternet: hasInternet);
  }
}

/// Online / offline status from live internet reachability.
class DashboardStatusPill extends StatelessWidget {
  const DashboardStatusPill({
    super.key,
    required this.hasInternet,
  });

  final bool hasInternet;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = _presentation();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: DashboardStyles.headerPillLabel().copyWith(color: color),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _presentation() {
    if (hasInternet) {
      return (
        'Online',
        DashboardStyles.green,
        const Color(0xFFF4FBF7),
      );
    }
    return (
      'Offline',
      AppColors.warning,
      const Color(0xFFFFF7EC),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.valueText,
    this.subtitle,
    this.deltaText,
    this.valueColor,
  });

  final String title;
  final String valueText;
  final String? subtitle;
  final String? deltaText;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: DashboardStyles.cardDecorationOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(), style: DashboardStyles.statTitleOf(context)),
          const SizedBox(height: 8),
          Text(valueText, style: DashboardStyles.statValueOf(context, color: valueColor)),
          if (deltaText != null) ...[
            const SizedBox(height: 4),
            Text(deltaText!, style: DashboardStyles.statDeltaGreen()),
          ] else if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: DashboardStyles.statHintOf(context)),
          ],
        ],
      ),
    );
  }
}

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
    required this.primary,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.subtitleStyle,
  });

  final bool primary;
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: primary ? DashboardStyles.orange : AppThemeColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primary
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppThemeColors.of(context).cardBorder,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 36, height: 36, child: Center(child: leading)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: DashboardStyles.actionTitle(primary: primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style:
                            subtitleStyle ??
                            (primary
                                ? DashboardStyles.actionSubtitlePrimary()
                                : DashboardStyles.actionSubtitleCheckout()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum TransactionStatusKind { parked, checkedOut }

class DashboardTransactionRow extends StatelessWidget {
  const DashboardTransactionRow({
    super.key,
    required this.plate,
    required this.plateNumber,
    required this.ticketNumber,
    required this.line1,
    required this.line2,
    required this.status,
    this.onTap,
  });

  final String plate;
  final String plateNumber;
  /// Formatted ticket number shown in orange badge (e.g. TKT-0123).
  final String ticketNumber;
  final String line1;
  final String line2;
  final TransactionStatusKind status;
  final VoidCallback? onTap;

  static const _ticketOrange = Color(0xFFF68D00);

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isParked = status == TransactionStatusKind.parked;
    final line1Style = DashboardStyles.transactionLinePrimaryOf(context);
    final line2Style = DashboardStyles.transactionLineSecondaryOf(context);

    final plateBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tc.plateBadgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardStyles.plateBlue),
      ),
      child: Text(plate, style: DashboardStyles.plateBadge()),
    );

    final ticketBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tc.accentSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ticketOrange),
      ),
      child: Text(
        ticketNumber,
        style: DashboardStyles.plateBadge().copyWith(color: _ticketOrange),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          line1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: line1Style,
        ),
        const SizedBox(height: 2),
        Text(
          line2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: line2Style,
        ),
      ],
    );

    final statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tc.chipBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isParked ? DashboardStyles.green : tc.textSecondary,
        ),
      ),
      child: Text(
        isParked ? 'Parked' : 'Checked Out',
        style: isParked
            ? DashboardStyles.statusParked()
            : DashboardStyles.statusCheckedOut(),
      ),
    );

    Widget body(BoxConstraints constraints) {
      final wide = constraints.maxWidth >= 520;
      if (!wide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                plateBadge,
                const SizedBox(width: 8),
                ticketBadge,
                const Spacer(),
                statusPill,
              ],
            ),
            const SizedBox(height: 8),
            details,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          plateBadge,
          const SizedBox(width: 8),
          ticketBadge,
          const SizedBox(width: 14),
          Expanded(child: details),
          const SizedBox(width: 12),
          statusPill,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final child = body(constraints);
          if (onTap == null) return child;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
