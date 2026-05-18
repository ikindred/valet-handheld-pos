import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';

/// Checkout layout/typography aligned with [CheckInCompactTokens].
abstract final class CheckOutUiTokens {
  static const double cardRadius = 10;
  static const double scanPreviewRadius = 10;
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets cardPaddingDense =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  static const Color hairline = Color(0x21000000);
  static const Color cardBorder = Color(0xFFC0C0BF);
  static const Color hintFill = Color(0xFFF8F9FB);
  static const Color plateBlue = Color(0xFF0068D3);
  static const Color plateBarBg = Color(0xFFA7D6FF);

  static TextStyle sectionTitle() => CheckInCompactTokens.pageHeading();

  static TextStyle fieldLabel() => CheckInCompactTokens.fieldLabel();

  static TextStyle body() => CheckInCompactTokens.fieldValue();

  /// Amounts with ₱ — Poppins lacks U+20B1; Noto Sans renders the sign.
  static TextStyle money({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return body().copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamilyFallback: const ['Noto Sans', 'Roboto'],
    );
  }

  static TextStyle hint() => CheckInCompactTokens.bodyHint();

  static TextStyle helper() => CheckInCompactTokens.helperText();

  static TextStyle plate() => CheckInCompactTokens.plateValue();

  static TextStyle timeAccent() => CheckInCompactTokens.dateTimeAccent();

  static TextStyle tabLabel({required bool selected}) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? DashboardStyles.orange : const Color(0xFFA09E9E),
      );

  static TextStyle error() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
      );

  static TextStyle timeDisplay({Color? color}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle amountHero({Color? color}) => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: color ?? const Color(0xFFF68D00),
      ).copyWith(fontFamilyFallback: const ['Noto Sans', 'Roboto']);

  static TextStyle pesoAccent(double size, Color color) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      ).copyWith(fontFamilyFallback: const ['Noto Sans', 'Roboto']);
}
