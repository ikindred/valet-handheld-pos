import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/printer_connection_notifier.dart';
import '../../../core/printing/valet_print_service.dart';
import '../../../core/printing/widgets/printer_pairing_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/presentation/logout_flow.dart';
import '../../auth/state/auth_bloc.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../../shared/widgets/branch_rates_slots_header_actions.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../sync/state/sync_cubit.dart';
import '../../sync/state/sync_state.dart';
import 'widgets/pending_sync_sheet.dart';

import '../../../core/storage/prefs_keys.dart';
const _kLastSyncKey = 'spid_last_sync_at_ms';
const _kAppVersion = 'Valet Master v1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  String _firstName = '';
  String _siteSubtitle = '';
  String _fullName = '';
  String _roleBadge = 'Staff';
  String _roleSubtitle = 'Valet Staff';
  bool _autoSyncEnabled = true;
  int _pendingCount = 0;
  int _failedCount = 0;
  String _lastSyncLabel = 'Never';
  bool _syncing = false;
  bool _isExpressCashier = false;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refreshOnline());
    });
    unawaited(_load());
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
      unawaited(_refreshOnline());
    }
  }

  Future<void> _refreshOnline() async {
    final online = await InternetReachability.hasInternet();
    if (!mounted) return;
    setState(() => _isOnline = online);
  }

  Future<void> _load() async {
    await Future.wait([
      _loadUserInfo(),
      _loadSyncInfo(),
      _loadPrefs(),
      _refreshOnline(),
    ]);
  }

  Future<void> _loadUserInfo() async {
    final auth = context.read<AuthBloc>().state;
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final siteLine = await repo.dateAndSiteLine(prefs, dateLabel);
    final site = await repo.branchAndAreaFromDb();
    final branchName =
        site.branch.trim().isEmpty ? 'Valet Master' : site.branch;

    var firstName = '';
    var fullName = '';
    var role = '';
    var isExpressCashier = false;

    if (auth is AuthAuthenticated && auth.userId != null) {
      final localId = int.tryParse(auth.userId!);
      if (localId != null) {
        final acct = await repo.offlineAccountById(localId);
        if (!mounted) return;
        if (acct != null) {
          fullName = acct.fullName.trim();
          role = acct.role.trim();
          isExpressCashier = acct.isExpressCashier;
          final parts = fullName.split(RegExp(r'\s+'));
          firstName = parts.isNotEmpty ? parts.first : '';
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _firstName = firstName;
      _fullName = fullName.isEmpty ? '—' : fullName;
      _siteSubtitle = siteLine;
      _roleBadge = _formatRoleBadge(role);
      _roleSubtitle =
          '${_formatRoleLabel(role)} · $branchName';
      _isExpressCashier = isExpressCashier;
    });
  }

  Future<void> _loadSyncInfo() async {
    final cubit = context.read<SyncCubit>();
    final count = await cubit.pendingCount();
    final failed = await cubit.failedCount();
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastSyncKey);
    if (!mounted) return;
    setState(() {
      _pendingCount = count;
      _failedCount = failed;
      _lastSyncLabel = _fmtLastSync(ms);
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoSyncEnabled = prefs.getBool(PrefsKeys.autoSyncOnConnect) ?? true;
    });
  }

  Future<void> _triggerSync() async {
    if (_syncing) return;
    if (!_isOnline) {
      _showOfflineSyncMessage();
      return;
    }
    setState(() => _syncing = true);
    try {
      await context.read<SyncCubit>().retryFailed();
      if (!mounted) return;
      final cubit = context.read<SyncCubit>();
      final count = await cubit.pendingCount();
      final failed = await cubit.failedCount();
      if (!mounted) return;
      final fullySynced = count == 0 && failed == 0;
      if (fullySynced) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          _kLastSyncKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
      if (!mounted) return;
      setState(() {
        _pendingCount = count;
        _failedCount = failed;
        if (fullySynced) {
          _lastSyncLabel =
              _fmtLastSync(DateTime.now().millisecondsSinceEpoch);
        }
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showOfflineSyncMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "You're offline — connect to the internet to sync.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.autoSyncOnConnect, value);
    if (!mounted) return;
    setState(() => _autoSyncEnabled = value);
  }

  Future<void> _openPendingSyncSheet() async {
    final auth = context.read<AuthBloc>().state;
    final isExpressCashier = _isExpressCashier ||
        (auth is AuthAuthenticated && auth.isExpressCashier);
    await showPendingSyncSheet(
      context,
      isExpressCashier: isExpressCashier,
    );
    if (!mounted) return;
    await _loadSyncInfo();
  }

  Future<void> _testPrint() async {
    final auth = context.read<AuthRepository>();
    final site = await auth.branchAndAreaFromDb();
    if (!mounted) return;
    final branch =
        site.branch.trim().isEmpty ? 'Valet Master' : site.branch;
    await runBluetoothPrint(
      context,
      printJob: () => context
          .read<ValetPrintService>()
          .printTestReceipt(branchName: branch),
    );
  }

  Future<void> _reconnectPrinter() async {
    await context.read<PrinterConnectionNotifier>().tryConnectPaired();
  }

  static String _formatRoleBadge(String role) {
    final r = role.toLowerCase();
    if (r.contains('admin')) return 'Admin';
    return 'Staff';
  }

  static String _formatRoleLabel(String role) {
    if (role.isEmpty) return 'Valet Staff';
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _fmtLastSync(int? ms) {
    if (ms == null) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(dt);
    final sameDay = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final yesterday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1;
    if (sameDay) return 'Today at $timeStr — successful';
    if (yesterday) return 'Yesterday at $timeStr — successful';
    return '${DateFormat('MMM d').format(dt)} at $timeStr — successful';
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterConnectionNotifier>();
    final syncState = context.watch<SyncCubit>().state;
    final isSyncing = _syncing || syncState is SyncInProgress;

    final auth = context.watch<AuthBloc>().state;
    final isExpressCashier = _isExpressCashier ||
        (auth is AuthAuthenticated && auth.isExpressCashier);

    return Scaffold(
      backgroundColor: null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isExpressCashier
              ? const ExpressCashierLeftRail()
              : const DashboardLeftRail(),
          Expanded(
            child: SafeArea(
              left: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 560;
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SettingsHeader(
                          firstName: _firstName,
                          siteSubtitle: _siteSubtitle,
                          isExpressCashier: isExpressCashier,
                        ),
                        const SizedBox(height: 16),
                        if (wide)
                          _WideLayout(
                            pendingCount: _pendingCount,
                            failedCount: _failedCount,
                            lastSyncLabel: _lastSyncLabel,
                            autoSyncEnabled: _autoSyncEnabled,
                            isSyncing: isSyncing,
                            isOnline: _isOnline,
                            printer: printer,
                            fullName: _fullName,
                            roleBadge: _roleBadge,
                            roleSubtitle: _roleSubtitle,
                            onSyncNow: _triggerSync,
                            onToggleAutoSync: _toggleAutoSync,
                            onViewPendingSync: _openPendingSyncSheet,
                            onTestPrint: _testPrint,
                            onReconnect: _reconnectPrinter,
                          )
                        else
                          _NarrowLayout(
                            pendingCount: _pendingCount,
                            failedCount: _failedCount,
                            lastSyncLabel: _lastSyncLabel,
                            autoSyncEnabled: _autoSyncEnabled,
                            isSyncing: isSyncing,
                            isOnline: _isOnline,
                            printer: printer,
                            fullName: _fullName,
                            roleBadge: _roleBadge,
                            roleSubtitle: _roleSubtitle,
                            onSyncNow: _triggerSync,
                            onToggleAutoSync: _toggleAutoSync,
                            onViewPendingSync: _openPendingSyncSheet,
                            onTestPrint: _testPrint,
                            onReconnect: _reconnectPrinter,
                          ),
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

// ── Header ──────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.firstName,
    required this.siteSubtitle,
    this.isExpressCashier = false,
  });

  final String firstName;
  final String siteSubtitle;
  final bool isExpressCashier;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    final namePart = firstName.isEmpty ? '…' : firstName;
    final sub = siteSubtitle.isEmpty
        ? '$dateLabel · — : —'
        : siteSubtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${DashboardScreen.greetingWord()}, $namePart',
                style: DashboardStyles.greetingOf(context),
              ),
              const SizedBox(height: 3),
              Text(sub, style: DashboardStyles.headerSubtitleOf(context)),
            ],
          ),
        ),
        BranchRatesSlotsHeaderActions(
          showRates: !isExpressCashier,
          showSlots: !isExpressCashier,
        ),
      ],
    );
  }
}

