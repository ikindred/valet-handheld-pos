import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/flow_page_header_bar.dart';
import '../../../../shared/widgets/header_ticket_pill.dart';
import '../../state/check_in_cubit.dart';

/// Top title bar for check-in — compact header, `#FAFAFA`, **bottom border only**.
/// **Left:** step caption + dot stepper. **Right:** ticket · Rates · Online.
class CheckInFlowHeader extends StatelessWidget {
  const CheckInFlowHeader({
    super.key,
    required this.stepIndex,
    this.totalSteps = 6,
    this.allStepsComplete = false,
  });

  /// 0-based (step-1 → 0).
  final int stepIndex;
  final int totalSteps;

  /// When true (e.g. all receipts printed on step 6), every dot shows completed.
  final bool allStepsComplete;

  static const List<String> stepTitles = [
    'CUSTOMER AND VALET DETAILS',
    'VEHICLE DETAILS',
    'PERSONAL BELONGINGS',
    'VEHICLE CONDITION',
    'REVIEW',
    'PRINT TICKET',
  ];

  @override
  Widget build(BuildContext context) {
    final safeStep = stepIndex.clamp(0, totalSteps - 1);
    final title = stepTitles[safeStep];
    final stepLabel = safeStep + 1;

    return FlowPageHeaderBar(
      caption: 'STEP $stepLabel OF $totalSteps — $title',
      stepIndex: safeStep,
      totalSteps: totalSteps,
      allStepsComplete: allStepsComplete,
      ticket: BlocBuilder<CheckInCubit, CheckInState>(
        buildWhen: (a, b) =>
            a.ticketNumber != b.ticketNumber ||
            a.serverTicketId != b.serverTicketId,
        builder: (context, state) {
          final synced = state.serverTicketId?.trim().isNotEmpty == true;
          return HeaderTicketPillLive(
            ticketNumber: state.ticketNumber,
            unsynced: !synced,
          );
        },
      ),
    );
  }
}
