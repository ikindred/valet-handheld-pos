import 'dart:ui';

/// Maps normalized tap coordinates on the vehicle diagram bitmap to a zone label.
///
/// Full spec (tables, tuning): `docs/vehicle_condition_zones.md` at the repo root.
///
/// ## Coordinate system
///
/// [Rect.fromLTRB] uses **(left, top, right, bottom)** in normalized **\[0, 1\]** space:
///
/// | Edge | Axis | Meaning |
/// |------|------|---------|
/// | **left** / **right** | Longitudinal | **Front** ≈ **0**; **rear** ≈ **1**. |
/// | **top** / **bottom** | Lateral | **Left** side of car ≈ **0**; **right** side ≈ **1**. |
///
/// Tap coordinates `(nx, ny)` match **(longitudinal, lateral)** — same as
/// [lookupVehicleZoneLabel] arguments.
///
/// ## Lookup rule
///
/// [lookupVehicleZoneLabel] walks [_zones] **in order**. The **first** [Rect]
/// for which `rect.contains(Offset(nx, ny))` is **true** supplies the label.
/// Small, specific zones **must** come before large fallbacks.
///
/// **Right/bottom are exclusive** in [Rect.contains].
///
/// If no rectangle matches, callers typically show a fallback (e.g. raw
/// percentages) in the UI.
///
/// ## Zone list (evaluation order)
///
/// Bounds **(L, T, R, B)** = **(left, top, right, bottom)**.
///
/// | # | Label | (L, T, R, B) |
/// |---|-------|--------------|
/// | 1 | Headlight — front left | (0.00, 0.00, 0.10, 0.16) |
/// | 2 | Headlight — front right | (0.00, 0.84, 0.10, 1.00) |
/// | 3 | Rear light — left | (0.90, 0.00, 1.00, 0.16) |
/// | 4 | Rear light — right | (0.90, 0.84, 1.00, 1.00) |
/// | 5 | Front bumper | (0.00, 0.16, 0.10, 0.84) |
/// | 6 | Rear bumper | (0.90, 0.16, 1.00, 0.84) |
/// | 7 | Side mirror — left | (0.28, 0.00, 0.36, 0.07) |
/// | 8 | Side mirror — right | (0.28, 0.93, 0.36, 1.00) |
/// | 9 | Hood | (0.10, 0.20, 0.28, 0.80) |
/// | 10 | Windshield | (0.28, 0.18, 0.42, 0.82) |
/// | 11 | Sunroof | (0.42, 0.28, 0.60, 0.72) |
/// | 12 | Roof — front | (0.36, 0.26, 0.42, 0.74) |
/// | 13 | Roof — rear | (0.60, 0.26, 0.68, 0.74) |
/// | 14 | Rear window | (0.68, 0.18, 0.82, 0.82) |
/// | 15 | Trunk | (0.82, 0.22, 0.90, 0.78) |
/// | 16 | Front fender — left | (0.10, 0.00, 0.50, 0.22) |
/// | 17 | Rear fender — left | (0.50, 0.00, 0.90, 0.22) |
/// | 18 | Front fender — right | (0.10, 0.78, 0.50, 1.00) |
/// | 19 | Rear fender — right | (0.50, 0.78, 0.90, 1.00) |
/// | 20 | Door / body — left | (0.28, 0.22, 0.82, 0.34) |
/// | 21 | Door / body — right | (0.28, 0.66, 0.82, 0.78) |
/// | 22 | Body — center spine | (0.10, 0.40, 0.90, 0.60) |
///
/// ## Tuning
///
/// When the car asset is replaced, adjust [_zones] so labels match the artwork.
/// Keep evaluation order unless you intentionally change priority.
String? lookupVehicleZoneLabel(double nx, double ny) {
  final p = Offset(nx, ny);
  for (final z in _zones) {
    if (z.$1.contains(p)) return z.$2;
  }
  return null;
}

/// Ordered zone definitions; must stay in sync with the “Zone list” section
/// on [lookupVehicleZoneLabel].
final List<(Rect, String)> _zones = [
  (Rect.fromLTRB(0.0, 0.0, 0.10, 0.16), 'Headlight — front left'),
  (Rect.fromLTRB(0.0, 0.84, 0.10, 1.0), 'Headlight — front right'),
  (Rect.fromLTRB(0.90, 0.0, 1.0, 0.16), 'Rear light — left'),
  (Rect.fromLTRB(0.90, 0.84, 1.0, 1.0), 'Rear light — right'),
  (Rect.fromLTRB(0.0, 0.16, 0.10, 0.84), 'Front bumper'),
  (Rect.fromLTRB(0.90, 0.16, 1.0, 0.84), 'Rear bumper'),
  (Rect.fromLTRB(0.28, 0.0, 0.36, 0.07), 'Side mirror — left'),
  (Rect.fromLTRB(0.28, 0.93, 0.36, 1.0), 'Side mirror — right'),
  (Rect.fromLTRB(0.10, 0.20, 0.28, 0.80), 'Hood'),
  (Rect.fromLTRB(0.28, 0.18, 0.42, 0.82), 'Windshield'),
  (Rect.fromLTRB(0.42, 0.28, 0.60, 0.72), 'Sunroof'),
  (Rect.fromLTRB(0.36, 0.26, 0.42, 0.74), 'Roof — front'),
  (Rect.fromLTRB(0.60, 0.26, 0.68, 0.74), 'Roof — rear'),
  (Rect.fromLTRB(0.68, 0.18, 0.82, 0.82), 'Rear window'),
  (Rect.fromLTRB(0.82, 0.22, 0.90, 0.78), 'Trunk'),
  (Rect.fromLTRB(0.10, 0.0, 0.50, 0.22), 'Front fender — left'),
  (Rect.fromLTRB(0.50, 0.0, 0.90, 0.22), 'Rear fender — left'),
  (Rect.fromLTRB(0.10, 0.78, 0.50, 1.0), 'Front fender — right'),
  (Rect.fromLTRB(0.50, 0.78, 0.90, 1.0), 'Rear fender — right'),
  (Rect.fromLTRB(0.28, 0.22, 0.82, 0.34), 'Door / body — left'),
  (Rect.fromLTRB(0.28, 0.66, 0.82, 0.78), 'Door / body — right'),
  (Rect.fromLTRB(0.10, 0.40, 0.90, 0.60), 'Body — center spine'),
];
