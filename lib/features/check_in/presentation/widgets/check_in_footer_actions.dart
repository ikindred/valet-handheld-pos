import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import 'check_in_compact_tokens.dart';

/// Horizontal space after **Cancel** so it’s visually separated from Back / Done.
const double kCheckInFooterCancelGap = 24;

class CheckInFooterActions extends StatelessWidget {
  const CheckInFooterActions({
    super.key,
    required this.onCancel,
    this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.showBack = false,
    this.primaryBusy = false,
  });

  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool showBack;
  final bool primaryBusy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedFooterButton(label: 'Cancel', onPressed: onCancel),
        ),
        const SizedBox(width: kCheckInFooterCancelGap),
        if (showBack) ...[
          Expanded(
            child: _OutlinedFooterButton(label: 'Back', onPressed: onBack!),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: _PrimaryFooterButton(
            label: primaryLabel,
            onPressed: onPrimary,
            busy: primaryBusy,
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
  const _PrimaryFooterButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CheckInCompactTokens.footerButtonHeight,
      child: FilledButton(
        onPressed: busy || !enabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF68D00),
          disabledBackgroundColor: const Color(0xFFE8E8E8),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF9E9E9E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: CheckInCompactTokens.footerLabel().copyWith(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Footer for vehicle condition (step 3):
/// **Cancel** (gap) **Back | Customer Signature | Next: Review & Print**.
class CheckInVehicleConditionFooter extends StatelessWidget {
  const CheckInVehicleConditionFooter({
    super.key,
    required this.hasCustomerSignature,
    required this.onCancel,
    required this.onSignature,
    required this.onBack,
    required this.onNext,
  });

  /// When true, the Customer Signature control uses the same green treatment as dashboard **Parked**.
  final bool hasCustomerSignature;

  final VoidCallback onCancel;
  final VoidCallback onSignature;
  final VoidCallback onBack;
  final VoidCallback onNext;

  static const _gap = CheckInCompactTokens.bodyTypeGridGap;

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
          child: _CustomerSignatureFooterButton(
            hasSignature: hasCustomerSignature,
            onPressed: onSignature,
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: _PrimaryFooterButton(
            label: 'Next: Review & Print',
            enabled: hasCustomerSignature,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

/// Missing signature: pale red fill, full red outline, draw icon.
/// Captured: mint fill + green border (aligned with [DashboardTransactionRow] **Parked** pill).
class _CustomerSignatureFooterButton extends StatelessWidget {
  const _CustomerSignatureFooterButton({
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
        height: CheckInCompactTokens.footerButtonHeight,
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
      height: CheckInCompactTokens.footerButtonHeight,
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
              // Use Border.all, not only top/bottom: partial borders + borderRadius
              // leave gaps at corner joins in Flutter's border painter.
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
                      style: CheckInCompactTokens.footerLabel().copyWith(
                        fontWeight: FontWeight.w700,
                        color: _negativeRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.draw, color: _negativeRed, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
