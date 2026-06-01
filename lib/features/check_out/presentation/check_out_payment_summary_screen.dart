import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../domain/checkout_preview_format.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
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
    extends State<CheckOutPaymentSummaryScreen> with WidgetsBindingObserver {
  late final TextEditingController _driverOutCtrl;
  String? _driverOutFieldTicketId;

  static const _orange = Color(0xFFF68D00);
  static const _doubleZeroBgLight = Color(0xFFFFF5DE);

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
    WidgetsBinding.instance.addObserver(this);
    _driverOutCtrl = TextEditingController();
    _driverOutCtrl.addListener(_onDriverOutChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CheckOutCubit>().refreshBreakdown();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _driverOutCtrl.removeListener(_onDriverOutChanged);
    _driverOutCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // IME open/close often does not update MediaQuery.viewInsets on Android
    // (adjustResize) — rebuild so layout can switch out of side-by-side mode.
    if (mounted) setState(() {});
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

  void _dismissDriverKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _appendDigit(String d) {
    _dismissDriverKeyboard();
    final cubit = context.read<CheckOutCubit>();
    var s = cubit.state.amountTenderedInput.replaceAll(RegExp(r'\D'), '');
    if (s == '0') s = '';
    s += d;
    cubit.setAmountTenderedInput(s.isEmpty ? '0' : s);
  }

  void _appendDoubleZero() {
    _dismissDriverKeyboard();
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
    final keyboardOpen = isKeyboardVisible(context);
    final peso2 = PesoCurrency.currency(decimalDigits: 2);
    final cubit = context.read<CheckOutCubit>();

    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.ticket != b.ticket ||
          a.receiptTicket != b.receiptTicket ||
          a.preview != b.preview ||
          a.breakdown != b.breakdown ||
          a.serverTotal != b.serverTotal ||
          a.isLoadingPreview != b.isLoadingPreview ||
          a.isSubmitting != b.isSubmitting ||
          a.amountTenderedInput != b.amountTenderedInput ||
          a.driverOut != b.driverOut ||
          a.isLostTicket != b.isLostTicket ||
          a.rates != b.rates ||
          a.checkoutBlockMessage != b.checkoutBlockMessage,
      builder: (context, state) {
        if (state.needsScanStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }
        if (state.isReceiptStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-5');
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

        final timeInLabel = formatPreviewTime(row.checkInAt);
        final dateInLabel = formatPreviewDate(row.checkInAt);
        final timeOutLabel =
            DateFormat('h:mm a').format(PhilippineTime.now());
        final durationLabel = state.breakdown != null
            ? CheckoutReceiptSnapshot.durationLabelFromMinutes(
                state.breakdown!.durationMinutes,
              )
            : '—';

        final blockMsg = state.checkoutBlockMessage;
        final canConfirm = blockMsg == null &&
            !state.isSubmitting &&
            !state.isLoadingPreview &&
            total != null &&
            tendered != null &&
            tendered + 1e-6 >= total;

        Widget child = state.isLoadingPreview
            ? const Center(child: CircularProgressIndicator())
            : total == null
            ? Text(
                state.previewError.isNotEmpty
                    ? state.previewError
                    : 'Waiting for server pricing…',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppThemeColors.of(context).textSecondary,
                ),
              )
            : LayoutBuilder(
                builder: (context, c) {
                  final tc = AppThemeColors.of(context);
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final keyBg = tc.hintFill;
                  final border = tc.cardBorder;
                  final doubleZeroBg =
                      isDark ? tc.inputFill : _doubleZeroBgLight;
                  // Figma: ticket + rates left, cash keypad right (keep columns on tablet
                  // even when the valet name field opens the IME).
                  final sideBySide = c.maxWidth >= 480;
                  final hideKeypadForIme = keyboardOpen && sideBySide;

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
                    flatBlockHours: state.flatBlockHours,
                    driverOutController: _driverOutCtrl,
                    isLostTicket: state.isLostTicket,
                    lostTicketFee: state.lostTicketFeePesos,
                    onLostTicketChanged: cubit.setLostTicket,
                  );

                  final keypad = _PaymentKeypad(
                    keyBg: keyBg,
                    border: border,
                    doubleZeroBg: doubleZeroBg,
                    orange: _orange,
                    peso2: peso2,
                    onDigit: _appendDigit,
                    onDoubleZero: _appendDoubleZero,
                    onQuick: _addQuick,
                    onBackspace: _backspace,
                    onClear: _clearTendered,
                  );

                  final rightPane = _PaymentRightPane(
                    tenderedLabel: tenderedLabel,
                    changeLabel: changeLabel,
                    totalDue: total,
                    peso2: peso2,
                    onExact: () => _setTenderPesos(total),
                    keypad: keypad,
                    showKeypad: !hideKeypadForIme,
                  );

                  final Widget paymentLayout;
                  if (sideBySide) {
                    paymentLayout = Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: leftPane,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            width: 1,
                            color: CheckOutUiTokens.hairlineOf(context),
                          ),
                        ),
                        Expanded(flex: 10, child: rightPane),
                      ],
                    );
                  } else if (keyboardOpen) {
                    paymentLayout = SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftPane,
                          const SizedBox(height: 12),
                          _CompactCashSummary(
                            tenderedLabel: tenderedLabel,
                            changeLabel: changeLabel,
                          ),
                        ],
                      ),
                    );
                  } else {
                    paymentLayout = SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftPane,
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: CheckOutUiTokens.hairlineOf(context),
                          ),
                          const SizedBox(height: 12),
                          rightPane,
                        ],
                      ),
                    );
                  }

                  if (blockMsg == null) {
                    return sideBySide
                        ? SizedBox.expand(child: paymentLayout)
                        : paymentLayout;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: CheckOutUiTokens.chipFillOf(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            blockMsg,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: DashboardStyles.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      paymentLayout,
                    ],
                  );
                },
              );

        return CheckOutStepBody(
          scrollable: false,
          footer: CheckoutVehicleReviewFooter(
            onBack: state.isSubmitting ? () {} : () => context.go('/check-out/step-3'),
            primaryLabel: state.isSubmitting ? 'Completing…' : 'Confirm payment',
            onPrimary: canConfirm ? () => _confirm(context) : null,
            primaryBusy: state.isSubmitting,
          ),
          child: child,
        );
      },
    );
  }

}

