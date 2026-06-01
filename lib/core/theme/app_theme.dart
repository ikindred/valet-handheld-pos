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

// ── Adaptive color tokens ────────────────────────────────────────────────────

/// Theme extension that carries adaptive surface/text colors.
/// Read via [AppThemeColors.of].
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.cardBorder,
    required this.railBg,
    required this.railBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textSubtitleMuted,
    required this.divider,
    required this.inputFill,
    required this.hintFill,
    required this.checkboxFill,
    required this.chipBg,
    required this.plateBadgeBg,
    required this.accentSurface,
  });

  final Color scaffoldBg;
  final Color cardBg;
  final Color cardBorder;
  final Color railBg;
  final Color railBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textSubtitleMuted;
  final Color divider;
  final Color inputFill;
  /// Subtle fill for keypad rows, rate breakdown hints, checkbox rows.
  final Color hintFill;
  /// Selected checkbox / toggle row background.
  final Color checkboxFill;
  /// Status pills, outlined chips on dark surfaces.
  final Color chipBg;
  /// Plate number badge background.
  final Color plateBadgeBg;
  /// Ticket / warm accent surfaces (e.g. ticket id pill).
  final Color accentSurface;

  static const light = AppThemeColors(
    scaffoldBg: Color(0xFFF4F5F7),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0x21000000),
    railBg: Color(0xFFFAFAFA),
    railBorder: Color(0x21000000),
    textPrimary: Color(0xFF0A1B39),
    textSecondary: Color(0xFF6C7688),
    textSubtitleMuted: Color(0x990A1B39),
    divider: Color(0xFFE2DEDE),
    inputFill: Color(0xFFFFFFFF),
    hintFill: Color(0xFFF8F9FB),
    checkboxFill: Color(0xFFF8F9FB),
    chipBg: Color(0xFFFFFFFF),
    plateBadgeBg: Color(0xFFECF3FF),
    accentSurface: Color(0xFFFFF4E5),
  );

  static const dark = AppThemeColors(
    scaffoldBg: Color(0xFF0B1120),
    cardBg: Color(0xFF1A2332),
    cardBorder: Color(0xFF334155),
    railBg: Color(0xFF0F1629),
    railBorder: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textSubtitleMuted: Color(0xFF94A3B8),
    divider: Color(0xFF334155),
    inputFill: Color(0xFF1E293B),
    hintFill: Color(0xFF152238),
    checkboxFill: Color(0xFF243044),
    chipBg: Color(0xFF1E293B),
    plateBadgeBg: Color(0xFF1E3A5F),
    accentSurface: Color(0xFF2D2418),
  );

  /// Returns the extension from the current theme, falling back to [light].
  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>() ?? light;

  @override
  AppThemeColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? cardBorder,
    Color? railBg,
    Color? railBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textSubtitleMuted,
    Color? divider,
    Color? inputFill,
    Color? hintFill,
    Color? checkboxFill,
    Color? chipBg,
    Color? plateBadgeBg,
    Color? accentSurface,
  }) {
    return AppThemeColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      railBg: railBg ?? this.railBg,
      railBorder: railBorder ?? this.railBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textSubtitleMuted: textSubtitleMuted ?? this.textSubtitleMuted,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
      hintFill: hintFill ?? this.hintFill,
      checkboxFill: checkboxFill ?? this.checkboxFill,
      chipBg: chipBg ?? this.chipBg,
      plateBadgeBg: plateBadgeBg ?? this.plateBadgeBg,
      accentSurface: accentSurface ?? this.accentSurface,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      railBg: Color.lerp(railBg, other.railBg, t)!,
      railBorder: Color.lerp(railBorder, other.railBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textSubtitleMuted:
          Color.lerp(textSubtitleMuted, other.textSubtitleMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      hintFill: Color.lerp(hintFill, other.hintFill, t)!,
      checkboxFill: Color.lerp(checkboxFill, other.checkboxFill, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      plateBadgeBg: Color.lerp(plateBadgeBg, other.plateBadgeBg, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

// ── Light theme ──────────────────────────────────────────────────────────────

ThemeData appTheme() => _buildTheme(Brightness.light);

// ── Dark theme ───────────────────────────────────────────────────────────────

ThemeData appDarkTheme() => _buildTheme(Brightness.dark);

// ── Shared builder ───────────────────────────────────────────────────────────

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final adaptive = isDark ? AppThemeColors.dark : AppThemeColors.light;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFFE8831A) : AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: adaptive.cardBg,
      onSurface: adaptive.textPrimary,
      onSurfaceVariant: adaptive.textSecondary,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    scaffoldBackgroundColor: adaptive.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1A2338) : AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    dividerColor: adaptive.divider,
    extensions: [adaptive],
  );

  const pesoFallback = <String>['Noto Sans', 'Roboto'];
  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
    displayLarge:
        GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium:
        GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
  ).apply(fontFamilyFallback: pesoFallback);

  return base.copyWith(
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: adaptive.inputFill,
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: const Color(0xFF9DA4B0)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: adaptive.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: adaptive.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: adaptive.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: adaptive.textPrimary,
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: adaptive.textSecondary,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(adaptive.cardBg),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: adaptive.textPrimary),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: adaptive.cardBg,
      surfaceTintColor: Colors.transparent,
      textStyle: textTheme.bodyMedium?.copyWith(color: adaptive.textPrimary),
    ),
    listTileTheme: ListTileThemeData(
      textColor: adaptive.textPrimary,
      iconColor: adaptive.textSecondary,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return adaptive.cardBorder;
      }),
    ),
  );
}
