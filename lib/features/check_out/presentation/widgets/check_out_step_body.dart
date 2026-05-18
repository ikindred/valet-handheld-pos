import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/keyboard_aware_scroll.dart';
import '../../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../../check_in/presentation/widgets/check_in_footer_actions.dart';
import '../../state/check_out_cubit.dart';

/// Scrollable body + footer for checkout steps (mirrors [CheckInStepBody]).
class CheckOutStepBody extends StatelessWidget {
  const CheckOutStepBody({
    super.key,
    required this.child,
    this.primaryLabel,
    this.onPrimary,
    this.showBack = false,
    this.onBack,
    this.scrollable = true,
    this.fillViewportWhenShort = false,
    this.footer,
  }) : assert(
         footer != null || (primaryLabel != null && onPrimary != null),
         'Provide footer or both primaryLabel and onPrimary.',
       );

  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool showBack;
  final VoidCallback? onBack;
  final bool scrollable;

  /// When [scrollable] is true, centers short content vertically (step 1 scan only).
  /// Do not use on steps with [Expanded] / fixed-height [LayoutBuilder] children.
  final bool fillViewportWhenShort;
  final Widget? footer;

  void _cancel(BuildContext context) {
    context.read<CheckOutCubit>().reset();
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

    final keyboardOpen = isKeyboardVisible(context);
    final insetBottom =
        keyboardOpen ? View.of(context).viewInsets.bottom : 0.0;

    Widget body = child;
    if (scrollable) {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final scrollChild = fillViewportWhenShort &&
                  constraints.maxHeight.isFinite
              ? ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: child,
                )
              : child;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: insetBottom),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: scrollChild,
          );
        },
      );
    } else if (keyboardOpen) {
      body = Padding(
        padding: EdgeInsets.only(bottom: insetBottom),
        child: child,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        CheckInCompactTokens.screenPaddingH,
        CheckInCompactTokens.screenPaddingTop,
        CheckInCompactTokens.screenPaddingH,
        keyboardOpen ? 8 : CheckInCompactTokens.screenPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          const SizedBox(height: CheckInCompactTokens.footerGap),
          bottom,
        ],
      ),
    );
  }
}
