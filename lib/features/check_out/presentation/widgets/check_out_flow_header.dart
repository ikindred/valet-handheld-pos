import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../../check_in/presentation/widgets/check_in_flow_header.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../state/check_out_cubit.dart';

/// Checkout title bar — compact chrome matching [CheckInFlowHeader].
class CheckOutFlowHeader extends StatelessWidget {
  const CheckOutFlowHeader({
    super.key,
    required this.stepIndex,
    this.totalSteps = 5,
  });

  final int stepIndex;
  final int totalSteps;

  static const List<String> stepTitles = [
    'SCAN QR CODE',
    'VEHICLE REVIEW — INFO',
    'VEHICLE REVIEW — CONDITION',
    'PAYMENT — SUMMARY & COLLECT',
    'PAYMENT — COMPLETE',
  ];

  static const Color _headerSurface = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final safeStep = stepIndex.clamp(0, totalSteps - 1);
    final title = switch (safeStep) {
      1 || 2 => 'VEHICLE REVIEW',
      3 => 'PAYMENT',
      _ => stepTitles[safeStep],
    };
    final stepLabel = safeStep + 1;
    final hairline = Colors.black.withValues(alpha: 0.13);

    return SizedBox(
      height: CheckInCompactTokens.headerHeight,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'STEP $stepLabel OF $totalSteps — $title',
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CheckInCompactTokens.headerStep(),
                  ),
                  const SizedBox(height: 8),
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
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _TicketPill(ticketNumber: ticket),
                );
              },
            ),
            const SizedBox(width: 8),
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

  static const Color _orange = Color(0xFFE87722);
  static const Color _bg = Color(0xFFFFF7EC);

  @override
  Widget build(BuildContext context) {
    final display = ticketNumber.trim().isEmpty ? '…' : ticketNumber.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _orange),
      ),
      child: Text(
        display,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: _orange,
        ),
      ),
    );
  }
}
