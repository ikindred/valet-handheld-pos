/// Parses `/check-in/step-N` → 0-based index for the 4-step flow (signature is
/// on vehicle condition; review/print is [step-5], legacy [step-6] redirects).
int checkInStepIndexFromPath(String path) {
  final m = RegExp(r'/check-in/step-(\d+)').firstMatch(path);
  if (m == null) return 0;
  final n = int.tryParse(m.group(1)!) ?? 1;
  if (n <= 1) return 0;
  if (n == 2) return 1;
  if (n == 3 || n == 4) return 2;
  return 3;
}
