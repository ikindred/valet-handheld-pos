import 'package:equatable/equatable.dart';

import '../../../core/branch/overnight_window.dart';
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

  static const String defaultOvernightStart = '01:30';
  static const String defaultOvernightEnd = '06:00';

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
        overnightStart: rates.overnightStart,
        overnightEnd: rates.overnightEnd,
        flatBlockHours: flatBlockHours,
      );

  /// Offline / Drift rates with cached overnight window (`HH:mm`).
  static CheckoutBreakdown compute({
    required DateTime timeIn,
    required DateTime timeOut,
    required StandardParkingRates rates,
    int flatBlockHours = defaultFlatBlockHours,
    String overnightStart = '',
    String overnightEnd = '',
  }) =>
      computeFees(
        timeIn: timeIn,
        timeOut: timeOut,
        flatRate: rates.flatRatePesos.toDouble(),
        succeedingRate: rates.succeedingHourPesos.toDouble(),
        overnightFee: rates.overnightFeePesos.toDouble(),
        overnightStart: overnightStart,
        overnightEnd: overnightEnd,
        flatBlockHours: flatBlockHours,
      );

  static CheckoutBreakdown computeFees({
    required DateTime timeIn,
    required DateTime timeOut,
    required double flatRate,
    required double succeedingRate,
    required double overnightFee,
    required String overnightStart,
    required String overnightEnd,
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

    final window = OvernightWindow.tryFromHhMm(overnightStart, overnightEnd);
    final overnightApplied =
        window?.stayOverlaps(timeIn, timeOut) ?? false;
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

  /// Legacy single-cutoff helper — maps to [overnightStart] with [defaultOvernightEnd].
  @Deprecated('Use overnight_start + overnight_end window overlap instead')
  static bool crossesOvernightCutoff(
    DateTime timeIn,
    DateTime timeOut,
    String overnightCutoff,
  ) {
    final window = OvernightWindow.tryFromHhMm(
      overnightCutoff,
      defaultOvernightEnd,
    );
    return window?.stayOverlaps(timeIn, timeOut) ?? false;
  }
}