// ── Layout wrappers ──────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncLabel,
    required this.autoSyncEnabled,
    required this.isSyncing,
    required this.isOnline,
    required this.printer,
    required this.fullName,
    required this.roleBadge,
    required this.roleSubtitle,
    required this.onSyncNow,
    required this.onToggleAutoSync,
    required this.onViewPendingSync,
    required this.onTestPrint,
    required this.onReconnect,
  });

  final int pendingCount;
  final int failedCount;
  final String lastSyncLabel;
  final bool autoSyncEnabled;
  final bool isSyncing;
  final bool isOnline;
  final PrinterConnectionNotifier printer;
  final String fullName;
  final String roleBadge;
  final String roleSubtitle;
  final VoidCallback onSyncNow;
  final ValueChanged<bool> onToggleAutoSync;
  final VoidCallback onViewPendingSync;
  final VoidCallback onTestPrint;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DataSyncCard(
                pendingCount: pendingCount,
                failedCount: failedCount,
                lastSyncLabel: lastSyncLabel,
                autoSyncEnabled: autoSyncEnabled,
                isSyncing: isSyncing,
                isOnline: isOnline,
                onSyncNow: onSyncNow,
                onToggleAutoSync: onToggleAutoSync,
                onViewPendingSync: onViewPendingSync,
              ),
              const SizedBox(height: 10),
              _PrinterCard(
                printer: printer,
                onTestPrint: onTestPrint,
                onReconnect: onReconnect,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppearanceCard(),
              const SizedBox(height: 10),
              _AccountCard(
                fullName: fullName,
                roleBadge: roleBadge,
                roleSubtitle: roleSubtitle,
              ),
              const SizedBox(height: 10),
              const _SessionCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncLabel,
    required this.autoSyncEnabled,
    required this.isSyncing,
    required this.isOnline,
    required this.printer,
    required this.fullName,
    required this.roleBadge,
    required this.roleSubtitle,
    required this.onSyncNow,
    required this.onToggleAutoSync,
    required this.onViewPendingSync,
    required this.onTestPrint,
    required this.onReconnect,
  });

  final int pendingCount;
  final int failedCount;
  final String lastSyncLabel;
  final bool autoSyncEnabled;
  final bool isSyncing;
  final bool isOnline;
  final PrinterConnectionNotifier printer;
  final String fullName;
  final String roleBadge;
  final String roleSubtitle;
  final VoidCallback onSyncNow;
  final ValueChanged<bool> onToggleAutoSync;
  final VoidCallback onViewPendingSync;
  final VoidCallback onTestPrint;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DataSyncCard(
          pendingCount: pendingCount,
          failedCount: failedCount,
          lastSyncLabel: lastSyncLabel,
          autoSyncEnabled: autoSyncEnabled,
          isSyncing: isSyncing,
          isOnline: isOnline,
          onSyncNow: onSyncNow,
          onToggleAutoSync: onToggleAutoSync,
          onViewPendingSync: onViewPendingSync,
        ),
        const SizedBox(height: 10),
        _PrinterCard(
          printer: printer,
          onTestPrint: onTestPrint,
          onReconnect: onReconnect,
        ),
        const SizedBox(height: 10),
        const _AppearanceCard(),
        const SizedBox(height: 10),
        _AccountCard(
          fullName: fullName,
          roleBadge: roleBadge,
          roleSubtitle: roleSubtitle,
        ),
        const SizedBox(height: 10),
        const _SessionCard(),
      ],
    );
  }
}

