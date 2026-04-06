import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_text_field.dart';

/// [LabeledAppTextField] + check-in value weight (semibold) on [CheckInTextField].
class CheckInFormField extends StatelessWidget {
  const CheckInFormField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LabeledAppTextField(label: label, child: child);
  }
}

class CheckInTextField extends StatelessWidget {
  const CheckInTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.hint,
    this.valueStyle,
    this.minHeight = AppTextFieldTokens.minInputHeight,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? hint;
  final TextStyle? valueStyle;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      minHeight: minHeight,
      hint: hint ?? '',
      style:
          valueStyle ??
          GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class CheckInSectionTitle extends StatelessWidget {
  const CheckInSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
