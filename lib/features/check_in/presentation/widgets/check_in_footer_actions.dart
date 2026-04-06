import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class CheckInFooterActions extends StatelessWidget {
  const CheckInFooterActions({
    super.key,
    required this.onCancel,
    this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.showBack = false,
  });

  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedFooterButton(label: 'Cancel', onPressed: onCancel),
        ),
        if (showBack) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _OutlinedFooterButton(label: 'Back', onPressed: onBack!),
          ),
        ],
        const SizedBox(width: 16),
        Expanded(
          child: _PrimaryFooterButton(
            label: primaryLabel,
            onPressed: onPrimary,
          ),
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
      height: 54,
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
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
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
      height: 54,
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
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
