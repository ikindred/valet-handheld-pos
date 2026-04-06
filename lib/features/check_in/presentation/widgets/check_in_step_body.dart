import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../state/check_in_cubit.dart';
import 'check_in_footer_actions.dart';

/// Scrollable body + standard footer for check-in steps 2–6.
class CheckInStepBody extends StatelessWidget {
  const CheckInStepBody({
    super.key,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.showBack = false,
    this.onBack,
  });

  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool showBack;
  final VoidCallback? onBack;

  void _cancel(BuildContext context) {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 20),
          CheckInFooterActions(
            onCancel: () => _cancel(context),
            showBack: showBack,
            onBack: onBack,
            primaryLabel: primaryLabel,
            onPrimary: onPrimary,
          ),
        ],
      ),
    );
  }
}
