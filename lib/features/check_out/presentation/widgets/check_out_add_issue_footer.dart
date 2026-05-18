import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../check_in/presentation/widgets/check_in_compact_tokens.dart';

/// Figma add-issue footer: **Back** | **Confirm**.
class CheckOutAddIssueFooter extends StatelessWidget {
  const CheckOutAddIssueFooter({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedFooterButton(label: 'Back', onPressed: onBack),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PrimaryFooterButton(label: 'Confirm', onPressed: onConfirm),
        ),
      ],
    );
  }
}

class _OutlinedFooterButton extends StatelessWidget {
  const _OutlinedFooterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CheckInCompactTokens.footerButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFFC0C0BF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: CheckInCompactTokens.footerLabel().copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PrimaryFooterButton extends StatelessWidget {
  const _PrimaryFooterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CheckInCompactTokens.footerButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF68D00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: CheckInCompactTokens.footerLabel().copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
