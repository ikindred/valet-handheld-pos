import '../../core/connectivity/internet_reachability.dart';
import '../../data/remote/area_detail.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/check_out/domain/checkout_pricing.dart';

/// Rates + parking layout from `GET /branches/{id}/areas/{areaId}`.
class BranchAreaDialogData {
  const BranchAreaDialogData({
    required this.flatBlockHours,
    required this.standard,
    required this.vehicleTypeRates,
    required this.levels,
    this.fromAreaApi = false,
  });

  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;
  final bool fromAreaApi;
}

class BranchAreaLoadResult {
  const BranchAreaLoadResult({
    this.data,
    this.offlineCache = false,
    this.errorMessage,
  });

  final BranchAreaDialogData? data;
  final bool offlineCache;
  final String? errorMessage;

  bool get hasError => errorMessage != null && data == null;
}

/// Fresh `GET /branches/{id}/areas/{areaId}` when online; optional Drift fallback offline.
Future<BranchAreaLoadResult> refreshBranchAreaDialogData({
  required AuthRepository authRepository,
  required RateFetchService rateFetchService,
  required RateService rateService,
  bool allowOfflineFallback = true,
}) async {
  final branchUuid = await authRepository.branchUuidForApi();
  final areaUuid = await authRepository.areaUuidForApi();
  final flatHours = CheckoutPricing.defaultFlatBlockHours;

  if (branchUuid.isEmpty || areaUuid.isEmpty) {
    return const BranchAreaLoadResult(
      errorMessage:
          'Branch or area is not configured on this device. Sign in online first.',
    );
  }

  final online = await InternetReachability.hasInternet();

  if (online) {
    final detail = await rateFetchService.fetchAreaDetail(
      branchId: branchUuid,
      areaId: areaUuid,
    );
    if (detail != null) {
      await rateFetchService.cacheAreaDetailRates(
        branchId: branchUuid,
        detail: detail,
      );
      return BranchAreaLoadResult(
        data: BranchAreaDialogData(
          flatBlockHours: flatHours,
          standard: detail.standard,
          vehicleTypeRates: detail.vehicleTypeRates,
          levels: detail.levels,
          fromAreaApi: true,
        ),
      );
    }
    return const BranchAreaLoadResult(
      errorMessage:
          'Could not refresh area data. Check your connection and try again.',
    );
  }

  if (!allowOfflineFallback) {
    return const BranchAreaLoadResult(
      errorMessage: 'No internet connection. Connect to refresh slot layout.',
    );
  }

  final resolved = await rateService.checkoutRatesResolved(
    branchId: branchUuid,
    vehicleType: 'Standard',
  );
  if (resolved == null) {
    return const BranchAreaLoadResult(
      errorMessage: 'No internet and no cached rates on this device.',
    );
  }
  final r = resolved.rates;
  return BranchAreaLoadResult(
    offlineCache: true,
    data: BranchAreaDialogData(
      flatBlockHours: resolved.flatBlockHours,
      standard: ParkingRateFees(
        flatRate: r.flatRatePesos,
        succeedingRate: r.succeedingHourPesos,
        overnightFee: r.overnightFeePesos,
        lostTicketFee: r.lostTicketFeePesos,
      ),
      vehicleTypeRates: const [],
      levels: const [],
      fromAreaApi: false,
    ),
  );
}
