import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../check_in/presentation/widgets/check_in_flow_header.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../state/check_out_cubit.dart';

/// Checkout title bar — same chrome as check-in: 96px, `#FAFAFA`, bottom border.
class CheckOutFlowHeader extends StatelessWidget {
  const CheckOutFlowHeader({
    super.key,
    required this.stepIndex,
    this.totalSteps = 6,
  });

  final int stepIndex;
  final int totalSteps;

  static const List<String> stepTitles = [
    'SCAN QR CODE',
    'VEHICLE REVIEW — INFO',
    'VEHICLE REVIEW — CONDITION',
    'PAYMENT — SUMMARY & COLLECT',
    'PAYMENT — COLLECT',
    'PAYMENT — COMPLETE',
  ];

  static const Color _headerSurface = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final safeStep = stepIndex.clamp(0, totalSteps - 1);
    final title = stepTitles[safeStep];
    final stepLabel = safeStep + 1;
    final hairline = Colors.black.withValues(alpha: 0.13);

    return SizedBox(
      height: 96,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _headerSurface,
          border: Border(bottom: BorderSide(width: 1, color: hairline)),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'STEP $stepLabel OF $totalSteps — $title',
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: const Color(0xFF6C7688),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckInDotStepper(
                    currentIndex: safeStep,
                    total: totalSteps,
                    mainAxisAlignment: MainAxisAlignment.start,
                  ),
                ],
              ),
            ),
            BlocBuilder<CheckOutCubit, CheckOutState>(
              buildWhen: (a, b) =>
                  a.ticket?.id != b.ticket?.id ||
                  a.receiptTicket != b.receiptTicket ||
                  a.receiptSnapshot != b.receiptSnapshot,
              builder: (context, state) {
                final ticket = state.ticket?.id ?? state.receiptTicket ?? '';
                if (ticket.isEmpty) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 16),
                    _TicketPill(ticketNumber: ticket),
                  ],
                );
              },
            ),
            const SizedBox(width: 16),
            const DashboardStatusPillLive(),
          ],
        ),
      ),
    );
  }
}

class _TicketPill extends StatelessWidget {
  const _TicketPill({required this.ticketNumber});

  final String ticketNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFF68D00)),
      ),
      child: Text(
        ticketNumber,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF68D00),
        ),
      ),
    );
  }
}
