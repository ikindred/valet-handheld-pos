import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isDark = AppThemeColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [tc.scaffoldBg, const Color(0xFF131C2E)]
              : const [
                  Color(0xFFFFFAF0),
                  Color(0xFFF1F5FF),
                ],
        ),
      ),
      child: child,
    );
  }
}

