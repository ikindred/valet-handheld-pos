import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/formatting/peso_currency.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/branch_config_service.dart';
import '../../auth/state/auth_bloc.dart';
import '../cubits/open_cash_cubit.dart';
import '../cubits/open_cash_state.dart';
import 'widgets/cash_figma_text_styles.dart';
import 'widgets/cash_widgets.dart';
import '../widgets/inherited_transactions_modal.dart';

/// [BlocProvider] lives here so keypad [setState] does not recreate [OpenCashCubit]
/// (which would drop [OpenCashReady] before [BlocListener] runs).
class OpenCashScreen extends StatelessWidget {
  const OpenCashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OpenCashCubit(context.read<AuthRepository>()),
      child: BlocConsumer<OpenCashCubit, OpenCashState>(
        listener: (context, state) async {
          if (state is OpenCashHasInheritedTransactions) {
            context.read<AuthBloc>().add(
                  const AuthCashSessionUpdated(CashSessionStatus.open),
                );
            InheritedTransactionsModal.show(
              context,
              inheritedTransactions: state.inheritedTransactions,
              onAcknowledge: () async {
                Navigator.of(context).pop();
                await context.read<OpenCashCubit>().adoptInheritedTickets();
              },
            );
          }
          if (state is OpenCashReady) {
            ValetLog.debug(
              'OpenCashScreen',
              'BlocListener saw OpenCashReady → AuthCashSessionUpdated + go /dashboard',
            );
            final authBloc = context.read<AuthBloc>();
            final current = authBloc.state;
            if (current is! AuthAuthenticated ||
                current.cashSessionStatus != CashSessionStatus.open) {
              authBloc.add(const AuthCashSessionUpdated(CashSessionStatus.open));
              await authBloc.stream.firstWhere(
                (s) =>
                    s is AuthAuthenticated &&
                    s.cashSessionStatus == CashSessionStatus.open,
              );
            }
            if (!context.mounted) return;
            context.go('/dashboard');
          }
          if (state is OpenCashError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return _OpenCashView(busy: state is OpenCashLoading);
        },
      ),
    );
  }
}

class _OpenCashView extends StatefulWidget {
  const _OpenCashView({required this.busy});

  final bool busy;

  @override
  State<_OpenCashView> createState() => _OpenCashViewState();
}

class _OpenCashViewState extends State<_OpenCashView> {
  final _notesCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  /// Whole peso digits only (no decimal point). "0" means zero pesos.
  String _digits = '0';

  String? _staffName;
  bool _online = true;

  static final _pesoFmt =
      PesoCurrency.currency(decimalDigits: 2, spaceAfter: true);
  static final _longDate = DateFormat('EEEE, MMMM d, y');
  static final _shiftDate = DateFormat('yyyy-MM-dd');

