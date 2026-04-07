import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/ui/app_text_field.dart';
import '../../auth/state/auth_bloc.dart';
import 'widgets/cash_figma_text_styles.dart';
import 'widgets/cash_widgets.dart';

class CloseCashScreen extends StatefulWidget {
  const CloseCashScreen({super.key});

  @override
  State<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends State<CloseCashScreen> {
  final _notesCtrl = TextEditingController();
  String _amountText = '0';

  Shift? _shift;
  bool _loading = true;
  bool _online = true;
  String _headerSubtitle = '';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadShift());
  }

  Future<void> _loadShift() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final uid = int.tryParse(auth.userId ?? '');
    if (uid == null) return;
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    final shift = await repo.getOpenShiftForUser(uid);
    if (!mounted) return;
    final expected = shift == null
        ? 0.0
        : shift.openingFloat + shift.totalSales;
    final dateLine = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final siteSub = await repo.dateAndSiteLine(prefs, dateLine);
    setState(() {
      _shift = shift;
      _loading = false;
      _online = !OfflineModePrefs.read(prefs);
      _amountText = expected.toStringAsFixed(2);
      _headerSubtitle = siteSub;
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _tapKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
        if (_amountText.isEmpty) _amountText = '0';
        return;
      }
      if (key == '00') {
        _amountText = (_amountText == '0') ? '00' : '$_amountText$key';
        return;
      }
      if (_amountText == '0') {
        _amountText = key;
      } else {
        _amountText = '$_amountText$key';
      }
    });
  }

  String get _displayAmount {
    final parsed = double.tryParse(_amountText.replaceAll(',', '')) ?? 0;
    return '₱ ${parsed.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_shift == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No open shift found.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final shift = _shift!;
    final opening = shift.openingFloat;
    final totalSales = shift.totalSales;
    final expected = opening + totalSales;
    final actual =
        double.tryParse(_amountText.replaceAll(',', '')) ?? expected;
    final variance = actual - expected;
    final headerSub = _headerSubtitle.isEmpty
        ? DateFormat('EEEE, MMMM d, y').format(DateTime.now())
        : _headerSubtitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        Text('OVERVIEW', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'TRANSACTIONS',
                                big: '${shift.transactionsCount}',
                                sub: 'This shift',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'TOTAL SALES',
                                big: '₱ ${totalSales.toStringAsFixed(2)}',
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
                                big: '₱ ${opening.toStringAsFixed(2)}',
                                sub: 'Start shift',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'EXPECTED CASH',
                                big: '₱ ${expected.toStringAsFixed(2)}',
                                sub: 'Opening + sales',
                                accent: _StatAccent.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text('ACTUAL CASH COUNT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        CashAmountBox(text: _displayAmount),
                        const SizedBox(height: 12),
                        CashKeypad(onKey: _tapKey),
                              ],
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
                                    variance: variance),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 360,
                            child: Column(
                              children: [
                                _RemittanceCard(
                                  amount: totalSales,
                                  openingInDrawer: opening,
                                ),
                                const SizedBox(height: 16),
                                _ClosingNotesCard(controller: _notesCtrl),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: () async {
                                      final auth = context.read<AuthBloc>().state;
                                      if (auth is! AuthAuthenticated) return;
                                      final userIdStr = auth.userId;
                                      if (userIdStr == null) return;
                                      final localUserId = int.tryParse(userIdStr);
                                      if (localUserId == null) return;
                                      await context
                                          .read<AuthRepository>()
                                          .confirmCloseCash(
                                            localUserId: localUserId,
                                            closingFloat: actual,
                                            closingNotes: _notesCtrl.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : _notesCtrl.text.trim(),
                                          );
                                      if (!context.mounted) return;
                                      context.read<AuthBloc>().add(
                                            const AuthLoggedOut(),
                                          );
                                      context.go('/login');
                                    },
                                    child: const Text('Close Cash & End Shift'),
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
  }
}

enum _StatAccent { none, success, warning }

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.big, required this.sub, this.accent = _StatAccent.none});

  final String title;
  final String big;
  final String sub;
  final _StatAccent accent;

  @override
  Widget build(BuildContext context) {
    Color bigColor = AppColors.textPrimary;
    if (accent == _StatAccent.success) bigColor = AppColors.success;
    if (accent == _StatAccent.warning) bigColor = const Color(0xFFF68D00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Text(big, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: bigColor)),
          const SizedBox(height: 4),
          Text(sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
  });

  final double opening;
  final double totalSales;
  final double expected;
  final double actual;
  final double variance;

  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right, {Color? color, FontWeight fw = FontWeight.w600}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            Text(right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color ?? AppColors.textPrimary, fontWeight: fw)),
          ],
        ),
      );
    }

    final varianceColor = variance.abs() < 0.005 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CASH RECONCILIATION', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 0.8)),
          const SizedBox(height: 10),
          row('Opening Balance', '₱ ${opening.toStringAsFixed(2)}'),
          const Divider(height: 1),
          row('Total Sales', '+ ₱ ${totalSales.toStringAsFixed(2)}', color: AppColors.success),
          const Divider(height: 1),
          row('Expected Total', '₱ ${expected.toStringAsFixed(2)}', fw: FontWeight.w700),
          const Divider(height: 1),
          row('Actual Cash on Hand', '₱ ${actual.toStringAsFixed(2)}'),
          const Divider(height: 1),
          row('Variance', '₱ ${variance.toStringAsFixed(2)}', color: varianceColor, fw: FontWeight.w700),
          const SizedBox(height: 14),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4FBF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success),
            ),
            alignment: Alignment.center,
            child: Text(
              variance.abs() < 0.005 ? 'Cash balanced — no variance' : 'Variance detected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemittanceCard extends StatelessWidget {
  const _RemittanceCard({
    required this.amount,
    required this.openingInDrawer,
  });

  final double amount;
  final double openingInDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('SALES TO REMIT TO SUPERVISOR', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Text(
            '₱ ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFFF68D00), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Opening (₱ ${openingInDrawer.toStringAsFixed(2)}) stays in drawer for next shift',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClosingNotesCard extends StatelessWidget {
  const _ClosingNotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLOSING NOTES', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            maxLines: 4,
            minHeight: 88,
            hint: 'Any incidents, discrepancies, or notes for the next shift…',
            style: CashFigmaStyles.notesInput(),
          ),
        ],
      ),
    );
  }
}

