import 'package:intl/intl.dart';

/// Philippine peso (U+20B1). Use this symbol in strings so sources stay ASCII-safe.
/// Poppins has no ₱ glyph — use `fontFamilyFallback: ['Noto Sans', …]` on those
/// [TextStyle]s; **Noto Sans must be declared in `pubspec.yaml`** so offline/web
/// builds can resolve the fallback.
abstract final class PesoCurrency {
  static const String symbol = '\u20B1';

  /// `₱ ` style for amount fields (trailing space after sign).
  static String get symbolWithTrailingSpace => '$symbol ';

  static NumberFormat currency({required int decimalDigits, bool spaceAfter = false}) {
    final sym = spaceAfter ? symbolWithTrailingSpace : symbol;
    return NumberFormat.currency(symbol: sym, decimalDigits: decimalDigits);
  }
}
