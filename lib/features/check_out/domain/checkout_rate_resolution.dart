import '../../../core/session/standard_parking_rates.dart';
import '../models/checkout_preview_rates.dart';

/// Merges checkout-preview `rates` with Drift when server parking fees are zero.
class CheckoutRateResolution {
  CheckoutRateResolution._();

  /// True when preview resolved no flat or succeeding parking fee (server VT miss).
  static bool previewParkingRatesEmpty(CheckoutPreviewRates rates) =>
      rates.flatRate <= 0 && rates.succeedingRate <= 0;

  /// Preview first; when parking fees are zero, use the full Drift row from rates sync.
  static CheckoutPreviewRates effectiveRates({
    required CheckoutPreviewRates preview,
    required StandardParkingRates? drift,
    required int driftFlatHours,
    required String driftOvernightStart,
    required String driftOvernightEnd,
  }) {
    if (!previewParkingRatesEmpty(preview) || drift == null) return preview;
    return CheckoutPreviewRates(
      flatRate: drift.flatRatePesos.toDouble(),
      flatRateHours: driftFlatHours,
      succeedingRate: drift.succeedingHourPesos.toDouble(),
      overnightFee: drift.overnightFeePesos.toDouble(),
      lostTicketFee: drift.lostTicketFeePesos.toDouble(),
      overnightStart: driftOvernightStart.trim(),
      overnightEnd: driftOvernightEnd.trim(),
    );
  }
}
