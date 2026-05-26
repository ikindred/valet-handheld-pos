/// Normalizes text for ESC/POS printers that only accept limited charsets.
String sanitizeEscPosText(String input) {
  var s = input;
  const replacements = <String, String>{
    '\u20B1': 'P', // Philippine peso — not in printer charset
    '\u2014': '-', // em dash
    '\u2013': '-', // en dash
    '\u2212': '-', // minus
    '\u00B7': ' ', // middle dot
    '\u2022': '*', // bullet
    '\u2018': "'",
    '\u2019': "'",
    '\u201C': '"',
    '\u201D': '"',
    '\u2026': '...',
  };
  for (final e in replacements.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s.replaceAllMapped(
    RegExp(r'[^\x09\x0A\x0D\x20-\x7E]'),
    (_) => '?',
  );
}
