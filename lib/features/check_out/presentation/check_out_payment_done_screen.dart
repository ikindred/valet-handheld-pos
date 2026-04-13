import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/formatting/peso_currency.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_step_body.dart';

/// Step 6 — Complete + print
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=43-43)).
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

  static String _dt(int unix) {
    if (unix <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${DateFormat('MMM d, y').format(dt)} · ${DateFormat('h:mm a').format(dt)}';
  }

  static String _customer(CheckoutReceiptSnapshot s) {
    final n = (s.customerName ?? '').trim();
    return n.isEmpty ? '—' : n;
  }

  static String _plate(CheckoutReceiptSnapshot s) {
    final p = s.plateNumber.trim();
    return p.isEmpty ? '—' : p;
  }

  static String _valet(CheckoutReceiptSnapshot s) {
    final v = (s.valetName ?? '').trim();
    return v.isEmpty ? '—' : v;
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
      builder: (context, state) {
        if (state.receiptTicket == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        final snap = state.receiptSnapshot ??
            CheckoutReceiptSnapshot.minimal(
              ticketNumber: state.receiptTicket!,
              totalPesos: state.receiptTotalPesos ?? 0,
              changePesos: state.receiptChangePesos ?? 0,
            );

        final peso2 = PesoCurrency.currency(decimalDigits: 2);
        final durationLabel =
            CheckoutReceiptSnapshot.durationLabelFromMinutes(snap.durationMinutes);
        final branch = (snap.branchLine ?? '').trim();
        final thankYou = branch.isEmpty
            ? 'THANK YOU FOR USING VALET MASTER'
            : 'THANK YOU FOR USING VALET MASTER · $branch';

        return CheckOutStepBody(
          footer: FilledButton(
            onPressed: () => _releaseDone(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              backgroundColor: _orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Release Vehicle & Done',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 960;
              final header = _vehicleReviewCompleteHeader();
              final success = _transactionCompleteCard();
              final printCard = _printBluetoothCard(
                onTap: () => _printStub(context),
              );
              final summary = _releaseSummaryCard(snap, peso2, durationLabel);
              final receipt = _receiptPreview(
                snap: snap,
                peso2: peso2,
                durationLabel: durationLabel,
                thankYou: thankYou,
              );

              if (wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              success,
                              const SizedBox(height: 16),
                              printCard,
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: summary),
                        const SizedBox(width: 20),
                        Expanded(flex: 6, child: receipt),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 20),
                  success,
                  const SizedBox(height: 16),
                  printCard,
                  const SizedBox(height: 20),
                  summary,
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

  Widget _vehicleReviewCompleteHeader() {
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
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 9),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _transactionCompleteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: _successSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: _green, size: 45),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Complete',
                  style: _poppins(20, FontWeight.w600, _green),
                ),
                Text(
                  'Vehicle may be released to customer',
                  style: _poppins(15, FontWeight.w500, _green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _printBluetoothCard({required VoidCallback onTap}) {
    return Material(
      color: _orange,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 45,
                width: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.27),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.bluetooth,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Via Bluetooth',
                      style: _poppins(18, FontWeight.w600, Colors.white),
                    ),
                    Text(
                      'Valet Master Printer · Connected',
                      style: _poppins(
                        12,
                        FontWeight.w500,
                        Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _releaseSummaryCard(
    CheckoutReceiptSnapshot snap,
    NumberFormat peso2,
    String durationLabel,
  ) {
    Widget row(String label, Widget right, {bool divider = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: _poppins(12, FontWeight.w500, _grey500)),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RELEASE SUMMARY',
            style: _poppins(15, FontWeight.w500, _navy),
          ),
          const SizedBox(height: 25),
          row(
            'Plate',
            Text(
              _plate(snap),
              style: _poppins(15, FontWeight.w600, _plateBlue),
            ),
          ),
          row(
            'Customer',
            Text(
              _customer(snap),
              style: _poppins(12, FontWeight.w500, _navy),
            ),
          ),
          row(
            'Duration',
            Text(
              durationLabel,
              style: _poppins(12, FontWeight.w500, _navy),
            ),
          ),
          row(
            'Amount Paid',
            Text(
              peso2.format(snap.totalPesos),
              style: _poppins(15, FontWeight.w600, _orange),
            ),
          ),
          row(
            'Cash Tendered',
            Text(
              peso2.format(snap.amountTendered),
              style: _poppins(12, FontWeight.w500, _navy),
            ),
          ),
          row(
            'Change Given',
            Text(
              peso2.format(snap.changePesos),
              style: _poppins(15, FontWeight.w600, _green),
            ),
            divider: false,
          ),
        ],
      ),
    );
  }

  Widget _receiptPreview({
    required CheckoutReceiptSnapshot snap,
    required NumberFormat peso2,
    required String durationLabel,
    required String thankYou,
  }) {
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

    final valet = _valet(snap);
    final flatLabel = 'First ${snap.flatBlockHours} hrs (flat)';
    final showSucceeding = snap.succeedingPesos > 0.009;
    final succeedingLabel = '+${snap.succeedingExtraMinutes} mins';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
          Text(
            'TICKET NUMBER',
            style: _poppins(12, FontWeight.w500, _grey500),
          ),
          const SizedBox(height: 4),
          Text(
            snap.ticketNumber,
            style: _poppins(20, FontWeight.w700, _orange),
          ),
          const SizedBox(height: 4),
          Text(
            _plate(snap),
            style: _poppins(15, FontWeight.w700, _plateBlue),
          ),
          if (snap.vehicleReceiptLine.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              snap.vehicleReceiptLine,
              style: _poppins(10, FontWeight.w400, Colors.black),
            ),
          ],
          const SizedBox(height: 16),
          smallRow('Time In', _dt(snap.timeInUnix)),
          smallRow('Time Out', _dt(snap.timeOutUnix)),
          smallRow('Duration', durationLabel),
          smallRow('Parking Slot', snap.slotLine),
          smallRow('Valet In', valet),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Valet Out', style: _poppins(10, FontWeight.w500, _grey500)),
                  Text(valet, style: _poppins(10, FontWeight.w500, _navy)),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.13)),
            ],
          ),
          const SizedBox(height: 14),
          feeRow(flatLabel, peso2.format(snap.flatPesos)),
          if (showSucceeding)
            feeRow(succeedingLabel, peso2.format(snap.succeedingPesos)),
          if (snap.overnightApplied && snap.overnightPesos > 0.009)
            feeRow('Overnight', peso2.format(snap.overnightPesos)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total', style: _poppins(10, FontWeight.w500, _grey500)),
              Text(
                peso2.format(snap.totalPesos),
                style: _poppins(20, FontWeight.w700, _orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: _successSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Change', style: _poppins(10, FontWeight.w500, _green)),
                Text(
                  peso2.format(snap.changePesos),
                  style: _poppins(10, FontWeight.w700, _green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  'MONDAY – SUNDAY · 10:00AM – 9:00PM',
                  textAlign: TextAlign.center,
                  style: _poppins(8, FontWeight.w500, _grey500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NOTE: THIS IS NOT AN OFFICIAL RECEIPT (OR)',
            textAlign: TextAlign.center,
            style: _poppins(8, FontWeight.w500, _grey500),
          ),
        ],
      ),
    );
  }
}
