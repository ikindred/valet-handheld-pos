import 'package:equatable/equatable.dart';

import '../../../core/session/standard_parking_rates.dart';
import '../models/checkout_preview_rates.dart';

/// On-device parking fee breakdown for checkout.
class CheckoutBreakdown extends Equatable {
  const CheckoutBreakdown({
    required this.durationMinutes,
    required this.flatRateAmount,
    required this.succeedingAmount,
    required this.overnightAmount,
    required this.total,
    this.overnightApplied = false,
  });

  final int durationMinutes;
  final double flatRateAmount;
  final double succeedingAmount;
  final double overnightAmount;
  final double total;
  final bool overnightApplied;

  @override
  List<Object?> get props => [
        durationMinutes,
        flatRateAmount,
        succeedingAmount,
        overnightAmount,
        total,
        overnightApplied,
      ];
}

class CheckoutPricing {
  CheckoutPricing._();

  /// Hours included in the flat block when the API does not send a per-branch value.
  static const int defaultFlatBlockHours = 3;

  static CheckoutBreakdown computeFromPreviewRates({
    required DateTime timeIn,
    required DateTime timeOut,
    required CheckoutPreviewRates rates,
    int flatBlockHours = defaultFlatBlockHours,
  }) =>
      computeFees(
        timeIn: timeIn,
        timeOut: timeOut,
        flatRate: rates.flatRate,
        succeedingRate: rates.succeedingRate,
        overnightFee: rates.overnightFee,
        overnightCutoff: rates.overnightCutoff,
        flatBlockHours: flatBlockHours,
      );

  /// Offline / Drift rates (optional [overnightCutoff] when cached locally).
  static CheckoutBreakdown compute({
    required DateTime timeIn,
    required DateTime timeOut,
    required StandardParkingRates rates,
    int flatBlockHours = defaultFlatBlockHours,
    String overnightCutoff = '',
  }) =>
      computeFees(
        timeIn: timeIn,
        timeOut: timeOut,
        flatRate: rates.flatRatePesos.toDouble(),
        succeedingRate: rates.succeedingHourPesos.toDouble(),
        overnightFee: rates.overnightFeePesos.toDouble(),
        overnightCutoff: overnightCutoff,
        flatBlockHours: flatBlockHours,
      );

  static CheckoutBreakdown computeFees({
    required DateTime timeIn,
    required DateTime timeOut,
    required double flatRate,
    required double succeedingRate,
    required double overnightFee,
    required String overnightCutoff,
    int flatBlockHours = defaultFlatBlockHours,
  }) {
    final durationMinutes = durationMinutesCeil(timeIn, timeOut);
    final flatMinutes = flatBlockHours * 60;

    final double flatPortion;
    final double succeedingPortion;
    if (durationMinutes <= flatMinutes) {
      flatPortion = flatRate;
      succeedingPortion = 0;
    } else {
      final extraMinutes = durationMinutes - flatMinutes;
      final extraHours = (extraMinutes / 60).ceil();
      flatPortion = flatRate;
      succeedingPortion = extraHours * succeedingRate;
    }

    final overnightApplied =
        crossesOvernightCutoff(timeIn, timeOut, overnightCutoff);
    final overnightPortion = overnightApplied ? overnightFee : 0.0;
    final total = flatPortion + succeedingPortion + overnightPortion;

    return CheckoutBreakdown(
      durationMinutes: durationMinutes,
      flatRateAmount: flatPortion,
      succeedingAmount: succeedingPortion,
      overnightAmount: overnightPortion,
      total: total,
      overnightApplied: overnightApplied,
    );
  }

  /// Wall-clock minutes between [timeIn] and [timeOut], rounded up.
  static int durationMinutesCeil(DateTime timeIn, DateTime timeOut) {
    final ms = timeOut.difference(timeIn).inMilliseconds;
    if (ms <= 0) return 0;
    return ((ms + 59999) ~/ 60000).clamp(0, 1 << 30);
  }

  /// `true` when stay crosses [overnightCutoff] (`HH:mm` local) with entry before
  /// cutoff and exit after the same cutoff instant.
  static bool crossesOvernightCutoff(
    DateTime timeIn,
    DateTime timeOut,
    String overnightCutoff,
  ) {
    final trimmed = overnightCutoff.trim();
    if (trimmed.isEmpty) return false;
    final parts = trimmed.split(':');
    if (parts.length < 2) return false;
    final ch = int.tryParse(parts[0].trim());
    final cm = int.tryParse(parts[1].trim());
    if (ch == null || cm == null) return false;

    var day = DateTime(timeIn.year, timeIn.month, timeIn.day);
    final lastDay = DateTime(timeOut.year, timeOut.month, timeOut.day);

    while (!day.isAfter(lastDay)) {
      final cutoff = DateTime(day.year, day.month, day.day, ch, cm);
      if (timeIn.isBefore(cutoff) && timeOut.isAfter(cutoff)) {
        return true;
      }
      day = day.add(const Duration(days: 1));
    }
    return false;
  }
}
