import '../../core/connectivity/internet_reachability.dart';
import '../../data/remote/area_detail.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/check_out/domain/checkout_pricing.dart';

/// Rates + parking layout — area detail first; branch detail `rate` as fallback.
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

/// Online: area detail for slots; branch detail `rate` when area has no fees.
Future<BranchAreaLoadResult> refreshBranchAreaDialogData({
  required AuthRepository authRepository,
  required RateFetchService rateFetchService,
  required RateService rateService,
  bool allowOfflineFallback = true,
}) async {
  final branchUuid = await authRepository.branchUuidForApi();
  final areaUuid = await authRepository.areaUuidForApi();
  final defaultFlatHours = CheckoutPricing.defaultFlatBlockHours;

  if (branchUuid.isEmpty || areaUuid.isEmpty) {
    return const BranchAreaLoadResult(
      errorMessage:
          'Branch or area is not configured on this device. Sign in online first.',
    );
  }

  final online = await InternetReachability.hasInternet();

  if (online) {
    AreaDetail? detail = await rateFetchService.fetchAreaDetail(
      branchId: branchUuid,
      areaId: areaUuid,
    );

    var standard = detail?.standard ??
        const ParkingRateFees(
          flatRate: 0,
          succeedingRate: 0,
          overnightFee: 0,
          lostTicketFee: 0,
        );
    var vehicleTypeRates = detail?.vehicleTypeRates ?? const [];
    var flatHours = defaultFlatHours;
    BranchRatesSnapshot? branchRates;

    if (!standard.hasAny || vehicleTypeRates.isEmpty) {
      branchRates = await rateFetchService.fetchBranchRatesSnapshot(branchUuid);
      if (branchRates != null) {
        if (!standard.hasAny && branchRates.standard.hasAny) {
          standard = branchRates.standard;
        }
        if (vehicleTypeRates.isEmpty && branchRates.vehicleTypeRates.isNotEmpty) {
          vehicleTypeRates = branchRates.vehicleTypeRates;
        }
        flatHours = branchRates.flatBlockHours;
      }
    }

    if (detail != null && standard.hasAny) {
      final areaDetail = detail;
      await rateFetchService.cacheAreaDetailRates(
        branchId: branchUuid,
        detail: areaDetail.standard.hasAny
            ? areaDetail
            : AreaDetail(
                id: areaDetail.id,
                name: areaDetail.name,
                code: areaDetail.code,
                standard: standard,
                vehicleTypeRates: vehicleTypeRates,
                levels: areaDetail.levels,
                overnightTimes: branchRates?.overnightTimes ??
                    areaDetail.overnightTimes,
              ),
      );
    } else if (branchRates != null && branchRates.standard.hasAny) {
      await rateFetchService.cacheBranchRatesSnapshot(
        branchId: branchUuid,
        snapshot: branchRates,
      );
    }

    if (standard.hasAny || vehicleTypeRates.isNotEmpty) {
      return BranchAreaLoadResult(
        data: BranchAreaDialogData(
          flatBlockHours: flatHours,
          standard: standard,
          vehicleTypeRates: vehicleTypeRates,
          levels: detail?.levels ?? const [],
          fromAreaApi: detail != null,
        ),
      );
    }

    return const BranchAreaLoadResult(
      errorMessage:
          'No rates configured for this branch. Check admin settings and try again.',
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
