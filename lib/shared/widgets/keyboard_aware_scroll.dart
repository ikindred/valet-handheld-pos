import 'package:flutter/material.dart';

/// True when the soft keyboard (or IME) is open.
///
/// With [Scaffold.resizeToAvoidBottomInset] + Android `adjustResize`, the scaffold
/// may consume insets so [MediaQuery.viewInsets] is zero while the viewport still
/// shrinks — also consult [View.viewInsets].
bool isKeyboardVisible(BuildContext context) {
  if (MediaQuery.viewInsetsOf(context).bottom > 0) return true;
  final view = View.maybeOf(context);
  return view != null && view.viewInsets.bottom > 0;
}

/// Wraps [child] in a [SingleChildScrollView] when the keyboard is open so forms
/// do not overflow. No-op when the keyboard is hidden.
class KeyboardAwareScroll extends StatelessWidget {
  const KeyboardAwareScroll({
    super.key,
    required this.child,
    this.padding,
    this.alwaysScroll = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool alwaysScroll;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = insets.bottom > 0;
    if (!alwaysScroll && !keyboardOpen) return child;

    return SingleChildScrollView(
      padding: (padding ?? EdgeInsets.zero).add(
        EdgeInsets.only(bottom: keyboardOpen ? insets.bottom : 0),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }
}
