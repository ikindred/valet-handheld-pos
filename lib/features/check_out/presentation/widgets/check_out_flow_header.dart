import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/flow_page_header_bar.dart';
import '../../../../shared/widgets/header_ticket_pill.dart';
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

    return FlowPageHeaderBar(
      caption: headerCaption,
      stepIndex: safeStep,
      totalSteps: totalSteps,
      ticket: BlocBuilder<CheckOutCubit, CheckOutState>(
        buildWhen: (a, b) =>
            a.ticket?.id != b.ticket?.id ||
            a.ticket?.syncStatus != b.ticket?.syncStatus ||
            a.receiptTicket != b.receiptTicket ||
            a.receiptSnapshot != b.receiptSnapshot,
        builder: (context, state) {
          final ticket = state.ticket?.id ?? state.receiptTicket ?? '';
          if (ticket.isEmpty) return const SizedBox.shrink();
          final unsynced =
              state.ticket != null && state.ticket!.syncStatus != 'synced';
          return HeaderTicketPillLive(
            ticketNumber: ticket,
            unsynced: unsynced,
          );
        },
      ),
    );
  }
}
