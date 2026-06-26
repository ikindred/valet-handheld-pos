import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/check_in_validation.dart';
import '../state/check_in_cubit.dart';

/// Leaves check-in for the dashboard.
///
/// Completed check-ins only reset wizard state (ticket stays in Drift).
/// Cancelled flows delete any reserved draft first.
Future<void> exitCheckInToDashboard(BuildContext context) async {
  final cubit = context.read<CheckInCubit>();
  final submitted = CheckInValidation.isCheckInSubmitted(cubit.state);
  cubit.beginExitToDashboard();
  if (context.mounted) {
    context.go('/dashboard');
  }
  // Let the router leave /check-in before clearing wizard state. Resetting while
  // CheckInShell is still mounted races with its step guard and bounces to step-1.
  await SchedulerBinding.instance.endOfFrame;
  if (submitted) {
    cubit.resetWizardAfterCompletedCheckIn();
  } else {
    await cubit.abandonCheckInSession();
  }
  // Shell schedules step-guard callbacks every build; keep the exit flag set
  // through the next frame so those cannot redirect back into the wizard.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    cubit.endExitToDashboard();
  });
}
