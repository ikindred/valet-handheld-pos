import '../../core/connectivity/internet_reachability.dart';
import '../../data/remote/area_detail.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/parking_layout_service.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/check_out/domain/checkout_pricing.dart';

/// Whether the dialog needs fee rows or parking levels from area detail.
enum BranchAreaDialogPurpose {
  rates,
  parkingSlots,
}

/// Rates + parking layout — area detail first; branch detail `rate` as fallback.
class BranchAreaDialogData {
  const BranchAreaDialogData({
    required this.flatBlockHours,
    required this.standard,
    required this.vehicleTypeRates,
    required this.levels,
    this.overnightStart = '',
    this.overnightEnd = '',
    this.fromAreaApi = false,
    this.usesAreaOverride = false,
  });

  final int flatBlockHours;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;

  /// Overnight billing window (`HH:mm`, 24h) from branch/area rates API.
  final String overnightStart;
  final String overnightEnd;
  final bool fromAreaApi;

  /// Fees resolved from `areaOverrides` for this parking area.
  final bool usesAreaOverride;
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
  required ParkingLayoutService parkingLayoutService,
  BranchAreaDialogPurpose purpose = BranchAreaDialogPurpose.rates,
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

    var standard = const ParkingRateFees(
      flatRate: 0,
      succeedingRate: 0,
      overnightFee: 0,
      lostTicketFee: 0,
    );
    var vehicleTypeRates = const <VehicleTypeRateRow>[];
    var flatHours = defaultFlatHours;
    var overnightStart = '';
    var overnightEnd = '';
    var usesAreaOverride = false;

    final branchRates = await rateFetchService.fetchBranchRatesForArea(
      branchId: branchUuid,
      areaId: areaUuid,
      areaCode: detail?.code ?? '',
    );

    if (branchRates != null) {
      standard = branchRates.standard;
      vehicleTypeRates = branchRates.vehicleTypeRates;
      flatHours = branchRates.flatBlockHours;
      usesAreaOverride = branchRates.usesAreaOverride;
      overnightStart = branchRates.overnightTimes.start?.trim() ?? '';
      overnightEnd = branchRates.overnightTimes.end?.trim() ?? '';
      if (branchRates.vehicleTypeRates.isNotEmpty) {
        await rateFetchService.cacheBranchRatesSnapshot(
          branchId: branchUuid,
          snapshot: branchRates,
        );
      }
    }

    if (detail != null) {
      if (detail.levels.isNotEmpty) {
        await parkingLayoutService.saveLevels(
          branchId: branchUuid,
          areaId: areaUuid,
          levels: detail.levels,
        );
      }
    }

    final levels = detail?.levels ?? const <AreaParkingLevel>[];
    final hasRates = vehicleTypeRates.isNotEmpty &&
        vehicleTypeRates.any((r) => r.fees.hasAny);
    final hasSlots = levels.isNotEmpty;

    if (purpose == BranchAreaDialogPurpose.parkingSlots) {
      if (hasSlots) {
        return BranchAreaLoadResult(
          data: BranchAreaDialogData(
            flatBlockHours: flatHours,
            standard: standard,
            vehicleTypeRates: vehicleTypeRates,
            levels: levels,
            overnightStart: overnightStart,
            overnightEnd: overnightEnd,
            fromAreaApi: detail != null,
            usesAreaOverride: usesAreaOverride,
          ),
        );
      }
      return const BranchAreaLoadResult(
        errorMessage:
            'No parking slots configured for this area. Check admin settings and try again.',
      );
    }

    if (hasRates) {
      return BranchAreaLoadResult(
        data: BranchAreaDialogData(
          flatBlockHours: flatHours,
          standard: standard,
          vehicleTypeRates: vehicleTypeRates,
          levels: levels,
          overnightStart: overnightStart,
          overnightEnd: overnightEnd,
          fromAreaApi: detail != null,
          usesAreaOverride: usesAreaOverride,
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

  final cachedLevels = await parkingLayoutService.loadLevels(
    branchId: branchUuid,
    areaId: areaUuid,
  );

  if (purpose == BranchAreaDialogPurpose.parkingSlots) {
    if (cachedLevels.isNotEmpty) {
      return BranchAreaLoadResult(
        offlineCache: true,
        data: BranchAreaDialogData(
          flatBlockHours: defaultFlatHours,
          standard: const ParkingRateFees(
            flatRate: 0,
            succeedingRate: 0,
            overnightFee: 0,
            lostTicketFee: 0,
          ),
          vehicleTypeRates: const [],
          levels: cachedLevels,
          fromAreaApi: false,
        ),
      );
    }
    return const BranchAreaLoadResult(
      errorMessage:
          'No internet and no cached parking layout. Sign in online once to download slots.',
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
      levels: cachedLevels,
      overnightStart: resolved.overnightStart,
      overnightEnd: resolved.overnightEnd,
      fromAreaApi: false,
    ),
  );
}