// ── Icon tile tones (light pastels vs dark muted surfaces) ───────────────────

class _SettingsIconTone {
  _SettingsIconTone._();

  static bool _dark(BuildContext context) => AppThemeColors.isDark(context);

  static (Color bg, Color fg) blue(BuildContext context) => _dark(context)
      ? (const Color(0xFF1E3A5F), const Color(0xFF60A5FA))
      : (const Color(0xFFEEF4FF), const Color(0xFF3B82F6));

  static (Color bg, Color fg) green(BuildContext context) => _dark(context)
      ? (const Color(0xFF14532D), const Color(0xFF4ADE80))
      : (const Color(0xFFECFDF5), const Color(0xFF27AE60));

  static (Color bg, Color fg) emerald(BuildContext context) => _dark(context)
      ? (const Color(0xFF064E3B), const Color(0xFF34D399))
      : (const Color(0xFFECFDF5), const Color(0xFF059669));

  static (Color bg, Color fg) amber(BuildContext context) => _dark(context)
      ? (const Color(0xFF422006), const Color(0xFFFBBF24))
      : (const Color(0xFFFFF7ED), const Color(0xFFF59E0B));

  static (Color bg, Color fg) grey(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return _dark(context)
        ? (tc.hintFill, tc.textSecondary)
        : (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
  }

  static (Color bg, Color fg) red(BuildContext context) => _dark(context)
      ? (const Color(0xFF450A0A), const Color(0xFFF87171))
      : (const Color(0xFFFEF2F2), const Color(0xFFEF4444));

  static (Color bg, Color fg) slate(BuildContext context) => _dark(context)
      ? (const Color(0xFF334155), Colors.white)
      : (const Color(0xFF1E293B), Colors.white);
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _DataSyncCard extends StatelessWidget {
  const _DataSyncCard({
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncLabel,
    required this.autoSyncEnabled,
    required this.isSyncing,
    required this.isOnline,
    required this.onSyncNow,
    required this.onToggleAutoSync,
    required this.onViewPendingSync,
  });

  final int pendingCount;
  final int failedCount;
  final String lastSyncLabel;
  final bool autoSyncEnabled;
  final bool isSyncing;
  final bool isOnline;
  final VoidCallback onSyncNow;
  final ValueChanged<bool> onToggleAutoSync;
  final VoidCallback onViewPendingSync;

  static const _green = Color(0xFF27AE60);

  bool get _isFullySynced => pendingCount == 0 && failedCount == 0;

  String? get _syncSubtitle {
    if (!isOnline) {
      if (pendingCount > 0 || failedCount > 0) {
        final parts = <String>[];
        if (pendingCount > 0) {
          parts.add('$pendingCount pending');
        }
        if (failedCount > 0) {
          parts.add('$failedCount failed');
        }
        return "You're offline — connect to sync (${parts.join(' · ')})";
      }
      return "You're offline — connect to the internet to sync";
    }
    if (pendingCount > 0 && failedCount > 0) {
      return '$pendingCount pending · $failedCount failed';
    }
    if (failedCount > 0) {
      return '$failedCount failed — tap Sync Now to retry';
    }
    if (_isFullySynced) return 'All transactions synced';
    return null;
  }

  String? get _unsyncedSubtitle {
    final total = pendingCount + failedCount;
    if (total == 0) return 'No items waiting to upload';
    final parts = <String>[];
    if (pendingCount > 0) parts.add('$pendingCount pending');
    if (failedCount > 0) parts.add('$failedCount failed');
    return '${parts.join(' · ')} — tap View';
  }

  @override
  Widget build(BuildContext context) {
    final syncTone = _SettingsIconTone.green(context);
    final historyTone = _SettingsIconTone.amber(context);
    final listTone = _SettingsIconTone.blue(context);
    final autoTone = _SettingsIconTone.emerald(context);
    return _SettingsCard(
      sectionLabel: 'DATA & SYNC',
      children: [
        _SettingsRow(
          iconBg: syncTone.$1,
          iconColor: syncTone.$2,
          icon: Icons.sync_rounded,
          title: 'Sync Offline Data',
          subtitleWidget: pendingCount > 0
              ? _PendingBadge(count: pendingCount)
              : null,
          subtitle: _syncSubtitle,
          onTap: (!isOnline && !isSyncing) ? onSyncNow : null,
          trailing: _GreenFilledButton(
            label: isSyncing ? 'Syncing…' : 'Sync Now',
            onPressed: (isSyncing || !isOnline) ? null : onSyncNow,
          ),
        ),
        const _RowDivider(),
        _SettingsRow(
          iconBg: listTone.$1,
          iconColor: listTone.$2,
          icon: Icons.list_alt_rounded,
          title: 'Unsynced Data',
          subtitle: _unsyncedSubtitle,
          onTap: onViewPendingSync,
          trailing: _OutlinedActionButton(
            label: 'View',
            onPressed: onViewPendingSync,
          ),
        ),
        const _RowDivider(),
        _SettingsRow(
          iconBg: historyTone.$1,
          iconColor: historyTone.$2,
          icon: Icons.history_rounded,
          title: 'Last Sync',
          subtitle: lastSyncLabel,
          trailing: lastSyncLabel != 'Never' && _isFullySynced
              ? _OutlinePill(label: 'Up to date')
              : null,
        ),
        const _RowDivider(),
        _SettingsRow(
          iconBg: autoTone.$1,
          iconColor: autoTone.$2,
          icon: Icons.bolt_rounded,
          title: 'Auto-sync on Connect',
          subtitle: 'Sync automatically when online',
          trailing: Switch.adaptive(
            value: autoSyncEnabled,
            onChanged: onToggleAutoSync,
            activeTrackColor: _green,
          ),
        ),
      ],
    );
  }
}

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({
    required this.printer,
    required this.onTestPrint,
    required this.onReconnect,
  });

  final PrinterConnectionNotifier printer;
  final VoidCallback onTestPrint;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final showBluetooth = Platform.isAndroid || Platform.isIOS;
    final printerLabel = printer.pairedDisplayName ?? 'No printer paired';
    final connSubtitle = printer.isConnected
        ? '${printer.statusSubtitle.split(' · ').last} · 80mm thermal'
        : printer.statusSubtitle;

    final printerTone = _SettingsIconTone.blue(context);
    final testTone = _SettingsIconTone.grey(context);
    return _SettingsCard(
      sectionLabel: 'BLUETOOTH PRINTER',
      children: [
        _SettingsRow(
          iconBg: printerTone.$1,
          iconColor: printerTone.$2,
          icon: Icons.print_rounded,
          title: printerLabel,
          subtitle: showBluetooth ? connSubtitle : 'Android / iOS only',
          trailing: showBluetooth
              ? printer.isConnected
                  ? _ConnectedBadge()
                  : printer.hasPairedPrinter
                      ? _GreenFilledButton(
                          label: 'Reconnect',
                          onPressed: onReconnect,
                        )
                      : _GreenFilledButton(
                          label: 'Connect',
                          onPressed: () => showPrinterPairingSheet(context),
                        )
              : null,
          onTap: showBluetooth
              ? () => showPrinterPairingSheet(context)
              : null,
        ),
        const _RowDivider(),
        _SettingsRow(
          iconBg: testTone.$1,
          iconColor: testTone.$2,
          icon: Icons.receipt_long_rounded,
          title: 'Test Print',
          subtitle: 'Print a test receipt to verify',
          trailing: _OutlinedActionButton(
            label: 'Test',
            onPressed:
                (showBluetooth && printer.isConnected) ? onTestPrint : null,
          ),
        ),
      ],
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;
    final appearanceTone = _SettingsIconTone.slate(context);
    return _SettingsCard(
      sectionLabel: 'APPEARANCE',
      children: [
        _SettingsRow(
          iconBg: appearanceTone.$1,
          iconColor: appearanceTone.$2,
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          title: 'Dark Mode',
          subtitle: isDark ? 'Dark theme is active' : 'Switch to dark theme',
          trailing: Switch.adaptive(
            value: isDark,
            onChanged: (v) => themeNotifier.setDark(v),
            activeTrackColor: const Color(0xFF27AE60),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.fullName,
    required this.roleBadge,
    required this.roleSubtitle,
  });

  final String fullName;
  final String roleBadge;
  final String roleSubtitle;

  @override
  Widget build(BuildContext context) {
    final accountTone = _SettingsIconTone.blue(context);
    final versionTone = _SettingsIconTone.amber(context);
    return _SettingsCard(
      sectionLabel: 'ACCOUNT',
      children: [
        _SettingsRow(
          iconBg: accountTone.$1,
          iconColor: accountTone.$2,
          icon: Icons.person_rounded,
          title: fullName,
          subtitle: roleSubtitle,
          trailing: _RoleBadge(label: roleBadge),
        ),
        const _RowDivider(),
        _SettingsRow(
          iconBg: versionTone.$1,
          iconColor: versionTone.$2,
          icon: Icons.layers_rounded,
          title: 'App Version',
          subtitle: _kAppVersion,
        ),
      ],
    );
  }

}

class _SessionCard extends StatelessWidget {
  const _SessionCard();

  @override
  Widget build(BuildContext context) {
    final logoutTone = _SettingsIconTone.red(context);
    return _SettingsCard(
      sectionLabel: 'SESSION',
      children: [
        _SettingsRow(
          iconBg: logoutTone.$1,
          iconColor: logoutTone.$2,
          icon: Icons.power_settings_new_rounded,
          title: 'Logout',
          titleColor: const Color(0xFFD92D20),
          subtitle: 'Sign out of this device',
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFD92D20),
            size: 14,
          ),
          onTap: () => showLogoutFlow(context),
        ),
      ],
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.sectionLabel,
    required this.children,
  });

  final String sectionLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: DashboardStyles.cardDecorationOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sectionLabel, style: DashboardStyles.sectionTitleOf(context)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

// ── Row widget ────────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppThemeColors.of(context).textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 4),
                      subtitleWidget!,
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: AppThemeColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AppThemeColors.of(context).divider);
  }
}

// ── Small UI primitives ───────────────────────────────────────────────────────

class _GreenFilledButton extends StatelessWidget {
  const _GreenFilledButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF27AE60),
        disabledBackgroundColor: const Color(0xFFB0BEC5),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final enabled = onPressed != null;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? tc.textPrimary : tc.textSubtitleMuted,
        side: BorderSide(
          color: enabled ? tc.cardBorder : tc.divider,
        ),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class _ConnectedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF27AE60)),
      ),
      child: Text(
        'Connected',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF27AE60),
        ),
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFDA29B)),
      ),
      child: Text(
        '$count transaction${count == 1 ? '' : 's'}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD92D20),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DashboardStyles.orange),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DashboardStyles.orange,
        ),
      ),
    );
  }
}
