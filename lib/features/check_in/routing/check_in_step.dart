/// Parses `/check-in/step-N` or `/check-in/print` → 0-based index for the 6-step flow.
int checkInStepIndexFromPath(String path) {
  if (path.endsWith('/check-in/print')) return 5;
  final m = RegExp(r'/check-in/step-(\d+)').firstMatch(path);
  if (m == null) return 0;
  final n = int.tryParse(m.group(1)!) ?? 1;
  if (n <= 1) return 0;
  if (n == 2) return 1;
  if (n == 3) return 2;
  if (n == 4) return 3;
  if (n == 5) return 4;
  // step-6+ (legacy bookmarks) → print step for header highlight
  return 5;
}