/// Minimal cash lines shown while the driver-name keyboard is open.
class _CompactCashSummary extends StatelessWidget {
  const _CompactCashSummary({
    required this.tenderedLabel,
    required this.changeLabel,
  });

  final String tenderedLabel;
  final String changeLabel;

  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: CheckOutUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: CheckOutUiTokens.cardBgOf(context),
        borderRadius: BorderRadius.circular(CheckOutUiTokens.cardRadius),
        border: Border.all(color: CheckOutUiTokens.hairlineOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash tendered',
                style: CheckOutUiTokens.fieldLabelOf(context),
              ),
              Text(
                tenderedLabel,
                style: CheckOutUiTokens.amountHero(color: _orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change',
                style: CheckOutUiTokens.bodyOf(context).copyWith(color: _green),
              ),
              Text(
                changeLabel,
                style: CheckOutUiTokens.money(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dismiss keyboard to use the cash keypad',
            style: CheckOutUiTokens.helperOf(context),
          ),
        ],
      ),
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
    this.showKeypad = true,
  });

  final String tenderedLabel;
  final String changeLabel;
  final num totalDue;
  final NumberFormat peso2;
  final VoidCallback onExact;
  final Widget keypad;
  final bool showKeypad;

  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);
  static const _tenderHighlightLight = Color(0xFFFFF5DE);

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    final tc = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenderBg = isDark ? tc.inputFill : _tenderHighlightLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

        final keypadSlot = !showKeypad
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Dismiss keyboard to use the cash keypad',
                  style: CheckOutUiTokens.helperOf(context),
                ),
              )
            : boundedHeight
            ? Expanded(child: keypad)
            : Padding(
                padding: const EdgeInsets.only(top: gap),
                child: SizedBox(height: 220, child: keypad),
              );

        final children = <Widget>[
          Text('CASH TENDERED', style: CheckOutUiTokens.fieldLabelOf(context)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: tenderBg,
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
                style: CheckOutUiTokens.money(
                  fontSize: CheckOutUiTokens.helper().fontSize,
                  fontWeight: FontWeight.w600,
                  color: _orange,
                ),
              ),
            ),
          ),
          if (showKeypad && boundedHeight) const SizedBox(height: gap),
          keypadSlot,
          const SizedBox(height: gap),
          Container(
            width: double.infinity,
            padding: CheckOutUiTokens.cardPaddingDense,
            decoration: BoxDecoration(
              color: CheckOutUiTokens.changeDueBgOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change',
                  style: CheckOutUiTokens.bodyOf(context).copyWith(
                    color: _green,
                  ),
                ),
                Text(
                  changeLabel,
                  style: CheckOutUiTokens.money(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: children,
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
    final digitStyle = CheckOutUiTokens.moneyOf(
      context,
      fontWeight: FontWeight.w500,
    );

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
                      child: Icon(
                        Icons.backspace_outlined,
                        color: AppThemeColors.of(context).textSecondary,
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
