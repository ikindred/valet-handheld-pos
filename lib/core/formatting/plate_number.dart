/// Normalizes a plate for storage and API lookup: trim and remove all whitespace.
String normalizePlateNumber(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s+'), '');
