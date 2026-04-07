# Vehicle condition diagram — zone mapping

This document describes how taps on the **top-down car image** on **Check In → Vehicle Condition (step 3)** are turned into human-readable **zone labels** for each logged damage entry.

## Source of truth

Implementation lives in:

- [`lib/features/check_in/domain/vehicle_damage_zones.dart`](../lib/features/check_in/domain/vehicle_damage_zones.dart) — `lookupVehicleZoneLabel(nx, ny)` and the ordered `_zones` list.

The diagram widget normalizes tap coordinates to **\[0, 1\]** × **\[0, 1\]** relative to the bitmap; the same numbers are stored on each [`VehicleDamageEntry`](../lib/features/check_in/domain/vehicle_damage.dart) and used to draw markers.

**Bitmap asset:** `assets/images/vehicle_condition_car_top.png` (see [`kVehicleConditionImageSize`](../lib/features/check_in/presentation/widgets/vehicle_condition_diagram.dart) — width × height in pixels must stay consistent with the rects below when the art changes).

---

## Coordinate system

`Rect.fromLTRB(left, top, right, bottom)` uses normalized **\[0, 1\]** values:

| Edge                 | Axis         | Meaning                                                   |
| -------------------- | ------------ | --------------------------------------------------------- |
| **left** / **right** | Longitudinal | **Front** of the car ≈ **0**; **rear** ≈ **1**.           |
| **top** / **bottom** | Lateral      | **Left** side of the car ≈ **0**; **right** side ≈ **1**. |

Tap coordinates `(nx, ny)` are **(longitudinal, lateral)** — the same as the arguments to `lookupVehicleZoneLabel`.

In Flutter, `Rect.contains` treats **right** and **bottom** as **exclusive**, so adjacent zones can abut without overlap.

---

## How lookup works

1. The tap point is tested against the `_zones` list **in order**.
2. **First match wins.** Small, specific regions are listed before large fallbacks.
3. If no rectangle contains the point, the UI typically shows **percentage coordinates** instead of a zone name.

---

## Zone table (evaluation order)

Update this table when you change `_zones` in code.

| Order | Label                   | Normalized bounds `(L, T, R, B)` |
| ----: | ----------------------- | -------------------------------: |
|     1 | Headlight — front left  |         (0.00, 0.00, 0.10, 0.16) |
|     2 | Headlight — front right |         (0.00, 0.84, 0.10, 1.00) |
|     3 | Rear light — left       |         (0.90, 0.00, 1.00, 0.16) |
|     4 | Rear light — right      |         (0.90, 0.84, 1.00, 1.00) |
|     5 | Front bumper            |         (0.00, 0.16, 0.10, 0.84) |
|     6 | Rear bumper             |         (0.90, 0.16, 1.00, 0.84) |
|     7 | Side mirror — left      |         (0.28, 0.00, 0.36, 0.07) |
|     8 | Side mirror — right     |         (0.28, 0.93, 0.36, 1.00) |
|     9 | Hood                    |         (0.10, 0.20, 0.28, 0.80) |
|    10 | Windshield              |         (0.28, 0.18, 0.42, 0.82) |
|    11 | Sunroof                 |         (0.42, 0.28, 0.60, 0.72) |
|    12 | Roof — front            |         (0.36, 0.26, 0.42, 0.74) |
|    13 | Roof — rear             |         (0.60, 0.26, 0.68, 0.74) |
|    14 | Rear window             |         (0.68, 0.18, 0.82, 0.82) |
|    15 | Trunk                   |         (0.82, 0.22, 0.90, 0.78) |
|    16 | Front fender — left     |         (0.10, 0.00, 0.50, 0.22) |
|    17 | Rear fender — left      |         (0.50, 0.00, 0.90, 0.22) |
|    18 | Front fender — right    |         (0.10, 0.78, 0.50, 1.00) |
|    19 | Rear fender — right     |         (0.50, 0.78, 0.90, 1.00) |
|    20 | Door / body — left      |         (0.28, 0.22, 0.82, 0.34) |
|    21 | Door / body — right     |         (0.28, 0.66, 0.82, 0.78) |
|    22 | Body — center spine     |         (0.10, 0.40, 0.90, 0.60) |

---

## Tuning after changing the car image

1. Replace `assets/images/vehicle_condition_car_top.png` in the repo.
2. Update the **intrinsic size** constant in [`vehicle_condition_diagram.dart`](../lib/features/check_in/presentation/widgets/vehicle_condition_diagram.dart) if pixel dimensions change.
3. Adjust the **rects** in `vehicle_damage_zones.dart` so each label still matches the artwork. Keep **evaluation order** unless you intentionally change priority.
4. Update **this document** and the dartdoc on `lookupVehicleZoneLabel` so they stay aligned.

---

## Related UI

- Screen: [`check_in_vehicle_condition_screen.dart`](../lib/features/check_in/presentation/check_in_vehicle_condition_screen.dart)
- Logged row subtitle: zone label from `VehicleDamageEntry.zoneLabel`, or percentage fallback when no zone matches.

Figma (step 3): [Vehicle Condition](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-2040&m=dev)
