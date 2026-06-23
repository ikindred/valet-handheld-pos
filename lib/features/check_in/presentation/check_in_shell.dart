import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../domain/check_in_validation.dart';
import '../routing/check_in_step.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_flow_header.dart';

class CheckInShell extends StatefulWidget {
  const CheckInShell({super.key, required this.child});

  final Widget child;

  @override
  State<CheckInShell> createState() => _CheckInShellState();
}

class _CheckInShellState extends State<CheckInShell> {
  bool _awaitingDraft = false;

  @override
  void initState() {
    super.initState();
    _awaitingDraft = _ticketNumberEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDraftReservation());
  }

  @override
  void activate() {
    super.activate();
    if (_ticketNumberEmpty) {
      setState(() => _awaitingDraft = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _runDraftReservation());
    }
  }

  bool get _ticketNumberEmpty =>
      context.read<CheckInCubit>().state.ticketNumber.trim().isEmpty;

  Future<void> _runDraftReservation() async {
    if (!mounted) return;
    final cubit = context.read<CheckInCubit>();
    if (cubit.state.ticketNumber.trim().isNotEmpty) {
      if (mounted) setState(() => _awaitingDraft = false);
      return;
    }
    final ok = await cubit.ensureDraftTicketReserved();
    if (!mounted) return;
    if (!ok && cubit.state.ticketNumber.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await cubit.ensureDraftTicketReserved();
    }
    if (mounted) setState(() => _awaitingDraft = false);
    if (mounted) {
      _applyStepGuard(GoRouterState.of(context).uri.path);
    }
  }

  void _applyStepGuard(String path) {
    if (!mounted) return;
    final redirect = CheckInValidation.forwardGuardPath(
      path,
      context.read<CheckInCubit>().state,
    );
    if (redirect == null || redirect == path) return;
    context.go(redirect);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final stepIndex = checkInStepIndexFromPath(path);

    final scaffoldBg = AppThemeColors.of(context).scaffoldBg;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyStepGuard(path);
    });

    if (_awaitingDraft) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardLeftRail(),
            Expanded(
              child: SafeArea(
                left: false,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocListener<CheckInCubit, CheckInState>(
      listenWhen: (prev, next) =>
          prev.customerFullName != next.customerFullName ||
          prev.contactNumber != next.contactNumber ||
          prev.plateNumber != next.plateNumber ||
          prev.vehicleBrand != next.vehicleBrand ||
          prev.vehicleColor != next.vehicleColor ||
          prev.vehicleVrNo != next.vehicleVrNo ||
          prev.parkingLevel != next.parkingLevel ||
          prev.parkingSlot != next.parkingSlot ||
          prev.parkingSlotId != next.parkingSlotId ||
          prev.signaturePng != next.signaturePng ||
          prev.serverTicketId != next.serverTicketId ||
          prev.qrCode != next.qrCode,
      listener: (context, _) {
        _applyStepGuard(GoRouterState.of(context).uri.path);
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardLeftRail(),
            Expanded(
              child: SafeArea(
                left: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocBuilder<CheckInCubit, CheckInState>(
                      buildWhen: (a, b) =>
                          stepIndex == 5 && a.receiptParts != b.receiptParts,
                      builder: (context, state) {
                        return CheckInFlowHeader(
                          stepIndex: stepIndex,
                          totalSteps: 6,
                          allStepsComplete:
                              stepIndex == 5 && state.allPartsPrinted,
                        );
                      },
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
