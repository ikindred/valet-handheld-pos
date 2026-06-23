import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/app_text_field.dart';
import 'check_in_compact_tokens.dart';

/// [LabeledAppTextField] + check-in value weight (semibold) on [CheckInTextField].
class CheckInFormField extends StatelessWidget {
  const CheckInFormField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LabeledAppTextField(
      label: label,
      labelStyle: CheckInCompactTokens.fieldLabelOf(context),
      gap: 3,
      child: child,
    );
  }
}

class CheckInTextField extends StatelessWidget {
  const CheckInTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.hint,
    this.valueStyle,
    this.minHeight = CheckInCompactTokens.inputMinHeight,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int maxLines;
  final String? hint;
  final TextStyle? valueStyle;
  final double minHeight;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLines: maxLines,
      minHeight: minHeight,
      hint: hint ?? '',
      style: valueStyle ?? CheckInCompactTokens.fieldValueOf(context),
    );
  }
}

class CheckInSectionTitle extends StatelessWidget {
  const CheckInSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: CheckInCompactTokens.sectionTitle());
  }
}
