import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/formatting/peso_currency.dart';
import '../domain/checkout_preview_format.dart';
import '../models/checkout_preview_response.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';

/// Step 5 — Complete + print
class CheckOutPaymentDoneScreen extends StatelessWidget {
  const CheckOutPaymentDoneScreen({super.key});

  static const _grey500 = Color(0xFF6C7688);
  static const _navy = Color(0xFF0A1B39);
  static const _plateBlue = Color(0xFF0068D3);
  static const _green = Color(0xFF27AE60);
  static const _orange = Color(0xFFF68D00);
  static const _surfaceCard = Color(0xFFF8F9FB);
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

  void _printStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bluetooth print is not connected yet.'),
      ),
    );
  }

  void _releaseDone(BuildContext context) {
    context.read<CheckOutCubit>().reset();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) =>
          a.receiptTicket != b.receiptTicket ||
          a.preview != b.preview ||
          a.serverTotal != b.serverTotal ||
          a.amountTenderedInput != b.amountTenderedInput ||
          a.invoiceNumber != b.invoiceNumber ||
          a.branchName != b.branchName ||
          a.mallHours != b.mallHours,
      builder: (context, state) {
        if (state.receiptTicket == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final cubit = context.read<CheckOutCubit>();
        final preview = state.preview;
        final peso2 = PesoCurrency.currency(decimalDigits: 2);
        final total = state.serverTotal ?? preview?.ticket.totalAmount ?? 0;
        final tendered = cubit.parsedTendered() ?? total;
        final change = cubit.changeDue() ?? 0;
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
              final wide = c.maxWidth >= 960;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _transactionCompleteCard(),
                  const SizedBox(height: 16),
                  _releaseSummaryCard(
                    preview: preview,
                    peso2: peso2,
                    total: total,
                    tendered: tendered,
                    change: change,
                  ),
                  const SizedBox(height: 16),
                  _printBluetoothCard(onTap: () => _printStub(context)),
                ],
              );

              final receipt = _receiptPreview(
                localTicketId: state.receiptTicket!,
                preview: preview,
                peso2: peso2,
                total: total,
                change: change,
                thankYou: thankYou,
                mallHours: state.mallHours,
                driverOut: state.driverOut,
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
          const Icon(Icons.check_circle, color: _green, size: 32),
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

  Widget _printBluetoothCard({required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _orange,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.bluetooth,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Print Via Bluetooth',
                  style: CheckOutUiTokens.body().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
    required NumberFormat peso2,
    required double total,
    required double tendered,
    required double change,
  }) {
    final rs = preview?.releaseSummary;
    final plate = rs?.plate.trim().isNotEmpty == true ? rs!.plate : '—';
    final customer = rs?.customer.trim().isNotEmpty == true ? rs!.customer : '—';
    final duration = rs?.duration.trim().isNotEmpty == true ? rs!.duration : '—';

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
        color: _surfaceCard,
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
              style: CheckOutUiTokens.body().copyWith(
                color: _orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          row(
            'Cash Tendered',
            Text(peso2.format(tendered), style: CheckOutUiTokens.body()),
          ),
          row(
            'Change Given',
            Text(
              peso2.format(change),
              style: CheckOutUiTokens.body().copyWith(
                color: _green,
                fontWeight: FontWeight.w700,
              ),
            ),
            divider: false,
          ),
        ],
      ),
    );
  }

  Widget _receiptPreview({
    required String localTicketId,
    required CheckoutPreviewResponse? preview,
    required NumberFormat peso2,
    required double total,
    required double change,
    required String thankYou,
    required String mallHours,
    String? driverOut,
  }) {
    final pt = preview?.ticket;
    final plate = pt?.plate.isNotEmpty == true
        ? pt!.plate
        : preview?.releaseSummary.plate ?? '—';
    final vehicleLine = pt?.vehicleReceiptLine ?? '—';
    final timeIn = pt != null ? formatPreviewDateTime(pt.timeIn) : '—';
    final timeOut = pt?.timeOut != null ? formatPreviewDateTime(pt!.timeOut) : '—';
    final duration = pt?.duration.isNotEmpty == true
        ? pt!.duration
        : preview?.releaseSummary.duration ?? '—';
    final slot = pt != null && pt.parkingLocationLine.trim().isNotEmpty
        ? pt.parkingLocationLine.trim()
        : '—';
    final valetIn = pt?.valetIn?.trim().isNotEmpty == true ? pt!.valetIn! : '—';
    final valetOut = (driverOut?.trim().isNotEmpty == true)
        ? driverOut!.trim()
        : (pt?.valetOut?.trim().isNotEmpty == true ? pt!.valetOut! : '—');

    final flatLabel = pt?.flatRateLabel?.trim().isNotEmpty == true
        ? pt!.flatRateLabel!.trim()
        : 'Flat rate';
    final succeedingLabel = pt?.succeedingTimeLabel?.trim() ?? '';
    final flatAmount = pt?.flatRateAmount ?? total;
    final succeedingAmount = pt?.succeedingRateAmount ?? 0;

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
            Text(value, style: _poppins(10, FontWeight.w500, _navy)),
          ],
        ),
      );
    }

    return Container(
      padding: CheckOutUiTokens.cardPadding,
      decoration: BoxDecoration(
        color: _surfaceCard,
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
            localTicketId,
            style: CheckOutUiTokens.plate().copyWith(color: _orange),
          ),
          const SizedBox(height: 4),
          Text(
            plate,
            style: CheckOutUiTokens.body().copyWith(
              color: _plateBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (vehicleLine != '—') ...[
            const SizedBox(height: 2),
            Text(
              vehicleLine,
              style: _poppins(10, FontWeight.w400, Colors.black),
            ),
          ],
          const SizedBox(height: 16),
          smallRow('Time In', timeIn),
          smallRow('Time Out', timeOut),
          smallRow('Duration', duration),
          smallRow('Parking Slot', slot),
          smallRow('Valet In', valetIn),
          smallRow('Valet Out', valetOut),
          const SizedBox(height: 14),
          feeRow(flatLabel, peso2.format(flatAmount)),
          if (succeedingLabel.isNotEmpty && succeedingAmount > 0.009)
            feeRow(succeedingLabel, peso2.format(succeedingAmount)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: _poppins(10, FontWeight.w500, _grey500)),
              Text(
                peso2.format(total),
                style: _poppins(20, FontWeight.w700, _orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: _successSurface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Change', style: _poppins(10, FontWeight.w600, _green)),
                const SizedBox(width: 8),
                Text(
                  peso2.format(change),
                  style: _poppins(12, FontWeight.w700, _green),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            color: const Color(0xFFF2F3F5),
            child: Column(
              children: [
                Text(
                  thankYou,
                  textAlign: TextAlign.center,
                  style: _poppins(8, FontWeight.w500, _grey500),
                ),
                const SizedBox(height: 5),
                Text(
                  mallHours,
                  textAlign: TextAlign.center,
                  style: _poppins(8, FontWeight.w500, _grey500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
