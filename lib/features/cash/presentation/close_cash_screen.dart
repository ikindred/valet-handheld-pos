import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/formatting/peso_currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/remote/dashboard_api.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/close_cash_purge_service.dart';
import '../../../data/services/shift_service.dart';
import '../../auth/state/auth_bloc.dart';
import '../../sync/state/sync_cubit.dart';
import '../../sync/state/sync_state.dart';
import '../cubits/close_cash_cubit.dart';
import '../cubits/close_cash_state.dart';
import 'widgets/cash_widgets.dart';
import 'widgets/close_cash_shift_stats_card.dart';

class CloseCashScreen extends StatefulWidget {
  const CloseCashScreen({super.key});

  @override
  State<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends State<CloseCashScreen> {
  String _amountText = '0';
  String _headerSubtitle = '';
  bool _online = true;
  bool _offlineMode = false;
  int _pendingSyncCount = 0;
  int _failedSyncCount = 0;
  bool _amountSyncedFromCubit = false;

  static const _orange = Color(0xFFE8831A);
  static const _pageBg = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadHeader());
  }

  Future<void> _loadHeader() async {
    final repo = context.read<AuthRepository>();
    final syncCubit = context.read<SyncCubit>();
    final prefs = await SharedPreferences.getInstance();
    final dateLine = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final siteSub = await repo.dateAndSiteLine(prefs, dateLine);
    final hasInternet = await InternetReachability.hasInternet();
    final offlineMode = OfflineModePrefs.read(prefs);
    final session = await repo.getActiveSession();
    await syncCubit.flush();
    final pending = await syncCubit.pendingCount();
    final failed = await syncCubit.failedCount();
    if (!mounted) return;
    setState(() {
      _headerSubtitle = siteSub;
      _online = hasInternet;
      _offlineMode = offlineMode || (session?.isOfflineSession ?? false);
      _pendingSyncCount = pending;
      _failedSyncCount = failed;
    });
  }

  Future<void> _refreshSyncCounts() async {
    final syncCubit = context.read<SyncCubit>();
    final pending = await syncCubit.pendingCount();
    final failed = await syncCubit.failedCount();
    if (!mounted) return;
    setState(() {
      _pendingSyncCount = pending;
      _failedSyncCount = failed;
    });
  }

  bool get _closeBlocked =>
      !_online ||
      _offlineMode ||
      _pendingSyncCount > 0 ||
      _failedSyncCount > 0;

  String? get _closeBlockedMessage {
    if (_offlineMode) {
      return 'Close cash requires an online connection. '
          'Connect to the internet and sync all transactions.';
    }
    if (!_online) {
      return 'Connect to the internet and sync all transactions before closing cash.';
    }
    if (_pendingSyncCount > 0) {
      return 'Sync $_pendingSyncCount pending transaction'
          '${_pendingSyncCount == 1 ? '' : 's'} before closing cash.';
    }
    if (_failedSyncCount > 0) {
      return 'Resolve $_failedSyncCount failed sync item'
          '${_failedSyncCount == 1 ? '' : 's'} before closing cash.';
    }
    return null;
  }

  String _formatDecimalInput(double v) => v.toStringAsFixed(2);

  /// Cubit sync uses fixed decimals ("0.00"); keypad logic expects bare "0".
  void _normalizeZeroLikeAmount() {
    if (_amountText == '0.00' || _amountText == '0.0') {
      _amountText = '0';
    }
  }

  bool get _isZeroLikeAmount {
    if (_amountText == '0' || _amountText == '0.') return true;
    final parsed = double.tryParse(_amountText.replaceAll(',', ''));
    return parsed == 0 && !_amountText.contains(RegExp(r'\.[1-9]'));
  }

  double get _parsedAmount =>
      double.tryParse(_amountText.replaceAll(',', '')) ?? 0;

  void _onKey(CloseCashCubit cubit, String key) {
    setState(() {
      _normalizeZeroLikeAmount();
      if (key == '⌫') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
        if (_amountText.isEmpty || _amountText == '.') _amountText = '0';
        _normalizeLeadingZero();
        return;
      }
      if (key == '.') {
        if (!_amountText.contains('.')) {
          _amountText = _amountText == '0' ? '0.' : '$_amountText.';
        }
        return;
      }
      if (_isZeroLikeAmount && key != '.') {
        _amountText = key;
      } else {
        _amountText = '$_amountText$key';
      }
      _trimDecimalPlaces();
    });
    cubit.updateActualCash(_parsedAmount);
  }

  void _normalizeLeadingZero() {
    if (_amountText.startsWith('0') &&
        _amountText.length > 1 &&
        _amountText[1] != '.') {
      _amountText = _amountText.replaceFirst(RegExp(r'^0+'), '');
      if (_amountText.isEmpty) _amountText = '0';
    }
  }

  void _trimDecimalPlaces() {
    final i = _amountText.indexOf('.');
    if (i >= 0 && _amountText.length - i - 1 > 2) {
      _amountText = _amountText.substring(0, i + 3);
    }
  }

  String _displayPeso(double v) =>
      '${PesoCurrency.symbol} ${v.toStringAsFixed(2)}';

  CloseCashLoaded? _resolveLoaded(CloseCashState state, CloseCashCubit cubit) {
    if (state is CloseCashLoaded) return state;
    if (state is CloseCashConfirming) return cubit.lastLoaded;
    if (state is CloseCashError) return cubit.lastLoaded;
    if (state is CloseCashBlocked) return cubit.lastLoaded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final uid = int.tryParse(auth.userId ?? '');
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Invalid user')));
    }

    return BlocListener<SyncCubit, SyncState>(
      listener: (context, state) {
        if (state is SyncComplete) {
          _refreshSyncCounts();
        }
      },
      child: BlocProvider(
        key: ValueKey<int>(uid),
        create: (_) => CloseCashCubit(
          context.read<AuthRepository>(),
          context.read<ShiftService>(),
          context.read<SyncCubit>(),
          context.read<DashboardApi>(),
          context.read<CloseCashPurgeService>(),
        )..loadShift(uid),
        child: BlocConsumer<CloseCashCubit, CloseCashState>(
        listener: (context, state) async {
          if (state is CloseCashLoading) {
            _amountSyncedFromCubit = false;
          }
          if (state is CloseCashLoaded) {
            if (!_amountSyncedFromCubit) {
              _amountSyncedFromCubit = true;
              setState(() {
                _amountText = state.actualCash == 0
                    ? '0'
                    : _formatDecimalInput(state.actualCash);
              });
            }
          }
          if (state is CloseCashSuccess) {
            await printCloseCashFromContext(
              context,
              data: state.receipt,
            );
            if (!context.mounted) return;
            final authBloc = context.read<AuthBloc>();
            if (authBloc.state is! AuthUnauthenticated) {
              authBloc.add(const AuthLoggedOut());
              await authBloc.stream.firstWhere((s) => s is AuthUnauthenticated);
            }
            if (!context.mounted) return;
            context.go('/login');
          }
          if (state is CloseCashError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<CloseCashCubit>().restoreLoadedAfterError();
          }
          if (state is CloseCashBlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<CloseCashCubit>().dismissBlockedWarning();
          }
        },
        builder: (context, state) {
          final cubit = context.read<CloseCashCubit>();

          if (state is CloseCashLoading || state is CloseCashInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final loaded = _resolveLoaded(state, cubit);
          if (loaded == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  state is CloseCashError ? state.message : 'No data',
                ),
              ),
            );
          }

          final headerSub = _headerSubtitle.isEmpty
              ? DateFormat('EEEE, MMMM d, y').format(DateTime.now())
              : _headerSubtitle;
          final confirming = state is CloseCashConfirming;

          return Scaffold(
            backgroundColor: _pageBg,
            body: Row(
              children: [
                const CashLeftRail(),
                Expanded(
                  child: SafeArea(
                    left: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CashPageHeader(
                          title: 'Close Cash',
                          subtitle: headerSub,
                          online: _online,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final sideBySide = constraints.maxWidth >= 640;
                                final statsPane = CloseCashShiftStatsCard(
                                  stats: loaded.stats,
                                  activeCheckInCount:
                                      loaded.openTransactions.length,
                                  accentColor: _orange,
                                );
                                final cashPane = _CloseCashCountPane(
                                  amountText: _displayPeso(_parsedAmount),
                                  accentColor: _orange,
                                  onKey: (k) => _onKey(cubit, k),
                                );

                                if (sideBySide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: SingleChildScrollView(
                                          child: statsPane,
                                        ),
                                      ),
                                      const VerticalDivider(
                                        width: 28,
                                        thickness: 1,
                                        color: Color(0x21000000),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: SingleChildScrollView(
                                          child: cashPane,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      statsPane,
                                      const SizedBox(height: 16),
                                      cashPane,
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_closeBlockedMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              _closeBlockedMessage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: confirming
                                            ? null
                                            : () => context.go('/dashboard'),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 54,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _orange,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: confirming || _closeBlocked
                                            ? null
                                            : () =>
                                                cubit.attemptCloseShift(uid),
                                        child: confirming
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Close Cash & End Shift',
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}

class _CloseCashCountPane extends StatelessWidget {
  const _CloseCashCountPane({
    required this.amountText,
    required this.accentColor,
    required this.onKey,
  });

  final String amountText;
  final Color accentColor;
  final void Function(String key) onKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ACTUAL CASH COUNT',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the total cash sales you are turning in for this shift.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 14),
        CashAmountBox(text: amountText, color: accentColor),
        const SizedBox(height: 10),
        CashKeypad(onKey: onKey),
      ],
    );
  }
}
