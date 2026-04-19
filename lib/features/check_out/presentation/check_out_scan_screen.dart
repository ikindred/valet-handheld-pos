import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/platform/orientation_lock.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_bloc.dart';
import '../../check_in/presentation/widgets/check_in_form_fields.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';

/// Step 1 — Scan QR or manual lookup
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=32-1807)).
class CheckOutScanScreen extends StatefulWidget {
  const CheckOutScanScreen({super.key});

  @override
  State<CheckOutScanScreen> createState() => _CheckOutScanScreenState();
}

class _CheckOutScanScreenState extends State<CheckOutScanScreen> {
  late final TextEditingController _ticketCtrl;
  late final TextEditingController _plateCtrl;
  MobileScannerController? _scanner;
  var _scannerReady = false;
  var _scanBusy = false;

  static const _hairline = Color.fromRGBO(0, 0, 0, 0.13);
  static const _cardBorder = Color(0xFFC0C0BF);
  static const _hintFill = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _ticketCtrl = TextEditingController();
    _plateCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scanner = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
      setState(() => _scannerReady = true);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _scanner == null) return;
        await _scanner!.start();
        if (!mounted) return;
        await lockLandscape();
      });
    });
  }

  @override
  void dispose() {
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

  static const List<String> _pesoGlyphFallback = ['Noto Sans', 'Roboto'];

  TextStyle _poppins(double size, FontWeight w, Color color, {double? height}) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      height: height,
      color: color,
    ).copyWith(fontFamilyFallback: _pesoGlyphFallback);
  }

  Widget _verticalOrDivider() {
    return LayoutBuilder(
      builder: (context, cons) {
        final h = cons.maxHeight.isFinite
            ? (cons.maxHeight * 0.45).clamp(100.0, 220.0)
            : 140.0;
        return SizedBox(
          width: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 1, height: h, color: _hairline),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR',
                  style: _poppins(15, FontWeight.w500, DashboardStyles.grey500),
                ),
              ),
              Container(width: 1, height: h, color: _hairline),
            ],
          ),
        );
      },
    );
  }

  Widget _horizontalOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: _hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: _poppins(15, FontWeight.w500, DashboardStyles.grey500),
          ),
        ),
        Expanded(child: Divider(height: 1, thickness: 1, color: _hairline)),
      ],
    );
  }

  Widget _cameraHeaderRow() {
    if (_scanner == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              "Point camera at customer's QR ticket",
              style: _poppins(15, FontWeight.w500, DashboardStyles.grey500),
            ),
          ),
        ],
      );
    }
    return ListenableBuilder(
      listenable: _scanner!,
      builder: (context, _) {
        final running = _scanner!.value.isRunning;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "Point camera at customer's QR ticket",
                style: _poppins(15, FontWeight.w500, DashboardStyles.grey500),
              ),
            ),
            if (running) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CAMERA ACTIVE',
                    style: _poppins(
                      15,
                      FontWeight.w500,
                      DashboardStyles.orange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DashboardStyles.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _scannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SCAN QR ON TICKET',
            style: _poppins(15, FontWeight.w500, DashboardStyles.grey500),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.04),
                child: _scannerReady && _scanner != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scanner!,
                            onDetect: _onDetect,
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Figma: subtle horizontal accent under preview
          Center(
            child: Container(
              height: 3,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    DashboardStyles.orange.withValues(alpha: 0.15),
                    DashboardStyles.orange,
                    DashboardStyles.orange.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualPanel(
    BuildContext context,
    CheckOutState state,
    bool busy, {
    required bool pinLostFeeToBottom,
  }) {
    final auth = context.read<AuthBloc>().state;
    final lostFee = auth is AuthAuthenticated
        ? (auth.standardRates?.lostTicketFeePesos ?? 200)
        : 200;
    final peso = PesoCurrency.currency(decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ENTER TICKET / PLATE MANUALLY',
          style: _poppins(20, FontWeight.w500, Colors.black),
        ),
        const SizedBox(height: 6),
        Text(
          'Use if QR is unavailable or damaged',
          style: _poppins(15, FontWeight.w400, DashboardStyles.grey500),
        ),
        const SizedBox(height: 20),
        CheckInFormField(
          label: 'TICKET NUMBER',
          child: CheckInTextField(
            controller: _ticketCtrl,
            hint: 'TKT-2024-0087',
          ),
        ),
        const SizedBox(height: 16),
        CheckInFormField(
          label: 'PLATE NUMBER',
          child: CheckInTextField(controller: _plateCtrl, hint: 'ABC 1234'),
        ),
        if (busy) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: busy ? null : _onCombinedSearch,
            style: OutlinedButton.styleFrom(
              backgroundColor: _hintFill,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: _cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Search',
              style: _poppins(15, FontWeight.w500, AppColors.textPrimary),
            ),
          ),
        ),
        if (state.scanError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            state.scanError,
            style: _poppins(13, FontWeight.w500, AppColors.error),
          ),
        ],
        if (pinLostFeeToBottom) const Spacer() else const SizedBox(height: 28),
        Text(
          'Lost ticket fee: ${peso.format(lostFee)}',
          style: _poppins(20, FontWeight.w500, const Color(0xFFEC2231)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wide layout uses a Row + [Spacer] in the manual column; that requires a
    // bounded height. [CheckOutStepBody] defaults to a [SingleChildScrollView],
    // which gives the child unbounded height and triggers "infinite height"
    // assertions. When wide, disable scrolling so [Expanded] in the shell
    // provides a finite max height.
    return LayoutBuilder(
      builder: (context, outer) {
        final wide = outer.maxWidth >= 900;
        return CheckOutStepBody(
          scrollable: !wide,
          primaryLabel: 'Next: Vehicle review',
          onPrimary: () {
            final s = context.read<CheckOutCubit>().state;
            if (s.ticket != null) {
              context.go('/check-out/step-2');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan or look up a ticket first.'),
                ),
              );
            }
          },
          child: LayoutBuilder(
            builder: (context, c) {
              return BlocBuilder<CheckOutCubit, CheckOutState>(
                buildWhen: (a, b) =>
                    a.isLookupBusy != b.isLookupBusy ||
                    a.scanError != b.scanError,
                builder: (context, state) {
                  final wideInner = c.maxWidth >= 900;
                  final busy = state.isLookupBusy;

                  final scannerCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (busy) ...[
                        const Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _cameraHeaderRow(),
                      const SizedBox(height: 12),
                      _scannerCard(),
                      if (state.scanError.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.scanError,
                          style: _poppins(
                            13,
                            FontWeight.w500,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  );

                  final manual = _manualPanel(
                    context,
                    state,
                    busy,
                    pinLostFeeToBottom: wideInner,
                  );

                  if (wideInner) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 12, child: scannerCol),
                        _verticalOrDivider(),
                        Expanded(flex: 11, child: manual),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      scannerCol,
                      const SizedBox(height: 20),
                      _horizontalOrDivider(),
                      const SizedBox(height: 20),
                      manual,
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
