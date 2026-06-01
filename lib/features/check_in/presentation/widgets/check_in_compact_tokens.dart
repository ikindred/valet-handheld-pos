import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Compact spacing and typography aligned with login / open cash tablet layout.
abstract final class CheckInCompactTokens {
  static const double screenPaddingH = 16;
  static const double screenPaddingTop = 12;
  static const double screenPaddingBottom = 16;

  static const double sectionGap = 8;
  static const double fieldGap = 10;
  static const double blockGap = 12;

  static const double inputMinHeight = 40;
  static const double footerButtonHeight = 44;
  static const double footerGap = 12;

  static const double headerHeight = 72;
  static const double valetCardHeight = 96;
  static const double plateMinHeight = 52;
  static const double bodyTypeCardHeight = 80;
  static const double bodyTypeGridGap = 8;
  static const double valuablesRowMinHeight = 40;
  static const double damageTypeButtonHeight = 56;
  static const double columnDividerWidth = 24;

  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  static TextStyle sectionTitle() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textSecondary,
      );

  static TextStyle fieldLabel() => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textSecondary,
      );

  static TextStyle fieldLabelOf(BuildContext context) => fieldLabel()
      .copyWith(color: AppThemeColors.of(context).textSecondary);

  static TextStyle fieldValue() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle inlineLabel() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle inlineLabelOf(BuildContext context) => inlineLabel()
      .copyWith(color: AppThemeColors.of(context).textPrimary);

  static TextStyle dateTimeAccent() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: const Color(0xFFF68D00),
      );

  static TextStyle headerStep() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: const Color(0xFF6C7688),
      );

  static TextStyle footerLabel() => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );

  static TextStyle pageHeading() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle bodyHint() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  static TextStyle helperText() => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  static TextStyle plateValue() => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: const Color(0xFFF68D00),
        height: 1.15,
      );

  static TextStyle plateHint() => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: const Color(0x66F68D00),
        height: 1.15,
      );

  static TextStyle sectionTitleOf(BuildContext context) => sectionTitle()
      .copyWith(color: AppThemeColors.of(context).textSecondary);

  static TextStyle pageHeadingOf(BuildContext context) => pageHeading()
      .copyWith(color: AppThemeColors.of(context).textPrimary);

  static TextStyle fieldValueOf(BuildContext context) => fieldValue()
      .copyWith(color: AppThemeColors.of(context).textPrimary);

  static TextStyle headerStepOf(BuildContext context) => headerStep()
      .copyWith(color: AppThemeColors.of(context).textSecondary);

  static TextStyle bodyHintOf(BuildContext context) => bodyHint()
      .copyWith(color: AppThemeColors.of(context).textSecondary);
}
