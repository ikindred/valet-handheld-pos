import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/formatting/peso_currency.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/printing/checkout_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/printer_connection_notifier.dart';
import '../domain/checkout_preview_format.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../models/checkout_preview_response.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';

/// Step 5 — Complete + print
class CheckOutPaymentDoneScreen extends StatefulWidget {
  const CheckOutPaymentDoneScreen({super.key});

  @override
  State<CheckOutPaymentDoneScreen> createState() =>
      _CheckOutPaymentDoneScreenState();
}

class _CheckOutPaymentDoneScreenState extends State<CheckOutPaymentDoneScreen> {
  bool _printing = false;

  static const _grey500 = Color(0xFF6C7688);
  static const _navy = Color(0xFF0A1B39);
  static const _plateBlue = Color(0xFF0068D3);
  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);
  static const _successSurface = Color(0xFFE2F9F1);
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

  Future<void> _printReceipt(BuildContext context, CheckOutState state) async {
    if (_printing) return;
    final snap = state.receiptSnapshot;
    if (snap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt data is not ready yet.')),
      );
      return;
    }

    setState(() => _printing = true);
    final data = CheckoutReceiptData.fromSnapshot(
      snap,
      mallHours: state.mallHours,
      branchDisplayName: state.branchName,
      isLostTicket: state.isLostTicket,
      lostTicketFee: state.lostTicketFeePesos,
    );
    await printCheckOutFromContext(context, data: data);
    if (mounted) setState(() => _printing = false);
  }

  void _releaseDone(BuildContext context) {
    // Navigate first — reset() before go() rebuilds step-5 and auto-redirects to
    // step-1, which races with dashboard and can hit duplicate GlobalKey on OR divider.
    context.go('/dashboard');
    context.read<CheckOutCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.receiptTicket != b.receiptTicket ||
          a.receiptSnapshot != b.receiptSnapshot ||
          a.preview != b.preview ||
          a.serverTotal != b.serverTotal ||
          a.isLostTicket != b.isLostTicket ||
          a.amountTenderedInput != b.amountTenderedInput ||
          a.invoiceNumber != b.invoiceNumber ||
          a.branchName != b.branchName ||
          a.mallHours != b.mallHours,
      builder: (context, state) {
        if (!state.isReceiptStep) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final path = GoRouterState.of(context).uri.path;
            if (path == '/check-out/step-5') return;
            context.go(
              state.needsScanStep ? '/check-out/step-1' : '/check-out/step-4',
            );
          });
          return const SizedBox.shrink();
        }

        final cubit = context.read<CheckOutCubit>();
        final preview = state.preview;
        final snap = state.receiptSnapshot;
        final peso2 = PesoCurrency.currency(decimalDigits: 2);
        final total = snap?.totalPesos ??
            state.receiptTotalPesos ??
            state.authoritativeTotal ??
            0;
        final tendered = snap?.amountTendered ?? cubit.parsedTendered() ?? total;
        final change =
            snap?.changePesos ?? state.receiptChangePesos ?? cubit.changeDue() ?? 0;
        final branch = (state.branchName ?? '').trim();
        final thankYou = branch.isEmpty
            ? 'THANK YOU FOR USING VALET MASTER'
            : 'THANK YOU FOR USING VALET MASTER · $branch';

        return CheckOutStepBody(
          footer: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _releaseDone(context),
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, CheckInCompactTokens.footerButtonHeight),
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Release Vehicle & Done',
                  style: CheckInCompactTokens.footerLabel().copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _transactionCompleteCard(),
                  const SizedBox(height: 16),
                  _releaseSummaryCard(
                    preview: preview,
                    snapshot: snap,
                    peso2: peso2,
                    total: total,
                    tendered: tendered,
                    change: change,
                  ),
                  const SizedBox(height: 16),
                  _printBluetoothCard(
                    context: context,
                    printing: _printing,
                    onTap: _printing ? null : () => _printReceipt(context, state),
                  ),
                ],
              );

              final receipt = _receiptPreview(
                snapshot: snap,
                preview: preview,
                peso2: peso2,
                isLostTicket: state.isLostTicket,
                lostTicketFee: state.lostTicketFeePesos,
                thankYou: thankYou,
                mallHours: state.mallHours,
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: receipt),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftColumn,
                  const SizedBox(height: 20),
                  receipt,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _transactionCompleteCard() {
    return Container(
      padding: CheckOutUiTokens.cardPaddingDense,
      decoration: BoxDecoration(
        color: _successSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Complete',
                  style: CheckOutUiTokens.timeDisplay(color: _green),
                ),
                Text(
                  'Vehicle may be released to customer',
                  style: CheckOutUiTokens.body().copyWith(color: _green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _printBluetoothCard({
    required BuildContext context,
    required bool printing,
    required VoidCallback? onTap,
  }) {
    final printerStatus = context.watch<PrinterConnectionNotifier>();
    final subtitle = printerStatus.statusSubtitle;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _orange.withValues(alpha: onTap == null ? 0.65 : 1),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.13)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: CheckOutUiTokens.cardPadding,
            child: Row(
              children: [
                if (printing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  )
                else
                  Icon(
                    LucideIcons.printer,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printing ? 'Printing…' : 'Print Via Bluetooth',
                        style: CheckOutUiTokens.body().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!printing) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: CheckOutUiTokens.helper().copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _releaseSummaryCard({
    required CheckoutPreviewResponse? preview,
    required CheckoutReceiptSnapshot? snapshot,
    required NumberFormat peso2,
    required double total,
    required double tendered,
    required double change,
  }) {
    final rs = preview?.releaseSummary;
    final plate = snapshot?.plateNumber.trim().isNotEmpty == true
        ? snapshot!.plateNumber
        : (rs?.plate.trim().isNotEmpty == true ? rs!.plate : '—');
    final customer = rs?.customer.trim().isNotEmpty == true ? rs!.customer : '—';
    final duration = snapshot?.durationLabel?.trim().isNotEmpty == true
        ? snapshot!.durationLabel!
        : (rs?.duration.trim().isNotEmpty == true ? rs!.duration : '—');

    Widget row(String label, Widget right, {bool divider = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: CheckOutUiTokens.fieldLabel()),
              right,
            ],
          ),
          const SizedBox(height: 8),
          if (divider)
            Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.13)),
        ],
      );
    }

    return Container(
      padding: CheckOutUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RELEASE SUMMARY', style: CheckOutUiTokens.sectionTitle()),
          const SizedBox(height: 10),
          row(
            'Plate',
            Text(
              plate,
              style: CheckOutUiTokens.body().copyWith(
                color: _plateBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          row(
            'Customer',
            Text(customer, style: CheckOutUiTokens.body()),
          ),
          row('Duration', Text(duration, style: CheckOutUiTokens.body())),
          row(
            'Amount Paid',
            Text(
              peso2.format(total),
              style: CheckOutUiTokens.money(
                fontWeight: FontWeight.w700,
                color: _orange,
              ),
            ),
          ),
          row(
            'Cash Tendered',
            Text(
              peso2.format(tendered),
              style: CheckOutUiTokens.money(),
            ),
          ),
          row(
            'Change Given',
            Text(
              peso2.format(change),
              style: CheckOutUiTokens.money(
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
            divider: false,
          ),
        ],
      ),
    );
  }

  Widget _dottedRule() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const gap = 3.0;
        final count =
            ((constraints.maxWidth) / (dashWidth + gap)).floor().clamp(1, 80);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++) ...[
              Container(
                width: dashWidth,
                height: 1,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              if (i < count - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }

  static String _formatSnapshotDateTime(int unixSeconds) {
    if (unixSeconds <= 0) return '—';
    return formatPreviewDateTime(
      PhilippineTime.fromUnixSeconds(unixSeconds).toIso8601String(),
    );
  }

  Widget _receiptPreview({
    required CheckoutReceiptSnapshot? snapshot,
    required CheckoutPreviewResponse? preview,
    required NumberFormat peso2,
    required bool isLostTicket,
    required double lostTicketFee,
    required String thankYou,
    required String mallHours,
  }) {
    final pt = preview?.ticket;
    final ticketNo = snapshot?.ticketNumber.trim().isNotEmpty == true
        ? snapshot!.ticketNumber
        : (pt?.ticketNumber ?? '—');
    final plate = snapshot?.plateNumber.trim().isNotEmpty == true
        ? snapshot!.plateNumber
        : (pt?.plate.isNotEmpty == true
            ? pt!.plate
            : preview?.releaseSummary.plate ?? '—');
    final vehicleLine = snapshot?.vehicleReceiptLine.trim().isNotEmpty == true
        ? snapshot!.vehicleReceiptLine
        : (pt?.vehicleReceiptLine ?? '—');
    final timeIn = snapshot != null && snapshot.timeInUnix > 0
        ? _formatSnapshotDateTime(snapshot.timeInUnix)
        : (pt != null ? formatPreviewDateTime(pt.timeIn) : '—');
    final timeOut = snapshot != null && snapshot.timeOutUnix > 0
        ? _formatSnapshotDateTime(snapshot.timeOutUnix)
        : '—';
    final duration = snapshot?.durationLabel?.trim().isNotEmpty == true
        ? snapshot!.durationLabel!
        : '—';
    final slot = snapshot?.slotLine.trim().isNotEmpty == true
        ? snapshot!.slotLine.trim()
        : (pt != null && pt.parkingLocationLine.trim().isNotEmpty
            ? pt.parkingLocationLine.trim()
            : '—');
    final valetIn = snapshot?.valetName?.trim().isNotEmpty == true
        ? snapshot!.valetName!
        : (pt?.valetIn?.trim().isNotEmpty == true ? pt!.valetIn! : '—');
    final valetOut = snapshot?.valetOutName?.trim().isNotEmpty == true
        ? snapshot!.valetOutName!
        : (pt?.valetOut?.trim().isNotEmpty == true ? pt!.valetOut! : '—');
    final valetInOut = valetOut.trim().isNotEmpty && valetOut != '—'
        ? valetOut
        : valetIn;

    final flatHours = snapshot?.flatBlockHours ?? 3;
    final flatLabel = snapshot?.flatRateLabel?.trim().isNotEmpty == true
        ? snapshot!.flatRateLabel!.trim()
        : 'Flat rate ($flatHours h)';
    final flatAmount = snapshot?.flatPesos ?? 0;
    final succeedingAmount = snapshot?.succeedingPesos ?? 0;
    final succeedingLabel = succeedingAmount > 0.009
        ? (snapshot?.succeedingTimeLabel?.trim().isNotEmpty == true
            ? snapshot!.succeedingTimeLabel!.trim()
            : 'Succeeding hours')
        : '';
    final overnightAmount =
        snapshot != null && snapshot.overnightApplied ? snapshot.overnightPesos : 0;
    final total = snapshot?.totalPesos ?? 0;
    final change = snapshot?.changePesos ?? 0;

    Widget smallRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: _poppins(10, FontWeight.w500, _grey500),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: _poppins(10, FontWeight.w500, _navy),
              ),
            ),
          ],
        ),
      );
    }

    Widget feeRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _poppins(10, FontWeight.w500, _grey500)),
            Text(
              value,
              style: CheckOutUiTokens.money(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _navy,
              ),
            ),
          ],
        ),
      );
    }

  return Container(
      padding: CheckOutUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TICKET NUMBER', style: CheckOutUiTokens.fieldLabel()),
          const SizedBox(height: 4),
          Text(
            ticketNo,
            style: CheckOutUiTokens.plate().copyWith(
              color: _orange,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plate,
            style: CheckOutUiTokens.body().copyWith(
              color: _plateBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (vehicleLine != '—') ...[
            const SizedBox(height: 4),
            Text(
              vehicleLine.toUpperCase(),
              style: _poppins(10, FontWeight.w500, _grey500),
            ),
          ],
          const SizedBox(height: 14),
          smallRow('Time In', timeIn),
          smallRow('Time Out', timeOut),
          smallRow('Duration', duration),
          smallRow('Parking Slot', slot),
          smallRow('Valet In/Out', valetInOut),
          const SizedBox(height: 4),
          _dottedRule(),
          const SizedBox(height: 12),
          if (flatAmount > 0.009) feeRow(flatLabel, peso2.format(flatAmount)),
          if (succeedingLabel.isNotEmpty && succeedingAmount > 0.009)
            feeRow(succeedingLabel, peso2.format(succeedingAmount)),
          if (overnightAmount > 0.009)
            feeRow('Overnight fee', peso2.format(overnightAmount)),
          if (isLostTicket && lostTicketFee > 0.009)
            feeRow('Lost ticket fee', peso2.format(lostTicketFee)),
          const SizedBox(height: 10),
          _dottedRule(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: _poppins(10, FontWeight.w500, _grey500)),
              Text(
                peso2.format(total),
                style: CheckOutUiTokens.money(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _successSurface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Change', style: _poppins(10, FontWeight.w600, _green)),
                Text(
                  peso2.format(change),
                  style: CheckOutUiTokens.money(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NOTE: THIS IS NOT AN OFFICIAL RECEIPT (OR)',
            textAlign: TextAlign.center,
            style: _poppins(8, FontWeight.w500, _grey500),
          ),
          const SizedBox(height: 10),
          Text(
            thankYou,
            textAlign: TextAlign.center,
            style: _poppins(8, FontWeight.w500, _grey500),
          ),
          if (mallHours.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              mallHours,
              textAlign: TextAlign.center,
              style: _poppins(8, FontWeight.w500, _grey500),
            ),
          ],
        ],
      ),
    );
  }
}
