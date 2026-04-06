import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide text field chrome: [AppTextFieldShadow] + single hairline border on
/// the control (shadow and border are not merged on one [BoxDecoration]).
///
/// **Use [LabeledAppTextField]** for label + standard gap + field.
/// (Figma baseline: auth login `30:401`.)
abstract final class AppTextFieldTokens {
  static const labelNavy = Color(0xFF0A1B39);
  static const accentOrange = Color(0xFFF68D00);
  static const hintGrey = Color(0xFF9DA4B0);
  static const borderGrey = Color(0xFFE7E8EB);

  /// Vertical gap between label and control.
  static const double labelToFieldSpacing = 4;

  /// Single-line fields: comfortable inner padding so rows without prefix icons
  /// match the **visual height** of login fields (icons inflate [InputDecorator]).
  static const EdgeInsets inputContentPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 14);

  /// Minimum height for one-line [AppTextField] / read-only row (Material ~48).
  static const double minInputHeight = 48;
}

/// Default label style for [LabeledAppTextField] (Poppins 14 w500, navy).
TextStyle appTextFieldLabelStyle() => GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: AppTextFieldTokens.labelNavy,
    );

/// Label + gap + `child` — shared spacing for forms (default gap 4px).
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
        Text(label, style: labelStyle ?? appTextFieldLabelStyle()),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

/// Non-editable value: [AppTextFieldShadow] + single hairline border (same
/// layering as [AppTextField], no focus ring).
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
    return AppTextFieldShadow(
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        alignment: alignment,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTextFieldTokens.borderGrey,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Subtle drop shadow behind the field (`0x0C000000`, blur 1, offset (0, 1)).
class AppTextFieldShadow extends StatelessWidget {
  const AppTextFieldShadow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
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

/// Grey border when idle, orange when focused.
InputDecoration appTextFieldDecoration({
  required String hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  BoxConstraints? constraints,
}) {
  const radius = 6.0;
  const sideGrey = BorderSide(
    color: AppTextFieldTokens.borderGrey,
    width: 1,
  );
  const sideOrange = BorderSide(
    color: AppTextFieldTokens.accentOrange,
    width: 1,
  );

  return InputDecoration(
    isDense: false,
    hintText: hint,
    hintStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppTextFieldTokens.hintGrey,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: AppTextFieldTokens.inputContentPadding,
    constraints: constraints ??
        BoxConstraints(minHeight: AppTextFieldTokens.minInputHeight),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideGrey,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideGrey,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: sideOrange,
    ),
  );
}

/// [TextField] wrapped in [AppTextFieldShadow] with [appTextFieldDecoration].
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minHeight = AppTextFieldTokens.minInputHeight,
    required this.hint,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final double minHeight;
  final String hint;
  final TextStyle? style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  static TextStyle defaultValueStyle() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppTextFieldTokens.labelNavy,
      );

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
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        style: widget.style ?? AppTextField.defaultValueStyle(),
        decoration: appTextFieldDecoration(
          hint: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          constraints: BoxConstraints(minHeight: widget.minHeight),
        ),
      ),
    );
  }
}