  void _onBranchAreaChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _branchCtrl.addListener(_onBranchAreaChanged);
    _areaCtrl.addListener(_onBranchAreaChanged);
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadContext());
  }

  Future<void> _loadContext() async {
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    final session = await repo.getActiveSession();
    if (session == null || !mounted) return;
    final acct = await repo.offlineAccountById(session.userId);
    if (!mounted) return;
    final site = await repo.branchAndAreaFromDb();
    _branchCtrl.text = site.branch;
    _areaCtrl.text = site.area;
    setState(() {
      _online = !OfflineModePrefs.read(prefs);
      _staffName = acct?.fullName ?? acct?.email ?? '—';
    });
    if (mounted) {
      unawaited(context.read<BranchConfigService>().syncFromServerForDeviceBranch());
    }
  }

  @override
  void dispose() {
    _branchCtrl.removeListener(_onBranchAreaChanged);
    _areaCtrl.removeListener(_onBranchAreaChanged);
    _notesCtrl.dispose();
    _branchCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  static const int _maxDigitChars = 12;

  void _tapKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_digits.length <= 1) {
          _digits = '0';
        } else {
          _digits = _digits.substring(0, _digits.length - 1);
        }
        return;
      }
      if (key == '00') {
        if (_digits == '0') return;
        _appendDigits('00');
        return;
      }
      if (key == '0') {
        if (_digits == '0') return;
        _appendDigits('0');
        return;
      }
      if (_digits == '0') {
        _digits = key;
      } else {
        _appendDigits(key);
      }
    });
  }

  void _appendDigits(String chunk) {
    if (_digits.length + chunk.length > _maxDigitChars) return;
    _digits += chunk;
  }

  String get _displayAmount {
    final n = int.tryParse(_digits) ?? 0;
    return _pesoFmt.format(n);
  }

  Future<void> _submit(OpenCashCubit cubit) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final userIdStr = auth.userId;
    if (userIdStr == null) return;
    final localUserId = int.tryParse(userIdStr);
    if (localUserId == null) return;
    final repo = context.read<AuthRepository>();
    final session = await repo.getActiveSession();
    if (session == null) return;
    final now = DateTime.now();
    final pesos = int.tryParse(_digits) ?? 0;
    final notes = _notesCtrl.text.trim();
    await cubit.openShift(
      localUserId: localUserId,
      sessionId: session.id,
      openingFloat: pesos.toDouble(),
      branch: _branchCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      shiftDate: _shiftDate.format(now),
      openingNotes: notes.isEmpty ? null : notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowLabel = _longDate.format(now);
    final b = _branchCtrl.text.trim();
    final a = _areaCtrl.text.trim();
    final headerSub = (b.isNotEmpty && a.isNotEmpty)
        ? '$nowLabel · $b : $a'
        : '$nowLabel · ${AppConfig.defaultDeviceBranch} : ${AppConfig.defaultDeviceArea}';

    final busy = widget.busy;
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
                          title: 'Open Cash',
                          subtitle: headerSub,
                          online: _online,
                        ),
                        const SizedBox(height: 22),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SHIFT INFORMATION',
                                          style: CashFigmaStyles.sectionCaps(),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'CASHIER / STAFF',
                                                value: _staffName ?? '—',
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'SHIFT DATE',
                                                value: _longDate.format(now),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: LabeledAppTextField(
                                                label: 'BRANCH',
                                                child: AppTextField(
                                                  controller: _branchCtrl,
                                                  minHeight: 40,
                                                  hint: 'Branch name',
                                                  style: CashFigmaStyles
                                                      .fieldValue(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: LabeledAppTextField(
                                                label: 'AREA',
                                                child: AppTextField(
                                                  controller: _areaCtrl,
                                                  minHeight: 40,
                                                  hint: 'Area',
                                                  style: CashFigmaStyles
                                                      .fieldValue(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 22),
                                        Text(
                                          'OPENING BALANCE',
                                          style: CashFigmaStyles.sectionCaps(),
                                        ),
                                        const SizedBox(height: 10),
                                        CashAmountBox(text: _displayAmount),
                                        const SizedBox(height: 12),
                                        CashKeypad(
                                          onKey: busy ? (_) {} : _tapKey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Container(
                                    width: 1,
                                    color: Colors.black.withValues(alpha: 0.13),
                                  ),
                                ),
                                Flexible(
                                  flex: 2,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 420),
                                    child: TextFieldTapRegion(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  _SummaryCard(
                                                    title:
                                                        'TOTAL OPENING BALANCE',
                                                    bigValue: _displayAmount,
                                                    subtitle:
                                                        'Counted & Verified by staff',
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _NotesCard(
                                                    controller: _notesCtrl,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _ShiftSummaryCard(
                                                    staff: _staffName ?? '—',
                                                    date: _longDate.format(now),
                                                    time: DateFormat.jm()
                                                        .format(now),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 54,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                textStyle: CashFigmaStyles
                                                    .filledActionLabel(),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: busy
                                                  ? null
                                                  : () => _submit(
                                                        context
                                                            .read<
                                                                OpenCashCubit>(),
                                                      ),
                                              child: busy
                                                  ? const SizedBox(
                                                      height: 22,
                                                      width: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Open Cash and Start Shift',
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LabeledAppTextField(
      label: label,
      child: AppReadOnlyField(
        minHeight: 40,
        child: Text(value, style: CashFigmaStyles.fieldValue()),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.bigValue,
    required this.subtitle,
  });

  final String title;
  final String bigValue;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: CashFigmaStyles.totalCardLabel()),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bigValue,
              textAlign: TextAlign.center,
              style: CashFigmaStyles.totalCardAmount(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: CashFigmaStyles.totalCardLabel(),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

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
          Text('NOTES (OPTIONAL)', style: CashFigmaStyles.notesSectionLabel()),
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            maxLines: 4,
            minHeight: 88,
            hint: 'e.g. received balance from supervisor. . .',
            style: CashFigmaStyles.notesInput(),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({
    required this.staff,
    required this.date,
    required this.time,
  });

  final String staff;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: CashFigmaStyles.shiftSummaryRow(isLabel: true)),
          Text(right, style: CashFigmaStyles.shiftSummaryRow(isLabel: false)),
        ],
      );
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
          Text('SHIFT SUMMARY', style: CashFigmaStyles.shiftSummaryTitle()),
          const SizedBox(height: 14),
          row('Staff', staff),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Date', date),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Time', time),
        ],
      ),
    );
  }
}
