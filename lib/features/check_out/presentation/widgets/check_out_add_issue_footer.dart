import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../check_in/presentation/widgets/check_in_footer_actions.dart';

/// Footer for checkout **Add new Issue** (mirrors check-in condition footer layout).
class CheckOutAddIssueFooter extends StatelessWidget {
  const CheckOutAddIssueFooter({
    super.key,
    required this.hasCustomerSignature,
    required this.onCancel,
    required this.onBack,
    required this.onSignature,
    required this.onSave,
  });

  final bool hasCustomerSignature;
  final VoidCallback onCancel;
  final VoidCallback onBack;
  final VoidCallback onSignature;
  final VoidCallback onSave;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedFooterButton(label: 'Cancel', onPressed: onCancel),
        ),
        const SizedBox(width: kCheckInFooterCancelGap),
        Expanded(
          child: _OutlinedFooterButton(label: 'Back', onPressed: onBack),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: _CheckoutIssueSignatureFooterButton(
            hasSignature: hasCustomerSignature,
            onPressed: onSignature,
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: _PrimaryFooterButton(
            label: 'Save & return',
            onPressed: onSave,
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

class _CheckoutIssueSignatureFooterButton extends StatelessWidget {
  const _CheckoutIssueSignatureFooterButton({
    required this.hasSignature,
    required this.onPressed,
  });

  final bool hasSignature;
  final VoidCallback onPressed;

  static const _label = 'Customer Signature';
  static const _radius = 10.0;
  static const _negativeRed = Color(0xFFE53935);
  static const _negativeBg = Color(0xFFFFF5F5);

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(_radius);
    final shape = RoundedRectangleBorder(borderRadius: r);

    if (hasSignature) {
      return SizedBox(
        height: 54,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: shape,
          child: InkWell(
            onTap: onPressed,
            borderRadius: r,
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF7),
                borderRadius: r,
                border: Border.all(color: DashboardStyles.green),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DashboardStyles.statusParked(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      color: DashboardStyles.green,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onPressed,
          borderRadius: r,
          child: Ink(
            decoration: BoxDecoration(
              color: _negativeBg,
              borderRadius: r,
              border: Border.all(color: _negativeRed, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _negativeRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.draw, color: _negativeRed, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
