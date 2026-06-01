import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../check_in/presentation/widgets/check_in_compact_tokens.dart';

/// Figma vehicle-review footer: **Back** | primary (no Cancel).
class CheckoutVehicleReviewFooter extends StatelessWidget {
  const CheckoutVehicleReviewFooter({
    super.key,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryBusy = false,
  });

  final VoidCallback onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryBusy;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final primaryEnabled = onPrimary != null && !primaryBusy;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: CheckInCompactTokens.footerButtonHeight,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                backgroundColor: tc.cardBg,
                foregroundColor: tc.textPrimary,
                side: BorderSide(color: tc.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Back',
                style: CheckInCompactTokens.footerLabel().copyWith(
                  color: tc.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: CheckInCompactTokens.footerButtonHeight,
            child: FilledButton(
              onPressed: primaryBusy ? null : onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF68D00),
                disabledBackgroundColor: tc.hintFill,
                disabledForegroundColor: tc.textSecondary,
                foregroundColor: Colors.white,
                elevation: primaryEnabled ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: primaryBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      primaryLabel,
                      style: CheckInCompactTokens.footerLabel().copyWith(
                        color: primaryEnabled ? Colors.white : tc.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
