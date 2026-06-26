import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/check_in/presentation/widgets/check_in_compact_tokens.dart';
import 'branch_rates_slots_header_actions.dart';

/// Two-row header for check-in / check-out.
///
/// **Left:** step caption with dot stepper directly beneath.
/// **Right:** ticket · Rates · Online/Offline pill group.
class FlowPageHeaderBar extends StatelessWidget {
  const FlowPageHeaderBar({
    super.key,
    required this.caption,
    required this.stepIndex,
    required this.totalSteps,
    this.allStepsComplete = false,
    this.ticket,
  });

  final String caption;
  final int stepIndex;
  final int totalSteps;
  final bool allStepsComplete;
  final Widget? ticket;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tc.cardBg,
        border: Border(bottom: BorderSide(width: 1, color: tc.cardBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: CheckInCompactTokens.headerStepOf(context).copyWith(
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CheckInDotStepper(
                    currentIndex: stepIndex,
                    total: totalSteps,
                    allComplete: allStepsComplete,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BranchRatesSlotsHeaderActions(
              showSlots: false,
              leading: ticket,
            ),
          ],
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
    this.allComplete = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final int currentIndex;
  final int total;
  final bool allComplete;
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
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: allComplete
                  ? _done
                  : (i < currentIndex
                      ? _done
                      : (i == currentIndex ? _current : _todo)),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
