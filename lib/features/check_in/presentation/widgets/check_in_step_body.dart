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
    this.primaryLabel,
    this.onPrimary,
    this.showBack = false,
    this.onBack,
    this.scrollable = true,
    this.footer,
  }) : assert(
         footer != null || (primaryLabel != null && onPrimary != null),
         'Provide footer or both primaryLabel and onPrimary.',
       );

  final Widget child;

  /// When [footer] is null, these drive [CheckInFooterActions].
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool showBack;
  final VoidCallback? onBack;

  /// When false, [child] is placed in an [Expanded] (bounded height) — use for
  /// layouts that need vertical flex (e.g. vehicle diagram + side panel).
  final bool scrollable;

  /// Replaces the default [CheckInFooterActions] when non-null (e.g. vehicle condition four-button row).
  final Widget? footer;

  void _cancel(BuildContext context) {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        footer ??
        CheckInFooterActions(
          onCancel: () => _cancel(context),
          showBack: showBack,
          onBack: onBack,
          primaryLabel: primaryLabel!,
          onPrimary: onPrimary!,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
          const SizedBox(height: 20),
          bottom,
        ],
      ),
    );
  }
}
