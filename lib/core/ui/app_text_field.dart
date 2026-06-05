import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// App-wide text field chrome: [AppTextFieldShadow] + single hairline border on
/// the control (shadow and border are not merged on one [BoxDecoration]).
///
/// **Use [LabeledAppTextField]** for label + standard gap + field.
abstract final class AppTextFieldTokens {
  static const accentOrange = Color(0xFFF68D00);

  /// Vertical gap between label and control.
  static const double labelToFieldSpacing = 4;

  static const EdgeInsets inputContentPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 14);

  static const double minInputHeight = 48;
}

TextStyle appTextFieldLabelStyle(BuildContext context) {
  final c = AppThemeColors.of(context);
  return GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: c.textSecondary,
  );
}

class LabeledAppTextField extends StatelessWidget {
  const LabeledAppTextField({
    super.key,
    required this.label,
    required this.child,
    this.labelStyle,
    this.gap = AppTextFieldTokens.labelToFieldSpacing,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle ?? appTextFieldLabelStyle(context)),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

class AppReadOnlyField extends StatelessWidget {
  const AppReadOnlyField({
    super.key,
    required this.child,
    this.minHeight = AppTextFieldTokens.minInputHeight,
    this.padding = AppTextFieldTokens.inputContentPadding,
    this.alignment = Alignment.centerLeft,
  });

  final Widget child;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return AppTextFieldShadow(
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.cardBorder, width: 1),
        ),
        child: child,
      ),
    );
  }
}

class AppTextFieldShadow extends StatelessWidget {
  const AppTextFieldShadow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: child,
    );
  }
}

InputDecoration appTextFieldDecoration(
  BuildContext context, {
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  BoxConstraints? constraints,
}) {
  final c = AppThemeColors.of(context);
  const radius = 6.0;
  final sideIdle = BorderSide(color: c.cardBorder, width: 1);
  const sideOrange = BorderSide(
    color: AppTextFieldTokens.accentOrange,
    width: 1.2,
  );

  return InputDecoration(
    isDense: false,
    hintText: hint,
    hintStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: c.textSubtitleMuted,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: c.inputFill,
    contentPadding: AppTextFieldTokens.inputContentPadding,
    constraints: constraints ??
        BoxConstraints(minHeight: AppTextFieldTokens.minInputHeight),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideIdle,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideIdle,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideOrange,
    ),
  );
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.minHeight = AppTextFieldTokens.minInputHeight,
    required this.hint,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int maxLines;
  final double minHeight;
  final String hint;
  final TextStyle? style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  static TextStyle defaultValueStyle(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: c.textPrimary,
    );
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  var _ownsFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocus = true;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocus) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextFieldShadow(
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        autofocus: widget.autofocus,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: widget.style ?? AppTextField.defaultValueStyle(context),
        decoration: appTextFieldDecoration(
          context,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          constraints: BoxConstraints(minHeight: widget.minHeight),
        ),
      ),
    );
  }
}
