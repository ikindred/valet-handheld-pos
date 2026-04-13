import 'package:equatable/equatable.dart';

import '../../../core/session/standard_parking_rates.dart';

/// Billable parking breakdown for an exit (offline-first; uses [StandardParkingRates]).
///
/// Assumes the flat rate covers the first [flatBlockHours] **ceiling** hours; each
/// additional started hour bills [StandardParkingRates.succeedingHourPesos].
/// Overnight applies when calendar day of exit is after calendar day of entry.
class CheckoutBreakdown extends Equatable {
  const CheckoutBreakdown({
    required this.durationMinutes,
    required this.billedHoursAfterFlat,
    required this.flatPortionPesos,
    required this.succeedingPortionPesos,
    required this.overnightApplied,
    required this.overnightPortionPesos,
    required this.totalPesos,
  });

  final int durationMinutes;
  final int billedHoursAfterFlat;
  final int flatPortionPesos;
  final int succeedingPortionPesos;
  final bool overnightApplied;
  final int overnightPortionPesos;
  final int totalPesos;

  @override
  List<Object?> get props => [
    durationMinutes,
    billedHoursAfterFlat,
    flatPortionPesos,
    succeedingPortionPesos,
    overnightApplied,
    overnightPortionPesos,
    totalPesos,
  ];
}

class CheckoutPricing {
  CheckoutPricing._();

  /// Hours included in the flat block when the API does not send a per-branch value.
  static const int defaultFlatBlockHours = 3;

  static CheckoutBreakdown compute({
    required int timeInUnix,
    required int timeOutUnix,
    required StandardParkingRates rates,
    int flatBlockHours = defaultFlatBlockHours,
  }) {
    final durationMinutes =
        ((timeOutUnix - timeInUnix) / 60).floor().clamp(0, 1 << 30);

    final timeIn = DateTime.fromMillisecondsSinceEpoch(timeInUnix * 1000);
    final timeOut = DateTime.fromMillisecondsSinceEpoch(timeOutUnix * 1000);
    final overnightApplied = _isOvernightStay(timeIn, timeOut);

    final totalHoursCeil = durationMinutes <= 0
        ? 0
        : ((durationMinutes + 59) ~/ 60);

    final billedAfterFlat =
        totalHoursCeil <= flatBlockHours ? 0 : totalHoursCeil - flatBlockHours;

    final flatPortion = rates.flatRatePesos;
    final succeedingPortion = billedAfterFlat * rates.succeedingHourPesos;
    final overnightPortion = overnightApplied ? rates.overnightFeePesos : 0;

    final total = flatPortion + succeedingPortion + overnightPortion;

    return CheckoutBreakdown(
      durationMinutes: durationMinutes,
      billedHoursAfterFlat: billedAfterFlat,
      flatPortionPesos: flatPortion,
      succeedingPortionPesos: succeedingPortion,
      overnightApplied: overnightApplied,
      overnightPortionPesos: overnightPortion,
      totalPesos: total,
    );
  }

  static bool _isOvernightStay(DateTime timeIn, DateTime timeOut) {
    final a = DateTime(timeIn.year, timeIn.month, timeIn.day);
    final b = DateTime(timeOut.year, timeOut.month, timeOut.day);
    return b.isAfter(a);
  }
}
