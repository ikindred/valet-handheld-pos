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
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _onlineGreen,
      );

  /// "OPEN CASH" — compact tablet layout
  static TextStyle pageTitle() => GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Date · branch
  static TextStyle pageSubtitle() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: const Color(0x990A1B39),
        height: 1.2,
      );

  /// SHIFT INFORMATION, OPENING BALANCE
  static TextStyle sectionCaps() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  /// Field label
  static TextStyle fieldLabel() => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textSecondary,
      );

  /// Field value in read-only box
  static TextStyle fieldValue() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  /// NOTES (OPTIONAL)
  static TextStyle notesSectionLabel() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  /// Notes hint
  static TextStyle notesHint() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: const Color(0x7F0A1B39),
      );

  /// Notes typed text
  static TextStyle notesInput() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// Total card caps / footer
  static TextStyle totalCardLabel() => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Total card amount
  static TextStyle totalCardAmount() => _withPesoFallback(
        GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _orange,
        ),
      );

  /// Opening balance inline box
  static TextStyle openingAmountInline() => _withPesoFallback(
        GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _orange,
        ),
      );

  /// SHIFT SUMMARY title
  static TextStyle shiftSummaryTitle() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Shift summary row (label + value). Values may include peso (U+20B1).
  static TextStyle shiftSummaryRow({required bool isLabel}) {
    final base = GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: isLabel ? AppColors.textSecondary : AppColors.textPrimary,
    );
    return isLabel ? base : _withPesoFallback(base);
  }

  /// Primary CTA (orange button)
  static TextStyle filledActionLabel() => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  /// Numpad digit
  static TextStyle keypadDigit({required Color color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
