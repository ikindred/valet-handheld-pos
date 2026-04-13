/// Maps `/check-out/step-N` → 0-based index for the 6-step checkout flow.
int checkOutStepIndexFromPath(String path) {
  if (path.contains('/check-out/add-issue')) {
    return 2;
  }
  final m = RegExp(r'/check-out/step-(\d+)').firstMatch(path);
  if (m == null) return 0;
  final n = int.tryParse(m.group(1)!) ?? 1;
  return (n - 1).clamp(0, 5);
}
