import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../sync/state/sync_cubit.dart';
import '../domain/checkout_pricing.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';

/// Step 4 — Payment summary, keypad, cash tendered, and change
/// ([Figma 38-3066](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=38-3066),
/// [Figma 38-3315](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=38-3315)).
class CheckOutPaymentSummaryScreen extends StatefulWidget {
  const CheckOutPaymentSummaryScreen({super.key});

  @override
  State<CheckOutPaymentSummaryScreen> createState() =>
      _CheckOutPaymentSummaryScreenState();
}

class _CheckOutPaymentSummaryScreenState
    extends State<CheckOutPaymentSummaryScreen> {
  var _submitting = false;
  var _seededTender = false;

  static const _grey500 = Color(0xFF6C7688);
  static const _border = Color(0xFFC0C0BF);
  static const _plateBlue = Color(0xFF0068D3);
  static const _plateBarBg = Color(0xFFA7D6FF);
  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);
  static const _keyBg = Color(0xFFF8F9FB);
  static const _doubleZeroBg = Color(0xFFFFF5DE);

  static const List<String> _pesoGlyphFallback = ['Noto Sans', 'Roboto'];

  static TextStyle _poppins(
    double size,
    FontWeight w,
    Color c, {
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      height: height,
      color: c,
    ).copyWith(fontFamilyFallback: _pesoGlyphFallback);
  }

  static String _vehicleSubtitle(Ticket row) {
    final parts = <String>[
      row.vehicleBrand.trim(),
      row.vehicleColor.trim(),
      row.vehicleType.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  static String _durationSoFar(int timeInUnix) {
    final inDt = DateTime.fromMillisecondsSinceEpoch(timeInUnix * 1000);
    final d = DateTime.now().difference(inDt);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m mins';
    return '$h hrs $m mins';
  }

  static String _succeedingLineLabel(CheckoutBreakdown b) {
    if (b.succeedingPortionPesos <= 0) return '';
    final flatMins = CheckoutPricing.defaultFlatBlockHours * 60;
    final extraMins = (b.durationMinutes - flatMins).clamp(0, 1 << 30);
    return '+ $extraMins mins Succeeding';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CheckOutCubit>();
      cubit.refreshBreakdown();
      final s = cubit.state;
      if (!_seededTender &&
          s.amountTenderedInput.trim().isEmpty &&
          s.breakdown != null) {
        _seededTender = true;
        cubit.setAmountTenderedInput(s.breakdown!.totalPesos.toString());
      }
    });
  }

  Future<void> _confirm(BuildContext context) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = context.read<AuthRepository>();
      final cubit = context.read<CheckOutCubit>();
      final sync = context.read<SyncCubit>();
      final session = await auth.getActiveSession();
      if (session == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No active session.')),
        );
        return;
      }
      final shift = await auth.getOpenShiftForUser(session.userId);
      if (shift == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Open a cash shift first.')),
        );
        return;
      }
      final err = await cubit.finalizeIfValid();
      if (!context.mounted) return;
      if (err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      await sync.flush();
      if (!context.mounted) return;
      context.go('/check-out/step-6');
    } catch (e, st) {
      ValetLog.error('check_out/payment_summary', 'confirm failed', e, st);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not complete checkout.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _appendDigit(String d) {
    final cubit = context.read<CheckOutCubit>();
    var s = cubit.state.amountTenderedInput.replaceAll(RegExp(r'\D'), '');
    if (s == '0') s = '';
    s += d;
    cubit.setAmountTenderedInput(s.isEmpty ? '0' : s);
  }

  void _appendDoubleZero() {
    final cubit = context.read<CheckOutCubit>();
    var s = cubit.state.amountTenderedInput.replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) s = '0';
    s += '00';
    cubit.setAmountTenderedInput(s);
  }

  void _addQuick(int pesos) {
    final cubit = context.read<CheckOutCubit>();
    final cur = int.tryParse(
          cubit.state.amountTenderedInput.replaceAll(RegExp(r'\D'), ''),
        ) ??
        0;
    cubit.setAmountTenderedInput((cur + pesos).toString());
  }

  void _backspace() {
    final cubit = context.read<CheckOutCubit>();
    var s = cubit.state.amountTenderedInput.replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return;
    s = s.substring(0, s.length - 1);
    cubit.setAmountTenderedInput(s);
  }

  void _clearTendered() {
    context.read<CheckOutCubit>().setAmountTenderedInput('');
  }

  @override
  Widget build(BuildContext context) {
    final peso2 = PesoCurrency.currency(decimalDigits: 2);

    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.breakdown != b.breakdown ||
          a.amountTenderedInput != b.amountTenderedInput,
      builder: (context, state) {
        if (state.ticket == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final row = state.ticket!;
        final b = state.breakdown;
        final tendered = context.read<CheckOutCubit>().parsedTendered();
        final change = context.read<CheckOutCubit>().changeDue();

        final timeInUnix = DateTime.tryParse(row.checkInAt)
                ?.millisecondsSinceEpoch ??
            0;
        final timeIn = DateTime.fromMillisecondsSinceEpoch(timeInUnix);
        final now = DateTime.now();
        final timeInLabel = DateFormat('h:mm a').format(timeIn);
        final dateInLabel = DateFormat('MMMM d, y').format(timeIn);
        final timeOutLabel = DateFormat('h:mm a').format(now);
        final durationLabel = _durationSoFar(timeInUnix ~/ 1000);

        final canConfirm = !_submitting &&
            b != null &&
            tendered != null &&
            tendered + 1e-6 >= b.totalPesos;

        return CheckOutStepBody(
          scrollable: false,
          footer: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          context.read<CheckOutCubit>().reset();
                          context.go('/dashboard');
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFC0C0BF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => context.go('/check-out/step-3'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFC0C0BF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: (_submitting || !canConfirm)
                      ? null
                      : () => _confirm(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: const Color(0xFFF68D00),
                    disabledBackgroundColor: const Color(0xFFF68D00)
                        .withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _submitting ? 'Saving…' : 'Next: Proceed to payment',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: b == null
              ? Text(
                  'Rates unavailable. Re-open checkout after login sync.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 900;

                    final leftPane = SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _vehicleTimeCard(
                            row: row,
                            timeInLabel: timeInLabel,
                            dateInLabel: dateInLabel,
                            timeOutLabel: timeOutLabel,
                            durationLabel: durationLabel,
                          ),
                          const SizedBox(height: 16),
                          _rateBreakdownCard(b: b, peso2: peso2),
                        ],
                      ),
                    );

                    final rightPane = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CASH TENDERED',
                          style: _poppins(15, FontWeight.w500, _grey500),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 3,
                          child: _PaymentKeypad(
                            keyBg: _keyBg,
                            border: _border,
                            doubleZeroBg: _doubleZeroBg,
                            orange: _orange,
                            peso2: peso2,
                            onDigit: _appendDigit,
                            onDoubleZero: _appendDoubleZero,
                            onQuick: _addQuick,
                            onBackspace: _backspace,
                            onClear: _clearTendered,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7EC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _orange),
                          ),
                          child: Text(
                            tendered == null
                                ? '${PesoCurrency.symbol}0.00'
                                : peso2.format(tendered),
                            textAlign: TextAlign.center,
                            style: _poppins(30, FontWeight.w700, _orange),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F9F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _green),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change',
                                style: _poppins(15, FontWeight.w500, _green),
                              ),
                              Text(
                                change == null || change < 0
                                    ? '—'
                                    : peso2.format(change),
                                style: _poppins(25, FontWeight.w700, _green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final body = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: leftPane),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  width: 1,
                                  color: Colors.black.withValues(alpha: 0.13),
                                ),
                              ),
                              Expanded(flex: 4, child: rightPane),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 380, child: leftPane),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              Expanded(child: rightPane),
                            ],
                          );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _vehicleReviewPaymentHeader(),
                        const SizedBox(height: 20),
                        Expanded(child: body),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _vehicleTimeCard({
    required Ticket row,
    required String timeInLabel,
    required String dateInLabel,
    required String timeOutLabel,
    required String durationLabel,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
            color: _plateBarBg,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                row.plateNumber.isEmpty ? '—' : row.plateNumber,
                style: _poppins(30, FontWeight.w700, _plateBlue),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _vehicleSubtitle(row),
            style: _poppins(15, FontWeight.w500, const Color(0xFF0A1B39)),
          ),
          const SizedBox(height: 20),
          _timeBlock(
            label: 'TIME OUT',
            time: timeOutLabel,
            sub: durationLabel,
            timeColor: _orange,
            subColor: _green,
          ),
          const SizedBox(height: 20),
          _timeBlock(
            label: 'TIME IN',
            time: timeInLabel,
            sub: dateInLabel,
            timeColor: const Color(0xFF0A1B39),
            subColor: const Color(0xFF0A1B39),
          ),
        ],
      ),
    );
  }

  Widget _timeBlock({
    required String label,
    required String time,
    required String sub,
    required Color timeColor,
    required Color subColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _poppins(15, FontWeight.w500, _grey500),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: timeColor,
          ),
        ),
        Text(
          sub,
          style: _poppins(15, FontWeight.w500, subColor),
        ),
      ],
    );
  }

  Widget _rateBreakdownCard({
    required CheckoutBreakdown b,
    required NumberFormat peso2,
  }) {
    final flatH = CheckoutPricing.defaultFlatBlockHours;
    final succeedingLabel = _succeedingLineLabel(b);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RATE BREAKDOWN',
            style: _poppins(15, FontWeight.w500, const Color(0xFF0A1B39)),
          ),
          const SizedBox(height: 25),
          _breakdownRow(
            'First $flatH hours',
            peso2.format(b.flatPortionPesos),
          ),
          if (succeedingLabel.isNotEmpty) ...[
            const SizedBox(height: 14),
            _breakdownRow(
              succeedingLabel,
              peso2.format(b.succeedingPortionPesos),
            ),
          ],
          const SizedBox(height: 14),
          _breakdownRow(
            'Overnight Fee',
            b.overnightApplied
                ? peso2.format(b.overnightPortionPesos)
                : '—',
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Due',
                style: _poppins(15, FontWeight.w500, _grey500),
              ),
              Text(
                peso2.format(b.totalPesos),
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: _poppins(12, FontWeight.w500, _grey500),
              ),
            ),
            Text(
              value,
              style: _poppins(12, FontWeight.w500, const Color(0xFF0A1B39)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.13)),
      ],
    );
  }

  /// Figma: centered VEHICLE REVIEW + payment-phase progress dots.
  Widget _vehicleReviewPaymentHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'VEHICLE REVIEW',
          textAlign: TextAlign.center,
          style: _poppins(15, FontWeight.w500, _grey500),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentKeypad extends StatelessWidget {
  const _PaymentKeypad({
    required this.keyBg,
    required this.border,
    required this.doubleZeroBg,
    required this.orange,
    required this.peso2,
    required this.onDigit,
    required this.onDoubleZero,
    required this.onQuick,
    required this.onBackspace,
    required this.onClear,
  });

  final Color keyBg;
  final Color border;
  final Color doubleZeroBg;
  final Color orange;
  final NumberFormat peso2;
  final void Function(String) onDigit;
  final VoidCallback onDoubleZero;
  final void Function(int) onQuick;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const _rowH = 52.0;
  static const _gap = 11.0;

  Widget _key({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? bg,
    Color? borderColor,
  }) {
    return Material(
      color: bg ?? keyBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor ?? border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digitStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF0A1B39),
    );

    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _key(
                        child: Text('7', style: digitStyle),
                        onTap: () => onDigit('7'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('8', style: digitStyle),
                        onTap: () => onDigit('8'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('9', style: digitStyle),
                        onTap: () => onDigit('9'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _key(
                        child: Text('4', style: digitStyle),
                        onTap: () => onDigit('4'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('5', style: digitStyle),
                        onTap: () => onDigit('5'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('6', style: digitStyle),
                        onTap: () => onDigit('6'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _key(
                        child: Text('1', style: digitStyle),
                        onTap: () => onDigit('1'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('2', style: digitStyle),
                        onTap: () => onDigit('2'),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _key(
                        child: Text('3', style: digitStyle),
                        onTap: () => onDigit('3'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        SizedBox(
          height: _rowH,
          child: Row(
            children: [
              Expanded(
                child: _key(
                  child: Text(
                    peso2.format(1000),
                    style: digitStyle,
                  ),
                  onTap: () => onQuick(1000),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _key(
                  child: Text(
                    peso2.format(500),
                    style: digitStyle,
                  ),
                  onTap: () => onQuick(500),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _key(
                  child: Text(
                    peso2.format(200),
                    style: digitStyle,
                  ),
                  onTap: () => onQuick(200),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        SizedBox(
          height: _rowH,
          child: Row(
            children: [
              Expanded(
                child: _key(
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Color(0xFF6C7688),
                    size: 22,
                  ),
                  onTap: onBackspace,
                  onLongPress: onClear,
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _key(
                  child: Text('0', style: digitStyle),
                  onTap: () => onDigit('0'),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _key(
                  child: Text(
                    '00',
                    style: digitStyle.copyWith(color: orange),
                  ),
                  onTap: onDoubleZero,
                  bg: doubleZeroBg,
                  borderColor: orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
