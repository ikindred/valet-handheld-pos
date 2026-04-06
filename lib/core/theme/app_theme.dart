import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF3C3434);
  static const accent = Color(0xFFE8831A);
  static const primaryLight = Color(0xFF5A5050);
  static const accentLight = Color(0xFFF4A84A);
  static const surface = Color(0xFFF9F7F5);
  static const background = Color(0xFFF0EDEA);
  static const error = Color(0xFFD64045);
  static const success = Color(0xFF2E7D52);
  static const warning = Color(0xFFF0A500);
  /// Figma grey / grey-900 — primary body and labels on light surfaces.
  static const textPrimary = Color(0xFF0A1B39);
  /// Figma grey / grey-500 — section caps, helper text, muted labels.
  static const textSecondary = Color(0xFF6C7688);
  /// Muted line under page titles (e.g. date · branch).
  static const textSubtitleMuted = Color.fromRGBO(10, 27, 57, 0.6);
  static const divider = Color(0xFFE2DEDE);
  static const white = Color(0xFFFFFFFF);
}

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    dividerColor: AppColors.divider,
  );

  // Poppins omits U+20B1 (₱); fallbacks supply the peso glyph on Android/iOS.
  const pesoFallback = <String>['Noto Sans', 'Roboto'];
  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
  ).apply(
    fontFamilyFallback: pesoFallback,
  );

  return base.copyWith(
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      hintStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFF9DA4B0)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE7E8EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE7E8EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: textTheme.labelLarge,
      ),
    ),
  );
}

