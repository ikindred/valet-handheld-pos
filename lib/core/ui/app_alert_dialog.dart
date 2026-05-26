import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

enum AppAlertIcon { info, warning, error }

/// Branded alert with readable body text and a single primary action.
Future<void> showAppAlertDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  AppAlertIcon icon = AppAlertIcon.info,
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppAlertDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: icon,
    ),
  );
}

class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'OK',
    this.icon = AppAlertIcon.info,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final AppAlertIcon icon;

  static const _maxWidth = 400.0;

  Color _iconColor() {
    switch (icon) {
      case AppAlertIcon.info:
        return AppColors.accent;
      case AppAlertIcon.warning:
        return AppColors.warning;
      case AppAlertIcon.error:
        return AppColors.error;
    }
  }

  IconData _iconData() {
    switch (icon) {
      case AppAlertIcon.info:
        return LucideIcons.info;
      case AppAlertIcon.warning:
        return LucideIcons.alertTriangle;
      case AppAlertIcon.error:
        return LucideIcons.alertCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconData(), color: _iconColor(), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
