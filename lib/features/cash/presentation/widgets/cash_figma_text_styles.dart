import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Typography from Figma Open Cash (Poppins + Inter).
abstract final class CashFigmaStyles {
  static const Color _orange = Color(0xFFF68D00);
  static const Color _onlineGreen = Color(0xFF27AE60);

  /// Poppins has no U+20B1 (₱); merge so currency strings render the sign.
  static const List<String> _pesoGlyphFallback = ['Noto Sans', 'Roboto'];

  static TextStyle _withPesoFallback(TextStyle base) =>
      base.copyWith(fontFamilyFallback: _pesoGlyphFallback);

  static TextStyle onlinePill() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _onlineGreen,
      );

  /// "OPEN CASH" — Poppins 20 w500
  static TextStyle pageTitle() => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Date · branch — Poppins 15 w400, #0A1B39 @ 60% (Inter not bundled offline).
  static TextStyle pageSubtitle() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: const Color(0x990A1B39),
        height: 1.25,
      );

  /// SHIFT INFORMATION, OPENING BALANCE — Poppins 15 w500 grey-500
  static TextStyle sectionCaps() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Field label — Poppins 14 w500
  static TextStyle fieldLabel() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Field value in white box — Poppins 14 w600
  static TextStyle fieldValue() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// NOTES (OPTIONAL) — Poppins 15 w500 grey-500
  static TextStyle notesSectionLabel() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Notes hint — Poppins 14 w400
  static TextStyle notesHint() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: const Color(0x7F0A1B39),
      );

  /// Notes typed text
  static TextStyle notesInput() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Total card caps / footer — Poppins 12 w500
  static TextStyle totalCardLabel() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Total card amount — Poppins 45 w700
  static TextStyle totalCardAmount() => _withPesoFallback(
        GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: _orange,
        ),
      );

  /// Opening balance inline box — Poppins 30 w700
  static TextStyle openingAmountInline() => _withPesoFallback(
        GoogleFonts.poppins(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: _orange,
        ),
      );

  /// SHIFT SUMMARY title — Poppins 15 w500
  static TextStyle shiftSummaryTitle() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Shift summary row — Poppins 12 w500 (label + value). Values may include peso (U+20B1).
  static TextStyle shiftSummaryRow({required bool isLabel}) {
    final base = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isLabel ? AppColors.textSecondary : AppColors.textPrimary,
    );
    return isLabel ? base : _withPesoFallback(base);
  }

  /// Primary CTA — Poppins 15 w500 (use on orange button; color from theme)
  static TextStyle filledActionLabel() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  /// Numpad digit — Poppins 15 w500
  static TextStyle keypadDigit({required Color color}) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
