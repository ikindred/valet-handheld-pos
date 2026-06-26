import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves check-in for the dashboard.
///
/// Does not reset [CheckInCubit] here — clearing state while [CheckInShell] is
/// still mounted lets `forwardGuardPath` redirect back into the wizard.
/// A new session is prepared when the user taps Check in on the dashboard.
void exitCheckInToDashboard(BuildContext context) {
  context.go('/dashboard');
}
