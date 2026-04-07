import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/offline_mode_prefs.dart';
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

  static TextStyle greeting() => GoogleFonts.inter(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle headerSubtitle() => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle statTitle() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: grey500,
  );

  static TextStyle statValue({Color? color}) => GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 0.96,
    color: color ?? AppColors.textPrimary,
  ).copyWith(fontFamilyFallback: _pesoFallback);

  static TextStyle statHint() => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: grey500,
    height: 1.5,
  );

  static TextStyle statDeltaGreen() => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: green,
    height: 1.5,
  );

  static TextStyle actionTitle({required bool primary}) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primary ? Colors.white : orange,
  );

  static TextStyle actionSubtitlePrimary() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.7),
  );

  static TextStyle actionSubtitleCheckout() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: checkoutSubtitle,
  );

  static TextStyle sectionTitle() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: grey500,
  );

  static TextStyle plateBadge() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: plateBlue,
    height: 1.3,
  );

  /// Vehicle + detail lines use `Colors.black` in the Figma export.
  static TextStyle transactionLine() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    height: 1.3,
  );

  static TextStyle statusParked() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: green,
  );

  static TextStyle statusCheckedOut() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6E7584),
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
}

class DashboardLeftRail extends StatelessWidget {
  const DashboardLeftRail({super.key});

  static const _width = 112.0;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.13)),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.13),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _RailIcon(
                selected: path == '/dashboard',
                icon: Icons.space_dashboard_rounded,
                onTap: () => context.go('/dashboard'),
                accentSelection: true,
              ),
              const SizedBox(height: 16),
              _RailIcon(
                selected: path == '/reports',
                icon: Icons.bar_chart_rounded,
                onTap: () => context.go('/reports'),
                accentSelection: false,
              ),
              const SizedBox(height: 16),
              _RailIcon(
                selected: path == '/settings',
                icon: Icons.settings_rounded,
                onTap: () => context.go('/settings'),
                accentSelection: false,
              ),
              const SizedBox(height: 16),
              _RailIcon(
                selected: false,
                icon: Icons.logout_rounded,
                onTap: () => showLogoutFlow(context),
                accentSelection: false,
              ),
              const Spacer(),
            ],
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
    final accent = accentSelection && selected;
    final bg = accent
        ? DashboardStyles.railAccentBg
        : (selected
              ? Colors.black.withValues(alpha: 0.06)
              : Colors.transparent);
    final fg = accent
        ? DashboardStyles.orange
        : (selected ? AppColors.textPrimary : AppColors.textSecondary);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 59,
          height: 59,
          child: Icon(icon, size: 28, color: fg),
        ),
      ),
    );
  }
}

/// Live connectivity + [OfflineModePrefs]; rebuilds when network changes or app resumes.
class DashboardStatusPillLive extends StatefulWidget {
  const DashboardStatusPillLive({super.key});

  @override
  State<DashboardStatusPillLive> createState() => _DashboardStatusPillLiveState();
}

class _DashboardStatusPillLiveState extends State<DashboardStatusPillLive>
    with WidgetsBindingObserver {
  bool _offlineMode = false;
  bool _hasInternet = false;
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
    final prefs = await SharedPreferences.getInstance();
    final offlineMode = OfflineModePrefs.read(prefs);
    var hasInternet = false;
    try {
      hasInternet = await InternetConnection()
          .hasInternetAccess
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      hasInternet = false;
    }
    if (!mounted) return;
    setState(() {
      _offlineMode = offlineMode;
      _hasInternet = hasInternet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardStatusPill(
      offlineMode: _offlineMode,
      hasInternet: _hasInternet,
    );
  }
}

/// Status from [offlineMode] prefs (offline vs online workflow) and live internet.
class DashboardStatusPill extends StatelessWidget {
  const DashboardStatusPill({
    super.key,
    required this.offlineMode,
    required this.hasInternet,
  });

  /// [OfflineModePrefs] — user is in offline-first workflow (e.g. offline login).
  final bool offlineMode;

  /// Result of [InternetConnection] / connectivity check.
  final bool hasInternet;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = _presentation();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _presentation() {
    if (offlineMode) {
      if (hasInternet) {
        return (
          'Offline mode',
          AppColors.textSecondary,
          const Color(0xFFF3F4F6),
        );
      }
      return (
        'Offline · No connection',
        AppColors.warning,
        const Color(0xFFFFF7EC),
      );
    }
    if (hasInternet) {
      return (
        'Online',
        DashboardStyles.green,
        const Color(0xFFF4FBF7),
      );
    }
    return (
      'No connection',
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
      padding: const EdgeInsets.all(20),
      decoration: DashboardStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: DashboardStyles.statTitle()),
          const SizedBox(height: 32),
          Text(valueText, style: DashboardStyles.statValue(color: valueColor)),
          if (deltaText != null) ...[
            const SizedBox(height: 7),
            Text(deltaText!, style: DashboardStyles.statDeltaGreen()),
          ] else if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(subtitle!, style: DashboardStyles.statHint()),
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
        color: primary ? DashboardStyles.orange : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
            ),
            child: Row(
              children: [
                SizedBox(width: 45, height: 45, child: Center(child: leading)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: DashboardStyles.actionTitle(primary: primary),
                      ),
                      const SizedBox(height: 4),
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
    required this.line1,
    required this.line2,
    required this.status,
  });

  final String plate;
  final String line1;
  final String line2;
  final TransactionStatusKind status;

  @override
  Widget build(BuildContext context) {
    final isParked = status == TransactionStatusKind.parked;
    final lineStyle = DashboardStyles.transactionLine();

    final plateBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardStyles.plateBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DashboardStyles.plateBlue),
      ),
      child: Text(plate, style: DashboardStyles.plateBadge()),
    );

    final statusPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: isParked ? const Color(0xFFF4FBF7) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isParked ? DashboardStyles.green : const Color(0xFF6E7584),
        ),
      ),
      child: Text(
        isParked ? 'Parked' : 'Checked Out',
        style: isParked
            ? DashboardStyles.statusParked()
            : DashboardStyles.statusCheckedOut(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [plateBadge, const Spacer(), statusPill],
                ),
                const SizedBox(height: 8),
                Text(line1, style: lineStyle),
                Text(line2, style: lineStyle),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              plateBadge,
              const SizedBox(width: 30),
              Expanded(
                flex: 3,
                child: Text(
                  line1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lineStyle,
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                flex: 3,
                child: Text(
                  line2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lineStyle,
                ),
              ),
              const SizedBox(width: 16),
              statusPill,
            ],
          );
        },
      ),
    );
  }
}
