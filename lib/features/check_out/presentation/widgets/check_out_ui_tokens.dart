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

  static Color cardBorderOf(BuildContext ctx) =>
      AppThemeColors.of(ctx).cardBorder;

  static Color hintFillOf(BuildContext ctx) => AppThemeColors.of(ctx).hintFill;

  static Color cardBgOf(BuildContext ctx) => AppThemeColors.of(ctx).cardBg;

  static Color hairlineOf(BuildContext ctx) => AppThemeColors.of(ctx).cardBorder;

  static Color plateBarBgOf(BuildContext ctx) {
    final tc = AppThemeColors.of(ctx);
    return AppThemeColors.isDark(ctx) ? tc.plateBadgeBg : plateBarBg;
  }

  static Color chipFillOf(BuildContext ctx) {
    final tc = AppThemeColors.of(ctx);
    return AppThemeColors.isDark(ctx) ? tc.accentSurface : const Color(0xFFFFF7EC);
  }

  static Color issueCardBgOf(BuildContext ctx) {
    final tc = AppThemeColors.of(ctx);
    return AppThemeColors.isDark(ctx) ? tc.chipBg : const Color(0xFFF4F5F7);
  }

  static Color checkoutIssueBgOf(BuildContext ctx) =>
      AppThemeColors.isDark(ctx)
          ? const Color(0xFF3D1F24)
          : const Color(0xFFFFECEC);

  static Color signedChipBgOf(BuildContext ctx) =>
      AppThemeColors.isDark(ctx)
          ? const Color(0xFF14532D)
          : const Color(0xFFF4FBF7);

  static ButtonStyle footerOutlinedButton(BuildContext ctx) {
    final tc = AppThemeColors.of(ctx);
    return OutlinedButton.styleFrom(
      backgroundColor: tc.cardBg,
      foregroundColor: tc.textPrimary,
      side: BorderSide(color: tc.cardBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  static ButtonStyle searchOutlinedButton(BuildContext ctx) {
    final tc = AppThemeColors.of(ctx);
    return OutlinedButton.styleFrom(
      backgroundColor: tc.hintFill,
      foregroundColor: tc.textPrimary,
      side: BorderSide(color: tc.cardBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  static TextStyle sectionTitle() => CheckInCompactTokens.pageHeading();

  static TextStyle sectionTitleOf(BuildContext ctx) =>
      sectionTitle().copyWith(color: AppThemeColors.of(ctx).textPrimary);

  static TextStyle fieldLabelOf(BuildContext ctx) =>
      fieldLabel().copyWith(color: AppThemeColors.of(ctx).textSecondary);

  static TextStyle bodyOf(BuildContext ctx) =>
      body().copyWith(color: AppThemeColors.of(ctx).textPrimary);

  static TextStyle hintOf(BuildContext ctx) =>
      hint().copyWith(color: AppThemeColors.of(ctx).textSecondary);

  static TextStyle helperOf(BuildContext ctx) =>
      helper().copyWith(color: AppThemeColors.of(ctx).textSecondary);

  static TextStyle timeDisplayOf(BuildContext ctx, {Color? color}) =>
      timeDisplay(color: color ?? AppThemeColors.of(ctx).textPrimary);

  static TextStyle fieldLabel() => CheckInCompactTokens.fieldLabel();

  static TextStyle body() => CheckInCompactTokens.fieldValue();

  /// Amounts with ₱ — Poppins omits U+20B1; bundled Noto Sans renders the sign.
  static TextStyle money({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final b = body();
    return TextStyle(
      fontFamily: 'Noto Sans',
      fontSize: fontSize ?? b.fontSize,
      fontWeight: fontWeight ?? b.fontWeight,
      height: b.height,
      color: color ?? b.color,
    );
  }

  static TextStyle moneyOf(
    BuildContext ctx, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) =>
      money(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppThemeColors.of(ctx).textPrimary,
      );

  static Color lostTicketTileBgOf(BuildContext ctx) =>
      AppThemeColors.isDark(ctx)
          ? const Color(0xFF3D1F24)
          : const Color(0xFFFFECEC);

  static Color changeDueBgOf(BuildContext ctx) =>
      AppThemeColors.isDark(ctx)
          ? const Color(0xFF14532D)
          : const Color(0xFFE2F9F1);

  static TextStyle hint() => CheckInCompactTokens.bodyHint();

  static TextStyle helper() => CheckInCompactTokens.helperText();

  static TextStyle plate() => CheckInCompactTokens.plateValue();

  static TextStyle timeAccent() => CheckInCompactTokens.dateTimeAccent();

  static TextStyle tabLabel({required bool selected}) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? DashboardStyles.orange : const Color(0xFFA09E9E),
      );

  static TextStyle tabLabelOf(BuildContext ctx, {required bool selected}) {
    final tc = AppThemeColors.of(ctx);
    return tabLabel(selected: selected).copyWith(
      color: selected ? DashboardStyles.orange : tc.textSecondary,
    );
  }

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
      ).copyWith(fontFamilyFallback: const ['Noto Sans', 'Roboto']);

  static TextStyle amountHero({Color? color}) => money(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? const Color(0xFFF68D00),
      );

  static TextStyle pesoAccent(double size, Color color) => money(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
