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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: CheckInCompactTokens.footerButtonHeight,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFC0C0BF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Back',
                style: CheckInCompactTokens.footerLabel().copyWith(
                  color: AppColors.textPrimary,
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
                disabledBackgroundColor: const Color(0xFFE8E8E8),
                disabledForegroundColor: const Color(0xFF9E9E9E),
                foregroundColor: Colors.white,
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
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
