import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/shift_service.dart';
import '../../../core/ui/app_text_field.dart';
import '../../auth/state/auth_bloc.dart';
import '../../sync/state/sync_cubit.dart';
import '../cubits/close_cash_cubit.dart';
import '../cubits/close_cash_state.dart';
import 'widgets/cash_figma_text_styles.dart';
import 'widgets/cash_widgets.dart';
import '../widgets/open_transactions_warning_modal.dart';

class CloseCashScreen extends StatefulWidget {
  const CloseCashScreen({super.key});

  @override
  State<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends State<CloseCashScreen> {
  final _notesCtrl = TextEditingController();
  String _amountText = '0';
  String _headerSubtitle = '';
  bool _online = true;
  bool _amountSyncedFromCubit = false;

  static const _orange = Color(0xFFE8831A);
  static const _pageBg = Color(0xFFF5F5F5);
  static const _varianceRed = Color(0xFFD32F2F);
  static const _varianceGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadHeader());
  }

  Future<void> _loadHeader() async {
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    final dateLine = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final siteSub = await repo.dateAndSiteLine(prefs, dateLine);
    if (!mounted) return;
    setState(() {
      _headerSubtitle = siteSub;
      _online = !OfflineModePrefs.read(prefs);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatDecimalInput(double v) => v.toStringAsFixed(2);

  void _onKey(CloseCashCubit cubit, String key) {
    setState(() {
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
      if (key == '00') {
        if (_amountText == '0') return;
        _amountText = '$_amountText$key';
        _trimDecimalPlaces();
        return;
      }
      if (_amountText == '0' && key != '.') {
        _amountText = key;
      } else {
        _amountText = '$_amountText$key';
      }
      _trimDecimalPlaces();
    });
    final parsed = double.tryParse(_amountText.replaceAll(',', '')) ?? 0;
    cubit.updateActualCash(parsed);
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
    if (state is CloseCashHasOpenTransactions) return cubit.lastLoaded;
    if (state is CloseCashError) return cubit.lastLoaded;
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

    return BlocProvider(
      key: ValueKey<int>(uid),
      create: (_) =>
          CloseCashCubit(
            context.read<AuthRepository>(),
            context.read<ShiftService>(),
            context.read<SyncCubit>(),
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
                _amountText = _formatDecimalInput(state.actualCash);
              });
            }
          }
          if (state is CloseCashSuccess) {
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
          if (state is CloseCashHasOpenTransactions) {
            OpenTransactionsWarningModal.show(
              context,
              openTransactions: state.openTransactions,
              onCancel: () {
                Navigator.of(context).pop();
                context.read<CloseCashCubit>().dismissOpenTransactionsWarning();
              },
              onConfirm: () {
                Navigator.of(context).pop();
                context.read<CloseCashCubit>().confirmCloseWithOpenTransactions(uid);
              },
            );
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
                  state is CloseCashError
                      ? state.message
                      : 'No data',
                ),
              ),
            );
          }

          final opening = loaded.openingFloat;
          final totalSales = loaded.totalSales;
          final expected = loaded.expectedCash;
          final actual = loaded.actualCash;
          final variance = loaded.variance;
          final remit = loaded.salesToRemit;

          final headerSub = _headerSubtitle.isEmpty
              ? DateFormat('EEEE, MMMM d, y').format(DateTime.now())
              : _headerSubtitle;

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
                        const SizedBox(height: 22),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'OVERVIEW',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _StatCard(
                                                title: 'TRANSACTIONS',
                                                big: '${loaded.transactionsCount}',
                                                sub: 'This shift',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _StatCard(
                                                title: 'TOTAL SALES',
                                                big:
                                                    '${PesoCurrency.symbol} ${totalSales.toStringAsFixed(2)}',
                                                sub: 'Cash collected',
                                                accent: _StatAccent.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _StatCard(
                                                title: 'OPENING BALANCE',
                                                big:
                                                    '${PesoCurrency.symbol} ${opening.toStringAsFixed(2)}',
                                                sub: 'Start shift',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _StatCard(
                                                title: 'EXPECTED CASH',
                                                big:
                                                    '${PesoCurrency.symbol} ${expected.toStringAsFixed(2)}',
                                                sub: 'Opening + sales',
                                                accent: _StatAccent.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        Container(
                                          height: 1,
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'ACTUAL CASH COUNT',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        CashAmountBox(
                                          text: _displayPeso(actual),
                                          color: _orange,
                                        ),
                                        const SizedBox(height: 12),
                                        _CloseCashKeypad(
                                          onKey: (k) =>
                                              _onKey(cubit, k),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(
                                  width: 380,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      _CashReconciliationCard(
                                        opening: opening,
                                        totalSales: totalSales,
                                        expected: expected,
                                        actual: actual,
                                        variance: variance,
                                        orange: _orange,
                                        varianceRed: _varianceRed,
                                        varianceGreen: _varianceGreen,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                SizedBox(
                                  width: 360,
                                  child: Column(
                                    children: [
                                      _RemittanceCard(
                                        amount: remit,
                                        accent: _orange,
                                      ),
                                      const SizedBox(height: 16),
                                      _ClosingNotesCard(
                                        controller: _notesCtrl,
                                        onChanged: (s) =>
                                            cubit.updateClosingNotes(s),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: state
                                                  is CloseCashConfirming
                                              ? null
                                              : () => cubit
                                                  .attemptCloseShift(uid),
                                          child: const Text(
                                            'Close Cash & End Shift',
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _StatAccent { none, success, warning }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.big,
    required this.sub,
    this.accent = _StatAccent.none,
  });

  final String title;
  final String big;
  final String sub;
  final _StatAccent accent;

  @override
  Widget build(BuildContext context) {
    Color bigColor = const Color(0xFF3C3434);
    if (accent == _StatAccent.success) bigColor = AppColors.success;
    if (accent == _StatAccent.warning) bigColor = const Color(0xFFE8831A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            big,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: bigColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _CashReconciliationCard extends StatelessWidget {
  const _CashReconciliationCard({
    required this.opening,
    required this.totalSales,
    required this.expected,
    required this.actual,
    required this.variance,
    required this.orange,
    required this.varianceRed,
    required this.varianceGreen,
  });

  final double opening;
  final double totalSales;
  final double expected;
  final double actual;
  final double variance;
  final Color orange;
  final Color varianceRed;
  final Color varianceGreen;

  @override
  Widget build(BuildContext context) {
    Widget row(
      String left,
      String right, {
      Color? color,
      FontWeight fw = FontWeight.w600,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color ?? const Color(0xFF3C3434),
                    fontWeight: fw,
                  ),
            ),
          ],
        ),
      );
    }

    final balanced = variance.abs() < 0.005;
    final over = variance > 0.005;
    final bannerColor = balanced ? varianceGreen : (over ? orange : varianceRed);
    String bannerText;
    if (balanced) {
      bannerText = 'Cash balanced — no variance';
    } else if (over) {
      bannerText =
          'Over by ${PesoCurrency.symbol}${variance.abs().toStringAsFixed(2)}';
    } else {
      bannerText =
          'Short by ${PesoCurrency.symbol}${variance.abs().toStringAsFixed(2)}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CASH RECONCILIATION',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 0.8,
                  color: const Color(0xFF3C3434),
                ),
          ),
          const SizedBox(height: 10),
          row('Opening Balance',
              '${PesoCurrency.symbol} ${opening.toStringAsFixed(2)}'),
          const Divider(height: 1),
          row(
            'Total Sales',
            '+ ${PesoCurrency.symbol} ${totalSales.toStringAsFixed(2)}',
            color: varianceGreen,
          ),
          const Divider(height: 1),
          row(
            'Expected Total',
            '${PesoCurrency.symbol} ${expected.toStringAsFixed(2)}',
            fw: FontWeight.w700,
          ),
          const Divider(height: 1),
          row('Actual Cash on Hand',
              '${PesoCurrency.symbol} ${actual.toStringAsFixed(2)}'),
          const Divider(height: 1),
          row(
            'Variance',
            '${PesoCurrency.symbol} ${variance.toStringAsFixed(2)}',
            color: balanced ? varianceGreen : (over ? orange : varianceRed),
            fw: FontWeight.w700,
          ),
          const SizedBox(height: 14),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: balanced
                  ? const Color(0xFFF4FBF7)
                  : (over
                      ? const Color(0xFFFFF7EC)
                      : const Color(0xFFFFEBEE)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bannerColor),
            ),
            alignment: Alignment.center,
            child: Text(
              bannerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemittanceCard extends StatelessWidget {
  const _RemittanceCard({required this.amount, required this.accent});

  final double amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 20, color: accent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SALES TO REMIT TO SUPERVISOR',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '${PesoCurrency.symbol} ${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingNotesCard extends StatelessWidget {
  const _ClosingNotesCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLOSING NOTES',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            maxLines: 4,
            minHeight: 88,
            hint: 'Any incidents, discrepancies, or notes for the next shift…',
            style: CashFigmaStyles.notesInput(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Numpad with decimal and backspace.
class _CloseCashKeypad extends StatelessWidget {
  const _CloseCashKeypad({required this.onKey});

  final void Function(String) onKey;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '00', '⌫'],
      ['0'],
    ];

    return Column(
      children: [
        for (var r = 0; r < keys.length; r++) ...[
          Row(
            children: [
              for (final k in keys[r])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: _CloseKeyButton(label: k, onTap: () => onKey(k)),
                  ),
                ),
              if (keys[r].length == 1) ...[
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _CloseKeyButton extends StatelessWidget {
  const _CloseKeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAccent = label == '00';
    final isDelete = label == '⌫';

    Color bg = const Color(0xFFF8F9FB);
    Color border = const Color(0xFFC0C0BF);
    Color fg = const Color(0xFF3C3434);

    if (isAccent) {
      bg = const Color(0xFFFFF5DE);
      border = const Color(0xFFE8831A);
      fg = const Color(0xFFE8831A);
    }
    if (isDelete) {
      bg = Colors.white;
      border = const Color(0xFFC0C0BF);
      fg = const Color(0xFFD64045);
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isDelete
            ? Icon(Icons.backspace_outlined, color: fg, size: 22)
            : Text(label, style: CashFigmaStyles.keypadDigit(color: fg)),
      ),
    );
  }
}
