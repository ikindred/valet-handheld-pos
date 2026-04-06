import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../state/check_in_cubit.dart';

/// Top title bar for check-in — same container pattern as [CashPageHeader]
/// (`open_cash_screen`): fixed 96px, `#FAFAFA`, **bottom border only**.
/// **Left → right:** step caption + dot stepper, ticket pill, online pill.
class CheckInFlowHeader extends StatelessWidget {
  const CheckInFlowHeader({
    super.key,
    required this.stepIndex,
    this.totalSteps = 6,
  });

  /// 0-based (step-1 → 0).
  final int stepIndex;
  final int totalSteps;

  static const List<String> stepTitles = [
    'CUSTOMER AND VALET DETAILS',
    'VEHICLE DETAILS',
    'VEHICLE CONDITION',
    'SIGNATURE',
    'SIGNED',
    'REVIEW AND PRINT',
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
            const SizedBox(width: 16),
            BlocBuilder<CheckInCubit, CheckInState>(
              buildWhen: (a, b) => a.ticketNumber != b.ticketNumber,
              builder: (context, state) {
                return _TicketPill(ticketNumber: state.ticketNumber);
              },
            ),
            const SizedBox(width: 16),
            const DashboardOnlinePill(),
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
        ticketNumber.isEmpty ? '…' : ticketNumber,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF68D00),
        ),
      ),
    );
  }
}

/// Dots: completed → green, current → orange, upcoming → `#D9D9D9` (Figma).
class CheckInDotStepper extends StatelessWidget {
  const CheckInDotStepper({
    super.key,
    required this.currentIndex,
    required this.total,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final int currentIndex;
  final int total;
  final MainAxisAlignment mainAxisAlignment;

  static const Color _done = Color(0xFF27AE60);
  static const Color _current = Color(0xFFF68D00);
  static const Color _todo = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: i < currentIndex
                  ? _done
                  : (i == currentIndex ? _current : _todo),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
