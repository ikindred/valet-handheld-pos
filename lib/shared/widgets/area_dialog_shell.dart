import 'package:flutter/material.dart';

/// Shared white card shell for branch area dialogs.
class AreaDialogShell extends StatelessWidget {
  const AreaDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.maxHeight = 520,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          child: SizedBox(
            height: maxHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
