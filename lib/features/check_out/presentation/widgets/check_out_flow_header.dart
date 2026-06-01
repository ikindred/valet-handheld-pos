import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
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
    'CHECKOUT SUMMARY',
  ];

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final safeStep = stepIndex.clamp(0, totalSteps - 1);
    final title = switch (safeStep) {
      1 || 2 => 'VEHICLE REVIEW',
      3 => 'PAYMENT',
      4 => 'CHECKOUT SUMMARY',
      _ => stepTitles[safeStep],
    };
    final stepLabel = safeStep + 1;
    final headerCaption = safeStep == 4
        ? title
        : 'STEP $stepLabel OF $totalSteps — $title';

    return SizedBox(
      height: CheckInCompactTokens.headerHeight,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: tc.cardBg,
          border: Border(bottom: BorderSide(width: 1, color: tc.cardBorder)),
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
                    headerCaption,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CheckInCompactTokens.headerStepOf(context),
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
  static const Color _bgLight = Color(0xFFFFF7EC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppThemeColors.of(context).inputFill : _bgLight;
    final display = ticketNumber.trim().isEmpty ? '…' : ticketNumber.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
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
