import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/platform/camera_preview_orientation.dart';
import '../../../core/platform/orientation_lock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../auth/state/auth_bloc.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../check_in/presentation/widgets/check_in_form_fields.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';
import 'widgets/checkout_or_divider.dart';
import 'widgets/checkout_qr_scan_viewport.dart';

/// Step 1 — Scan QR or manual lookup
/// ([Figma 32-1807](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=32-1807)).
class CheckOutScanScreen extends StatefulWidget {
  const CheckOutScanScreen({super.key});

  @override
  State<CheckOutScanScreen> createState() => _CheckOutScanScreenState();
}

class _CheckOutScanScreenState extends State<CheckOutScanScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _ticketCtrl;
  late final TextEditingController _plateCtrl;
  MobileScannerController? _scanner;
  var _scannerReady = false;
  var _scanBusy = false;
  var _lastPreviewTurns = -1;

  static const _twoColumnMinWidth = 560.0;
  static const _viewportSize = 240.0;
  static const _manualMaxWidth = 360.0;

  static const List<String> _pesoFallback = ['Noto Sans', 'Roboto'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticketCtrl = TextEditingController();
    _plateCtrl = TextEditingController();
    unawaited(_initScanner());
  }

  Future<void> _initScanner() async {
    await lockLandscape();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    setState(() {
      _scanner = controller;
      _scannerReady = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await controller.start();
    if (!mounted) return;
    _lastPreviewTurns = cameraPreviewQuarterTurns(
      context,
      cameraBufferSize: controller.value.isInitialized
          ? controller.value.size
          : null,
    );
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || _scanner == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sc = _scanner;
      final turns = cameraPreviewQuarterTurns(
        context,
        cameraBufferSize:
            sc != null && sc.value.isInitialized ? sc.value.size : null,
      );
      if (turns == _lastPreviewTurns) return;
      _lastPreviewTurns = turns;
      unawaited(restartMobileScanner(_scanner));
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticketCtrl.dispose();
    _plateCtrl.dispose();
    final sc = _scanner;
    if (sc != null) unawaited(sc.stop());
    _scanner?.dispose();
    super.dispose();
  }

  Future<void> _afterLookup(Future<void> lookup) async {
    await lookup;
    if (!mounted) return;
    final s = context.read<CheckOutCubit>().state;
    if (s.ticket != null) {
      context.go('/check-out/step-2');
    }
  }

  Future<void> _onCombinedSearch() async {
    final ticket = _ticketCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    if (ticket.isNotEmpty) {
      await _afterLookup(
        context.read<CheckOutCubit>().lookupByTicketCode(ticket),
      );
    } else if (plate.isNotEmpty) {
      await _afterLookup(context.read<CheckOutCubit>().lookupByPlate(plate));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a ticket number or plate, then tap Search.'),
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanBusy || _scanner == null) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final raw = codes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanBusy = true;
    final cubit = context.read<CheckOutCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _scanBusy = false;
        return;
      }
      setState(() {});
      await _afterLookup(cubit.lookupByTicketCode(raw));
      _scanBusy = false;
      if (mounted) setState(() {});
    });
  }

  Widget _cameraStatusRow() {
    Widget content({required bool running}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Point camera at customer's QR ticket",
            textAlign: TextAlign.center,
            style: CheckOutUiTokens.hint(),
          ),
          if (running) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DashboardStyles.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CAMERA ACTIVE',
                  style: CheckOutUiTokens.body().copyWith(
                    color: DashboardStyles.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    final sc = _scanner;
    if (sc == null) return content(running: false);
    return ListenableBuilder(
      listenable: sc,
      builder: (context, _) => content(running: sc.value.isRunning),
    );
  }

  Widget _scannerColumn({required bool busy, required String? scanError}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        CheckoutQrScanViewport(
          size: _viewportSize,
          scannerReady: _scannerReady,
          controller: _scanner,
          onDetect: _onDetect,
        ),
        const SizedBox(height: 12),
        _cameraStatusRow(),
        if (scanError != null && scanError.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              scanError,
              textAlign: TextAlign.center,
              style: CheckOutUiTokens.error(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _manualPanel(
    BuildContext context,
    CheckOutState state,
    bool busy, {
    required bool pinLostFeeToBottom,
    bool keyboardOpen = false,
  }) {
    final auth = context.read<AuthBloc>().state;
    final lostFee = auth is AuthAuthenticated
        ? (auth.standardRates?.lostTicketFeePesos ?? 200)
        : 200;
    final peso = PesoCurrency.currency(decimalDigits: 2);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _manualMaxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment:
            pinLostFeeToBottom ? MainAxisAlignment.start : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ENTER TICKET / PLATE MANUALLY',
            style: CheckOutUiTokens.sectionTitle().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use if QR is unavailable or damaged',
            style: CheckOutUiTokens.hint(),
          ),
          const SizedBox(height: CheckInCompactTokens.blockGap),
          CheckInFormField(
            label: 'TICKET NUMBER',
            child: CheckInTextField(
              controller: _ticketCtrl,
              hint: 'TKT-2024-0087',
            ),
          ),
          const CheckoutFieldOrDivider(),
          CheckInFormField(
            label: 'PLATE NUMBER',
            child: CheckInTextField(controller: _plateCtrl, hint: 'ABC 1234'),
          ),
          if (busy) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ],
          const SizedBox(height: CheckInCompactTokens.blockGap),
          SizedBox(
            height: CheckInCompactTokens.footerButtonHeight,
            child: OutlinedButton(
              onPressed: busy ? null : _onCombinedSearch,
              style: OutlinedButton.styleFrom(
                backgroundColor: CheckOutUiTokens.hintFill,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: CheckOutUiTokens.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Search',
                style: CheckInCompactTokens.footerLabel().copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (state.scanError.isNotEmpty && !pinLostFeeToBottom) ...[
            const SizedBox(height: 8),
            Text(state.scanError, style: CheckOutUiTokens.error()),
          ],
          if (pinLostFeeToBottom && !keyboardOpen) const Spacer(),
          Text(
            'Lost ticket fee: ${peso.format(lostFee)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEC2231),
            ).copyWith(fontFamilyFallback: _pesoFallback),
          ),
        ],
      ),
    );
  }

  Widget _cancelOnlyFooter(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          width: 200,
          height: CheckInCompactTokens.footerButtonHeight,
          child: OutlinedButton(
            onPressed: () {
              context.read<CheckOutCubit>().reset();
              context.go('/dashboard');
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: CheckOutUiTokens.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: CheckInCompactTokens.footerLabel().copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _keyboardFocusLayout(
    BuildContext context,
    CheckOutState state,
    bool busy,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: _manualPanel(
        context,
        state,
        busy,
        pinLostFeeToBottom: false,
        keyboardOpen: true,
      ),
    );
  }

  Widget _stackedLayout(
    CheckOutState state,
    bool busy,
    String? scanError, {
    required bool keyboardOpen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!keyboardOpen) ...[
          Center(
            child: _scannerColumn(busy: busy, scanError: scanError),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CheckoutOrDivider.horizontal(),
          ),
        ],
        Center(
          child: _manualPanel(
            context,
            state,
            busy,
            pinLostFeeToBottom: false,
            keyboardOpen: keyboardOpen,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final keyboardOpen = isKeyboardVisible(context);
    final twoColumn =
        screenW >= _twoColumnMinWidth && !keyboardOpen;

    return CheckOutStepBody(
      scrollable: !twoColumn,
      footer: _cancelOnlyFooter(context),
      child: BlocBuilder<CheckOutCubit, CheckOutState>(
        buildWhen: (a, b) =>
            a.isLookupBusy != b.isLookupBusy || a.scanError != b.scanError,
        builder: (context, state) {
          final busy = state.isLookupBusy;
          final scanError = state.scanError;

          if (keyboardOpen) {
            return _keyboardFocusLayout(context, state, busy);
          }

          if (twoColumn) {
            return Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: _scannerColumn(
                            busy: busy,
                            scanError: scanError,
                          ),
                        ),
                      ),
                      const CheckoutOrDivider.vertical(),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _manualPanel(
                              context,
                              state,
                              busy,
                              pinLostFeeToBottom: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _stackedLayout(
            state,
            busy,
            scanError,
            keyboardOpen: false,
          );
        },
      ),
    );
  }
}

