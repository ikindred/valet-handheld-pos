import 'package:flutter/material.dart';

import '../../data/remote/area_detail.dart';

/// Shared free (green) / occupied (red) styling for slot chips and dropdowns.
abstract final class ParkingSlotStatusStyle {
  static const Color freeBackground = Color(0xFFE8F5E9);
  static const Color freeBorder = Color(0xFF43A047);
  static const Color freeText = Color(0xFF2E7D32);

  static const Color occupiedBackground = Color(0xFFFFEBEE);
  static const Color occupiedBorder = Color(0xFFE53935);
  static const Color occupiedText = Color(0xFFC62828);

  static Color backgroundFor(AreaParkingSlot slot) =>
      slot.isAvailable ? freeBackground : occupiedBackground;

  static Color borderFor(AreaParkingSlot slot) =>
      slot.isAvailable
          ? freeBorder.withValues(alpha: 0.45)
          : occupiedBorder.withValues(alpha: 0.45);

  static Color textFor(AreaParkingSlot slot) =>
      slot.isAvailable ? freeText : occupiedText;

  static String statusSuffix(AreaParkingSlot slot) =>
      slot.isAvailable ? ' · available' : ' · occupied';
}
