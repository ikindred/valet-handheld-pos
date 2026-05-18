import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../domain/checkout_preview_format.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';
import 'widgets/checkout_payment_left_pane.dart';
import 'widgets/checkout_vehicle_review_footer.dart';

/// Step 4 — Payment summary, keypad, cash tendered, and change
/// ([Figma 38-3066](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=38-3066)).
class CheckOutPaymentSummaryScreen extends StatefulWidget {
  const CheckOutPaymentSummaryScreen({super.key});

  @override
  State<CheckOutPaymentSummaryScreen> createState() =>
      _CheckOutPaymentSummaryScreenState();
}

class _CheckOutPaymentSummaryScreenState
    extends State<CheckOutPaymentSummaryScreen> {
  late final TextEditingController _driverOutCtrl;
  String? _driverOutFieldTicketId;

  static const _border = Color(0xFFC0C0BF);
  static const _orange = Color(0xFFF68D00);
  static const _keyBg = Color(0xFFF8F9FB);
  static const _doubleZeroBg = Color(0xFFFFF5DE);

  void _onDriverOutChanged() {
    if (!mounted) return;
    context.read<CheckOutCubit>().setDriverOut(_driverOutCtrl.text);
  }

  void _bindDriverOutFieldToTicket(CheckOutState state) {
    final id = state.ticket?.id;
    if (id == null) return;
    if (_driverOutFieldTicketId != id) {
      _driverOutFieldTicketId = id;
      final text = state.driverOut ?? '';
      if (_driverOutCtrl.text != text) {
        _driverOutCtrl.removeListener(_onDriverOutChanged);
        _driverOutCtrl.text = text;
        _driverOutCtrl.addListener(_onDriverOutChanged);
      }
    }
  }

  /// Keypad stores whole pesos as digits (e.g. `150` → ₱150.00).
  static String _tenderInputFromPesos(num pesos) => pesos.round().toString();

  String _tenderedDisplay(CheckOutCubit cubit, NumberFormat peso2) {
    final t = cubit.parsedTendered();
    if (t != null) return peso2.format(t.toDouble());
    return peso2.format(0);
  }

  @override
  void initState() {
    super.initState();
    _driverOutCtrl = TextEditingController();
    _driverOutCtrl.addListener(_onDriverOutChanged);
  }

  @override
  void dispose() {
    _driverOutCtrl.removeListener(_onDriverOutChanged);
    _driverOutCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<CheckOutCubit>();
    if (cubit.state.isSubmitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthRepository>();
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

    final err = await cubit.finalizeCheckout(context);
    if (!context.mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
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

  void _setTenderPesos(num pesos) {
    context.read<CheckOutCubit>().setAmountTenderedInput(
          _tenderInputFromPesos(pesos),
        );
  }

  void _addQuick(int pesos) {
    final cubit = context.read<CheckOutCubit>();
    final cur = cubit.parsedTendered()?.round() ?? 0;
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
    final cubit = context.read<CheckOutCubit>();

    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.preview != b.preview ||
          a.breakdown != b.breakdown ||
          a.serverTotal != b.serverTotal ||
          a.isLoadingPreview != b.isLoadingPreview ||
          a.isSubmitting != b.isSubmitting ||
          a.amountTenderedInput != b.amountTenderedInput ||
          a.driverOut != b.driverOut ||
          a.isLostTicket != b.isLostTicket ||
          a.rates != b.rates,
      builder: (context, state) {
        if (state.ticket == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final row = state.ticket!;
        _bindDriverOutFieldToTicket(state);
        final preview = state.preview;
        final total = state.authoritativeTotal;

        final tendered = cubit.parsedTendered();
        final change = cubit.changeDue();
        final tenderedLabel = _tenderedDisplay(cubit, peso2);
        final changeLabel = change == null || change < 0
            ? peso2.format(0)
            : peso2.format(change.toDouble());

        final pt = preview?.ticket;
        final timeInLabel = pt != null
            ? formatPreviewTime(pt.timeIn)
            : formatPreviewTime(row.checkInAt);
        final dateInLabel = pt != null
            ? formatPreviewDate(pt.timeIn)
            : formatPreviewDate(row.checkInAt);
        final timeOutLabel = pt?.timeOut != null
            ? formatPreviewTime(pt!.timeOut)
            : DateFormat('h:mm a').format(PhilippineTime.now());
        final durationLabel = pt?.duration ??
            preview?.releaseSummary.duration ??
            '—';

        final canConfirm = !state.isSubmitting &&
            !state.isLoadingPreview &&
            total != null &&
            tendered != null &&
            tendered + 1e-6 >= total;

        return CheckOutStepBody(
          scrollable: false,
          footer: CheckoutVehicleReviewFooter(
            onBack: state.isSubmitting ? () {} : () => context.go('/check-out/step-3'),
            primaryLabel: state.isSubmitting ? 'Completing…' : 'Confirm payment',
            onPrimary: canConfirm ? () => _confirm(context) : null,
            primaryBusy: state.isSubmitting,
          ),
          child: state.isLoadingPreview
              ? const Center(child: CircularProgressIndicator())
              : total == null
              ? Text(
                  state.previewError.isNotEmpty
                      ? state.previewError
                      : 'Waiting for server pricing…',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 720;
                    final bodyHeight = c.maxHeight.isFinite
                        ? c.maxHeight
                        : MediaQuery.sizeOf(context).height * 0.55;

                    final leftPane = CheckoutPaymentLeftPane(
                      row: row,
                      preview: preview,
                      serverTotal: total,
                      breakdown: state.breakdown,
                      peso2: peso2,
                      timeInLabel: timeInLabel,
                      dateInLabel: dateInLabel,
                      timeOutLabel: timeOutLabel,
                      durationLabel: durationLabel,
                      driverOutController: _driverOutCtrl,
                      isLostTicket: state.isLostTicket,
                      lostTicketFee: state.lostTicketFeePesos,
                      onLostTicketChanged: cubit.setLostTicket,
                    );

                    final rightPane = _PaymentRightPane(
                      tenderedLabel: tenderedLabel,
                      changeLabel: changeLabel,
                      totalDue: total,
                      peso2: peso2,
                      onExact: () => _setTenderPesos(total),
                      keypad: _PaymentKeypad(
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
                    );

                    if (wide) {
                      return SizedBox(
                        height: bodyHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: leftPane),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Container(
                                width: 1,
                                color: CheckOutUiTokens.hairline,
                              ),
                            ),
                            Expanded(flex: 4, child: rightPane),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 260, child: leftPane),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: CheckOutUiTokens.hairline),
                        const SizedBox(height: 12),
                        SizedBox(height: 320, child: rightPane),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

}

class _PaymentRightPane extends StatelessWidget {
  const _PaymentRightPane({
    required this.tenderedLabel,
    required this.changeLabel,
    required this.totalDue,
    required this.peso2,
    required this.onExact,
    required this.keypad,
  });

  final String tenderedLabel;
  final String changeLabel;
  final num totalDue;
  final NumberFormat peso2;
  final VoidCallback onExact;
  final Widget keypad;

  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        const changeBlockH = 48.0;
        const headerBlockH = 88.0;
        final keypadH = (constraints.maxHeight - headerBlockH - changeBlockH - gap * 3)
            .clamp(168.0, 240.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CASH TENDERED', style: CheckOutUiTokens.fieldLabel()),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5DE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _orange, width: 1.5),
              ),
              child: Text(
                tenderedLabel,
                textAlign: TextAlign.center,
                style: CheckOutUiTokens.amountHero(color: _orange),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onExact,
                style: TextButton.styleFrom(
                  foregroundColor: _orange,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Use exact amount (${peso2.format(totalDue.toDouble())})',
                  style: CheckOutUiTokens.helper().copyWith(
                    color: _orange,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: const ['Noto Sans', 'Roboto'],
                  ),
                ),
              ),
            ),
            SizedBox(height: keypadH, child: keypad),
            const SizedBox(height: gap),
            Container(
              width: double.infinity,
              padding: CheckOutUiTokens.cardPaddingDense,
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
                    style: CheckOutUiTokens.body().copyWith(color: _green),
                  ),
                  Text(
                    changeLabel,
                    style: CheckOutUiTokens.timeDisplay(color: _green),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  static const _gap = 6.0;

  Widget _key({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? bg,
    Color? borderColor,
    double? height,
  }) {
    return Material(
      color: bg ?? keyBg,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
    final digitStyle = CheckOutUiTokens.money(fontWeight: FontWeight.w500);

    return LayoutBuilder(
      builder: (context, constraints) {
        const actionRowH = 36.0;
        const gaps = 5 * _gap;
        final digitRowH =
            ((constraints.maxHeight - 2 * actionRowH - gaps) / 3).clamp(32.0, 40.0);

        Widget digitRow(String a, String b, String c) {
          return SizedBox(
            height: digitRowH,
            child: Row(
              children: [
                Expanded(
                  child: _key(
                    height: digitRowH,
                    child: Text(a, style: digitStyle),
                    onTap: () => onDigit(a),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _key(
                    height: digitRowH,
                    child: Text(b, style: digitStyle),
                    onTap: () => onDigit(b),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _key(
                    height: digitRowH,
                    child: Text(c, style: digitStyle),
                    onTap: () => onDigit(c),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            digitRow('1', '2', '3'),
            const SizedBox(height: _gap),
            digitRow('4', '5', '6'),
            const SizedBox(height: _gap),
            digitRow('7', '8', '9'),
            const SizedBox(height: _gap),
            SizedBox(
              height: actionRowH,
              child: Row(
                children: [
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: Text(
                        '00',
                        style: digitStyle.copyWith(color: orange),
                      ),
                      onTap: onDoubleZero,
                      bg: doubleZeroBg,
                      borderColor: orange,
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: Text('0', style: digitStyle),
                      onTap: () => onDigit('0'),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: Color(0xFF6C7688),
                        size: 20,
                      ),
                      onTap: onBackspace,
                      onLongPress: onClear,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: actionRowH,
              child: Row(
                children: [
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: Text(peso2.format(200), style: digitStyle),
                      onTap: () => onQuick(200),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: Text(peso2.format(500), style: digitStyle),
                      onTap: () => onQuick(500),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _key(
                      height: actionRowH,
                      child: Text(peso2.format(1000), style: digitStyle),
                      onTap: () => onQuick(1000),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
