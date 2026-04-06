/// Parses `/check-in/step-N` → 0-based index. Defaults to `0` if missing.
int checkInStepIndexFromPath(String path) {
  final m = RegExp(r'/check-in/step-(\d+)').firstMatch(path);
  if (m == null) return 0;
  final n = int.tryParse(m.group(1)!) ?? 1;
  return (n - 1).clamp(0, 5);
}
