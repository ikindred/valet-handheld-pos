import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/rate_fetch_service.dart';
import '../../../../data/services/rate_service.dart';
import '../../../../shared/widgets/branch_rates_dialog.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../state/check_in_cubit.dart';
import 'check_in_compact_tokens.dart';

/// Top title bar for check-in — compact header, `#FAFAFA`, **bottom border only**.
/// **Left:** step caption + dot stepper. **Right:** [ticket] [Rates] [status] — one row, equal gaps.
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
    'PERSONAL BELONGINGS',
    'VEHICLE CONDITION',
    'REVIEW',
    'PRINT TICKET',
  ];

  static const Color _headerSurface = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final safeStep = stepIndex.clamp(0, totalSteps - 1);
    final title = stepTitles[safeStep];
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
            const SizedBox(width: 8),
            BlocBuilder<CheckInCubit, CheckInState>(
              buildWhen: (a, b) => a.ticketNumber != b.ticketNumber,
              builder: (context, state) {
                return _TicketPill(ticketNumber: state.ticketNumber);
              },
            ),
            const SizedBox(width: 8),
            RatesOutlinePill(
              onPressed: () async {
                final auth = context.read<AuthRepository>();
                final site = await auth.branchAndAreaFromDb();
                final name = branchRatesSubtitle(site);
                if (!context.mounted) return;
                await showBranchRatesDialog(
                  context,
                  authRepository: auth,
                  rateFetchService: context.read<RateFetchService>(),
                  rateService: context.read<RateService>(),
                  branchName: name,
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

/// Capsule badge — same visual language as [DashboardStatusPill] (e.g. Online).
class _TicketPill extends StatelessWidget {
  const _TicketPill({required this.ticketNumber});

  final String ticketNumber;

  /// SPiD orange; background matches warm cream used with status pills.
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
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
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
