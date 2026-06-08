import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/formatting/peso_currency.dart';
import '../../../core/session/cashier_shift_schedule.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/connectivity/internet_reachability.dart';
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
            // Shift has NOT been opened yet — do not update AuthBloc here.
            await InheritedTransactionsModal.show(
              context,
              inheritedTransactions: state.inheritedTransactions,
              onAcknowledge: () {
                context.read<OpenCashCubit>().adoptInheritedTickets();
              },
              onCancel: () {
                context.read<OpenCashCubit>().cancelPendingShift();
              },
            );
          }
          if (state is OpenCashCancelled) {
            // No shift was created — AuthBloc is still closed, nothing to reset.
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cancelled. Adjust your opening float and try again.'),
              ),
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

  /// Decimal amount text (e.g. "150.50"). "0" means zero pesos.
  String _amountText = '0';

  String? _staffName;
  String _branchName = '';
  String _areaName = '';
  CashierShiftSchedule? _shiftSchedule;
  bool _online = true;

  static final _pesoFmt =
      PesoCurrency.currency(decimalDigits: 2, spaceAfter: true);
  static final _longDate = DateFormat('EEEE, MMMM d, y');
  static final _shiftDate = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadContext());
  }

  /// Staff from active session; branch/area from cached device site (prefs / claim).
  Future<void> _loadContext() async {
    final repo = context.read<AuthRepository>();
    final session = await repo.getActiveSession();
    if (session == null || !mounted) return;
    final acct = await repo.offlineAccountById(session.userId);
    if (!mounted) return;
    final site = await repo.branchAndAreaFromDb();
    final schedule = await repo.shiftScheduleForLocalUser(session.userId);
    final hasInternet = await InternetReachability.hasInternet();
    setState(() {
      _online = hasInternet;
      _staffName = acct?.fullName ?? acct?.email ?? '—';
      _branchName = site.branch;
      _areaName = site.area;
      _shiftSchedule = schedule;
    });
    if (mounted) {
      unawaited(context.read<BranchConfigService>().syncFromServerForDeviceBranch());
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

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

  void _tapKey(String key) {
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
  }

  String get _displayAmount => _pesoFmt.format(_parsedAmount);

  String get _shiftTodayLabel {
    final schedule = _shiftSchedule;
    if (schedule == null) return 'No shift today';
    return schedule.todayShiftLabel(DateTime.now());
  }

  bool get _hasShiftToday {
    final schedule = _shiftSchedule;
    if (schedule == null) return false;
    return schedule.hasShiftOnDate(DateTime.now());
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
    final notes = _notesCtrl.text.trim();
    await cubit.openShift(
      localUserId: localUserId,
      sessionId: session.id,
      openingFloat: _parsedAmount,
      branch: _branchName,
      area: _areaName,
      shiftDate: _shiftDate.format(now),
      openingNotes: notes.isEmpty ? null : notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowLabel = _longDate.format(now);
    final headerSub = (_branchName.isNotEmpty && _areaName.isNotEmpty)
        ? '$nowLabel · $_branchName : $_areaName'
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
                        const SizedBox(height: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'CASHIER / STAFF',
                                                value: _staffName ?? '—',
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'SHIFT TODAY',
                                                value: _shiftTodayLabel,
                                                emphasizeNoShift:
                                                    !_hasShiftToday,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'BRANCH',
                                                value: _branchName.isEmpty
                                                    ? '—'
                                                    : _branchName,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _ReadOnlyField(
                                                label: 'AREA',
                                                value: _areaName.isEmpty
                                                    ? '—'
                                                    : _areaName,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'OPENING BALANCE',
                                          style: CashFigmaStyles.sectionCaps(),
                                        ),
                                        const SizedBox(height: 6),
                                        CashAmountBox(text: _displayAmount),
                                        const SizedBox(height: 8),
                                        CashKeypad(
                                          onKey: busy ? (_) {} : _tapKey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
                                        const BoxConstraints(maxWidth: 360),
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
                                                  const SizedBox(height: 10),
                                                  _NotesCard(
                                                    controller: _notesCtrl,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _ShiftSummaryCard(
                                                    staff: _staffName ?? '—',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
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
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.emphasizeNoShift = false,
  });

  final String label;
  final String value;
  final bool emphasizeNoShift;

  @override
  Widget build(BuildContext context) {
    return LabeledAppTextField(
      label: label,
      labelStyle: CashFigmaStyles.fieldLabel(),
      gap: 3,
      child: AppReadOnlyField(
        minHeight: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CashFigmaStyles.fieldValue().copyWith(
            color: emphasizeNoShift
                ? const Color(0xFF6B7280)
                : const Color(0xFF0A1B39),
            fontStyle:
                emphasizeNoShift ? FontStyle.italic : FontStyle.normal,
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: CashFigmaStyles.totalCardLabel()),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bigValue,
              textAlign: TextAlign.center,
              style: CashFigmaStyles.totalCardAmount(),
            ),
          ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES (OPTIONAL)', style: CashFigmaStyles.notesSectionLabel()),
          const SizedBox(height: 6),
          AppTextField(
            controller: controller,
            maxLines: 3,
            minHeight: 64,
            hint: 'e.g. received balance from supervisor. . .',
            style: CashFigmaStyles.notesInput(),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummaryCard extends StatefulWidget {
  const _ShiftSummaryCard({required this.staff});

  final String staff;

  @override
  State<_ShiftSummaryCard> createState() => _ShiftSummaryCardState();
}

class _ShiftSummaryCardState extends State<_ShiftSummaryCard> {
  static final _phDate = DateFormat('EEEE, MMMM d, y');
  static final _phTime = DateFormat('h:mm:ss a');

  Timer? _clock;
  late String _dateLabel;
  late String _timeLabel;

  @override
  void initState() {
    super.initState();
    _applyPhClock();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(_applyPhClock);
      },
    );
  }

  void _applyPhClock() {
    final phNow = PhilippineTime.now();
    _dateLabel = _phDate.format(phNow);
    _timeLabel = _phTime.format(phNow);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: CashFigmaStyles.shiftSummaryRow(isLabel: true)),
          Flexible(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: CashFigmaStyles.shiftSummaryRow(isLabel: false),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHIFT SUMMARY', style: CashFigmaStyles.shiftSummaryTitle()),
          const SizedBox(height: 8),
          row('Staff', widget.staff),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Date', _dateLabel),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.black.withValues(alpha: 0.13),
          ),
          row('Time', _timeLabel),
        ],
      ),
    );
  }
}
