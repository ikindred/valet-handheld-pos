import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/formatting/plate_number.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/session/standard_parking_rates.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/checkout_exceptions.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/rate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../domain/checkout_condition_payload.dart';
import '../domain/checkout_preview_format.dart';
import '../domain/checkout_pricing.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../domain/ticket_damage_markers.dart';
import '../models/check_out_response.dart';
import '../models/checkout_preview_response.dart';

class CheckOutState extends Equatable {
  const CheckOutState({
    this.ticket,
    this.preview,
    this.checkInDamage = const [],
    this.checkoutAddedDamage = const [],
    this.selectedDamageType = DamageType.dent,
    this.rates,
    this.breakdown,
    this.amountTenderedInput = '',
    this.driverIn,
    this.driverOut,
    this.scanError = '',
    this.isLookupBusy = false,
    this.isLoadingPreview = false,
    this.isSubmitting = false,
    this.isLostTicket = false,
    this.previewError = '',
    this.serverTicketId,
    this.serverTotal,
    this.invoiceNumber,
    this.checkOutResponse,
    this.flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
    this.overnightStart = '',
    this.overnightEnd = '',
    this.receiptTicket,
    this.receiptTotalPesos,
    this.receiptChangePesos,
    this.receiptSnapshot,
    this.branchName,
    this.mallHours = 'MONDAY – SUNDAY · 10:00AM – 9:00PM',
  });

  final Ticket? ticket;
  final CheckoutPreviewResponse? preview;
  final List<VehicleDamageEntry> checkInDamage;
  final List<VehicleDamageEntry> checkoutAddedDamage;
  final DamageType selectedDamageType;
  final StandardParkingRates? rates;
  final CheckoutBreakdown? breakdown;
  final String amountTenderedInput;
  final String? driverIn;
  final String? driverOut;
  final String scanError;
  final bool isLookupBusy;
  final bool isLoadingPreview;
  final bool isSubmitting;
  final bool isLostTicket;
  final String previewError;
  final String? serverTicketId;
  final double? serverTotal;
  final String? invoiceNumber;
  final CheckOutResponse? checkOutResponse;
  final int flatBlockHours;
  final String overnightStart;
  final String overnightEnd;
  final String? receiptTicket;
  final double? receiptTotalPesos;
  final double? receiptChangePesos;
  final CheckoutReceiptSnapshot? receiptSnapshot;
  final String? branchName;
  final String mallHours;

  List<VehicleDamageEntry> get diagramEntries => [
        ...checkInDamage,
        ...checkoutAddedDamage,
      ];

  double get lostTicketFeePesos =>
      preview?.rates?.lostTicketFee ??
      rates?.lostTicketFeePesos.toDouble() ??
      200.0;

  double? get authoritativeTotal {
    final parking = breakdown?.total;
    if (parking == null) return null;
    if (isLostTicket) return parking + lostTicketFeePesos;
    return parking;
  }

  /// True when the user must return to scan (no in-progress or completed receipt).
  bool get needsScanStep => ticket == null && receiptTicket == null;

  /// Step 5 receipt screen is showing.
  bool get isReceiptStep => receiptTicket != null;

  CheckOutState copyWith({
    Ticket? ticket,
    CheckoutPreviewResponse? preview,
    bool clearPreview = false,
    List<VehicleDamageEntry>? checkInDamage,
    List<VehicleDamageEntry>? checkoutAddedDamage,
    DamageType? selectedDamageType,
    StandardParkingRates? rates,
    CheckoutBreakdown? breakdown,
    bool clearBreakdown = false,
    String? amountTenderedInput,
    String? driverIn,
    String? driverOut,
    String? scanError,
    bool? isLookupBusy,
    bool? isLoadingPreview,
    bool? isSubmitting,
    bool? isLostTicket,
    String? previewError,
    String? serverTicketId,
    bool clearServerTicketId = false,
    double? serverTotal,
    bool clearServerTotal = false,
    String? invoiceNumber,
    CheckOutResponse? checkOutResponse,
    bool clearCheckOutResponse = false,
    int? flatBlockHours,
    String? overnightStart,
    String? overnightEnd,
    String? receiptTicket,
    double? receiptTotalPesos,
    double? receiptChangePesos,
    CheckoutReceiptSnapshot? receiptSnapshot,
    bool clearReceipt = false,
    String? branchName,
    String? mallHours,
  }) {
    return CheckOutState(
      ticket: ticket ?? this.ticket,
      preview: clearPreview ? null : (preview ?? this.preview),
      checkInDamage: checkInDamage ?? this.checkInDamage,
      checkoutAddedDamage: checkoutAddedDamage ?? this.checkoutAddedDamage,
      selectedDamageType: selectedDamageType ?? this.selectedDamageType,
      rates: rates ?? this.rates,
      breakdown: clearBreakdown ? null : (breakdown ?? this.breakdown),
      amountTenderedInput: amountTenderedInput ?? this.amountTenderedInput,
      driverIn: driverIn ?? this.driverIn,
      driverOut: driverOut ?? this.driverOut,
      scanError: scanError ?? this.scanError,
      isLookupBusy: isLookupBusy ?? this.isLookupBusy,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLostTicket: isLostTicket ?? this.isLostTicket,
      previewError: previewError ?? this.previewError,
      serverTicketId:
          clearServerTicketId ? null : (serverTicketId ?? this.serverTicketId),
      serverTotal:
          clearServerTotal ? null : (serverTotal ?? this.serverTotal),
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      checkOutResponse:
          clearCheckOutResponse ? null : (checkOutResponse ?? this.checkOutResponse),
      flatBlockHours: flatBlockHours ?? this.flatBlockHours,
      overnightStart: overnightStart ?? this.overnightStart,
      overnightEnd: overnightEnd ?? this.overnightEnd,
      receiptTicket: clearReceipt ? null : (receiptTicket ?? this.receiptTicket),
      receiptTotalPesos:
          clearReceipt ? null : (receiptTotalPesos ?? this.receiptTotalPesos),
      receiptChangePesos:
          clearReceipt ? null : (receiptChangePesos ?? this.receiptChangePesos),
      receiptSnapshot:
          clearReceipt ? null : (receiptSnapshot ?? this.receiptSnapshot),
      branchName: branchName ?? this.branchName,
      mallHours: mallHours ?? this.mallHours,
    );
  }

  @override
  List<Object?> get props => [
        ticket,
        preview,
        checkInDamage,
        checkoutAddedDamage,
        selectedDamageType,
        rates,
        breakdown,
        amountTenderedInput,
        driverIn,
        driverOut,
        scanError,
        isLookupBusy,
        isLoadingPreview,
        isSubmitting,
        isLostTicket,
        previewError,
        serverTicketId,
        serverTotal,
        invoiceNumber,
        checkOutResponse,
        flatBlockHours,
        overnightStart,
        overnightEnd,
        receiptTicket,
        receiptTotalPesos,
        receiptChangePesos,
        receiptSnapshot,
        branchName,
        mallHours,
      ];
}

class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit(
    this._tickets,
    this._rates,
    this._auth,
    this._transactionsApi,
  ) : super(const CheckOutState());

  final TicketService _tickets;
  final RateService _rates;
  final AuthRepository _auth;
  final TransactionsApi _transactionsApi;

  void reset() => emit(
        CheckOutState(
          rates: state.rates,
          flatBlockHours: state.flatBlockHours,
          overnightStart: state.overnightStart,
          overnightEnd: state.overnightEnd,
          branchName: state.branchName,
          mallHours: state.mallHours,
        ),
      );

  void setRates(StandardParkingRates? rates) {
    emit(state.copyWith(rates: rates));
    _recomputeBreakdown();
  }

  /// Branch rates from Drift (Standard row when [vehicleType] is null).
  Future<void> hydrateBranchRatesFromDrift({String? vehicleType}) async {
    try {
      final branchId = await _auth.branchUuidForApi();
      final vt = vehicleType?.trim();
      final resolved = await _rates.checkoutRatesForOffline(
        branchId: branchId,
        vehicleType: vt == null || vt.isEmpty ? null : vt,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          rates: resolved.rates,
          flatBlockHours: resolved.flatBlockHours,
          overnightStart: resolved.overnightStart,
          overnightEnd: resolved.overnightEnd,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      const fallback = StandardParkingRates.offlineDefault;
      emit(
        state.copyWith(
          rates: fallback,
          flatBlockHours: CheckoutPricing.defaultFlatBlockHours,
          overnightStart: CheckoutPricing.defaultOvernightStart,
          overnightEnd: CheckoutPricing.defaultOvernightEnd,
        ),
      );
    }
  }

  Future<void> hydrateRatesFromDrift() async {
    final t = state.ticket;
    if (t == null) return;
    try {
      // Same branch UUID key as RateFetchService / dashboard modal upsert.
      final branchId = await _auth.branchUuidForApi();
      final vehicleType = t.vehicleType.trim();
      final resolved = await _rates.checkoutRatesForOffline(
        branchId: branchId,
        vehicleType: vehicleType.isEmpty ? null : vehicleType,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          rates: resolved.rates,
          flatBlockHours: resolved.flatBlockHours,
          overnightStart: resolved.overnightStart,
          overnightEnd: resolved.overnightEnd,
        ),
      );
      _recomputeBreakdown();
    } catch (_) {
      if (isClosed) return;
      const fallback = StandardParkingRates.offlineDefault;
      emit(
        state.copyWith(
          rates: fallback,
          flatBlockHours: CheckoutPricing.defaultFlatBlockHours,
          overnightStart: CheckoutPricing.defaultOvernightStart,
          overnightEnd: CheckoutPricing.defaultOvernightEnd,
        ),
      );
      _recomputeBreakdown();
    }
  }

  void beginFromTicket(Ticket t) {
    final checkIn = parseTicketDamageMarkersForCheckout(t.damageMarkers);
    emit(
      CheckOutState(
        rates: state.rates,
        flatBlockHours: state.flatBlockHours,
        overnightStart: state.overnightStart,
        overnightEnd: state.overnightEnd,
        branchName: state.branchName,
        mallHours: state.mallHours,
        ticket: t,
        driverIn: t.driverIn,
        checkInDamage: checkIn,
        checkoutAddedDamage: const [],
        selectedDamageType: DamageType.dent,
      ),
    );
    _recomputeBreakdown();
    unawaited(hydrateRatesFromDrift());
    unawaited(_hydrateBranchName());
  }

  Future<void> _hydrateBranchName() async {
    try {
      final site = await _auth.branchAndAreaFromDb();
      if (isClosed) return;
      final branch = site.branch.trim();
      if (branch.isEmpty) return;
      emit(state.copyWith(branchName: branch));
    } catch (_) {}
  }

  String? _checkOutPathId() {
    final sid = state.serverTicketId?.trim() ?? '';
    if (sid.isNotEmpty) return sid;
    final driftSid = state.ticket?.serverTicketId?.trim() ?? '';
    if (driftSid.isNotEmpty) return driftSid;
    return state.ticket?.id;
  }

  ({List<VehicleDamageEntry> checkIn, List<VehicleDamageEntry> checkout})
      _damageFromPreview(CheckoutPreviewResponse preview) {
    final checkIn = [
      ...damageEntriesFromComparison(preview.checkInConditions),
      for (final c in preview.conditionComparison)
        if (!c.isNew) ...damageEntriesFromComparison([c]),
    ];
    final checkoutOnly = [
      for (final c in preview.conditionComparison)
        if (c.isNew) ...damageEntriesFromComparison([c]),
    ];
    return (checkIn: checkIn, checkout: checkoutOnly);
  }

  void _emitPreviewLoaded({
    required CheckoutPreviewResponse preview,
    required Ticket ticket,
  }) {
    final dmg = _damageFromPreview(preview);
    emit(
      state.copyWith(
        preview: preview,
        previewError: '',
        serverTicketId: preview.transactionId,
        clearServerTotal: true,
        ticket: ticket,
        driverIn: ticket.driverIn,
        isLookupBusy: false,
        isLoadingPreview: false,
        checkInDamage: dmg.checkIn,
        checkoutAddedDamage: dmg.checkout,
        clearBreakdown: true,
      ),
    );
    _recomputeBreakdown();
  }

  Ticket _mergeTicketWithPreview(Ticket base, CheckoutPreviewResponse preview) {
    final pt = preview.ticket;
    final belongingsJson = preview.belongings.isEmpty
        ? base.personalBelongings
        : jsonEncode(preview.belongings);
    return Ticket(
      id: base.id,
      shiftId: base.shiftId,
      userId: base.userId,
      branchId: base.branchId,
      plateNumber: pt.plate.isNotEmpty ? pt.plate : base.plateNumber,
      vehicleBrand: pt.vehicleMake.isNotEmpty ? pt.vehicleMake : base.vehicleBrand,
      vehicleColor: pt.vehicleColor.isNotEmpty ? pt.vehicleColor : base.vehicleColor,
      vehicleType: pt.vehicleType.isNotEmpty ? pt.vehicleType : base.vehicleType,
      cellphoneNumber: preview.customerContact ?? base.cellphoneNumber,
      damageMarkers: base.damageMarkers,
      personalBelongings: belongingsJson,
      signaturePng: base.signaturePng,
      checkInAt: pt.timeIn.isNotEmpty ? pt.timeIn : base.checkInAt,
      checkOutAt: base.checkOutAt,
      fee: base.fee,
      status: base.status,
      syncStatus: base.syncStatus,
      createdAt: base.createdAt,
      serverTicketId: preview.transactionId,
      driverIn: pt.valetIn ?? base.driverIn,
      driverOut: base.driverOut,
    );
  }

  Future<Ticket?> _minimalTicketFromPreview(CheckoutPreviewResponse preview) async {
    final session = await _auth.getActiveSession();
    if (session == null) return null;
    final site = await _auth.branchAndAreaFromDb();
    final shift = await _auth.getOpenShiftForUser(session.userId);
    final pt = preview.ticket;
    final ticketId =
        pt.ticketNumber.isNotEmpty ? pt.ticketNumber : 'TKT-UNKNOWN';
    return Ticket(
      id: ticketId,
      shiftId: shift?.id ?? '',
      userId: shift?.userId ?? session.userId.toString(),
      branchId: site.branch,
      plateNumber: pt.plate,
      vehicleBrand: pt.vehicleMake,
      vehicleColor: pt.vehicleColor,
      vehicleType: pt.vehicleType,
      cellphoneNumber: preview.customerContact ?? '',
      damageMarkers: '[]',
      personalBelongings: jsonEncode(preview.belongings),
      checkInAt: pt.timeIn.isNotEmpty
          ? pt.timeIn
          : DateTime.now().toIso8601String(),
      status: 'active',
      syncStatus: 'synced',
      createdAt: DateTime.now().toIso8601String(),
      serverTicketId: preview.transactionId,
      driverIn: pt.valetIn,
    );
  }

  Future<CheckoutPreviewResponse> _fetchCheckoutPreview(String lookupKey) async {
    final session = await _auth.getActiveSession();
    final token = session?.authToken;
    if (token == null || token.isEmpty) {
      throw CheckoutAuthException();
    }
    return _transactionsApi.getCheckoutPreview(
      token: token,
      ticketId: lookupKey,
    );
  }

  void setSelectedDamage(DamageType t) =>
      emit(state.copyWith(selectedDamageType: t));

  void addCheckoutDamageAt(double nx, double ny) {
    final label = lookupVehicleZoneLabel(nx, ny);
    final e = VehicleDamageEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      normalizedX: nx,
      normalizedY: ny,
      type: state.selectedDamageType,
      zoneLabel: label,
    );
    emit(
      state.copyWith(
        checkoutAddedDamage: [...state.checkoutAddedDamage, e],
      ),
    );
  }

  void removeCheckoutDamage(String id) {
    final next = [
      for (final x in state.checkoutAddedDamage)
        if (x.id != id) x,
    ];
    emit(state.copyWith(checkoutAddedDamage: next));
  }

  void applyCheckoutIssueSession({required List<VehicleDamageEntry> damage}) {
    emit(state.copyWith(checkoutAddedDamage: damage));
  }

  void setAmountTenderedInput(String s) =>
      emit(state.copyWith(amountTenderedInput: s));

  void setLostTicket(bool value) {
    if (value == state.isLostTicket) return;
    emit(
      state.copyWith(
        isLostTicket: value,
        amountTenderedInput: value ? '' : state.amountTenderedInput,
      ),
    );
  }

  void setDriverOut(String raw) {
    final t = raw.trim();
    emit(state.copyWith(driverOut: t.isEmpty ? null : t));
  }

  Future<void> lookupByTicketCode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return;
    emit(
      state.copyWith(
        scanError: '',
        isLookupBusy: true,
        isLoadingPreview: true,
        clearPreview: true,
        clearServerTicketId: true,
      ),
    );
    try {
      final lookupKey = _normalizeQrPayload(code);
      ValetLog.debug('CheckOutCubit.lookupByTicketCode', 'lookupKey=$lookupKey');

      if (await InternetReachability.hasInternet()) {
        try {
          ValetLog.info(
            'CheckOutCubit.lookupByTicketCode',
            'GET checkout-preview/$lookupKey',
          );
          final preview = await _fetchCheckoutPreview(lookupKey);
          if (isClosed) return;

          final ticketNumber = preview.ticket.ticketNumber.isNotEmpty
              ? preview.ticket.ticketNumber
              : lookupKey;
          final local = await _tickets.activeTicketByTicketNumber(ticketNumber) ??
              await _tickets.activeTicketByTicketNumber(lookupKey);
          final ticket = local != null
              ? _mergeTicketWithPreview(local, preview)
              : await _minimalTicketFromPreview(preview);
          if (ticket == null) {
            emit(
              state.copyWith(
                scanError: 'Sign in and open a shift to check out.',
                isLookupBusy: false,
                isLoadingPreview: false,
              ),
            );
            return;
          }
          _emitPreviewLoaded(preview: preview, ticket: ticket);
          return;
        } on TicketNotFoundException {
          emit(
            state.copyWith(
              scanError: 'Ticket not found.',
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        } on CheckoutAuthException catch (e) {
          emit(
            state.copyWith(
              scanError: e.message,
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        } on CheckoutApiException catch (e) {
          emit(
            state.copyWith(
              scanError: e.message,
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        }
      }

      final vt = await _tickets.activeTicketByTicketNumber(lookupKey) ??
          await _tickets.activeTicketByTicketNumber(code);
      if (vt != null) {
        beginFromTicket(vt);
        emit(
          state.copyWith(
            isLookupBusy: false,
            isLoadingPreview: false,
            previewError: 'Offline — showing saved ticket data.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          scanError: 'Ticket not found on this device.',
          isLookupBusy: false,
          isLoadingPreview: false,
        ),
      );
    } catch (e, st) {
      ValetLog.error('CheckOutCubit.lookupByTicketCode', 'unexpected', e, st);
      emit(
        state.copyWith(
          scanError: 'Could not load ticket. Try again.',
          isLookupBusy: false,
          isLoadingPreview: false,
        ),
      );
    }
  }

  Future<void> lookupByPlate(String raw) async {
    final plate = normalizePlateNumber(raw);
    if (plate.isEmpty) return;
    emit(
      state.copyWith(
        scanError: '',
        isLookupBusy: true,
        isLoadingPreview: true,
        clearPreview: true,
        clearServerTicketId: true,
      ),
    );
    try {
      final vt = await _tickets.activeTicketByPlate(plate);
      if (vt == null) {
        emit(
          state.copyWith(
            scanError:
                'Ticket not found. Try scanning the QR code or entering the ticket number instead.',
            isLookupBusy: false,
            isLoadingPreview: false,
          ),
        );
        return;
      }

      if (!await InternetReachability.hasInternet()) {
        beginFromTicket(vt);
        emit(
          state.copyWith(
            isLookupBusy: false,
            isLoadingPreview: false,
            previewError: 'Offline — showing saved ticket data.',
          ),
        );
        return;
      }

      try {
        ValetLog.info('CheckOutCubit.lookupByPlate', 'GET checkout-preview/$plate');
        final preview = await _fetchCheckoutPreview(plate);
        if (isClosed) return;
        _emitPreviewLoaded(
          preview: preview,
          ticket: _mergeTicketWithPreview(vt, preview),
        );
      } on TicketNotFoundException {
        emit(
          state.copyWith(
            scanError: 'Ticket not found.',
            isLookupBusy: false,
            isLoadingPreview: false,
          ),
        );
      } on CheckoutAuthException catch (e) {
        emit(
          state.copyWith(
            scanError: e.message,
            isLookupBusy: false,
            isLoadingPreview: false,
          ),
        );
      } on CheckoutApiException catch (e) {
        emit(
          state.copyWith(
            scanError: e.message,
            isLookupBusy: false,
            isLoadingPreview: false,
          ),
        );
      }
    } catch (e, st) {
      ValetLog.error('CheckOutCubit.lookupByPlate', 'unexpected', e, st);
      emit(
        state.copyWith(
          scanError: 'Lookup failed. Try again.',
          isLookupBusy: false,
          isLoadingPreview: false,
        ),
      );
    }
  }

  String _normalizeQrPayload(String code) {
    try {
      final decoded = jsonDecode(code);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        for (final k in ['ticket_number', 'ticketNumber', 'ticket']) {
          final v = m[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
      }
    } catch (_) {}
    return code.trim();
  }

  void _recomputeBreakdown() {
    final previewRates = state.preview?.rates;
    if (previewRates != null) {
      final timeInRaw = state.preview!.ticket.timeIn.trim();
      if (timeInRaw.isEmpty) {
        emit(state.copyWith(clearBreakdown: true));
        return;
      }
      final timeIn = PhilippineTime.fromApiIso(timeInRaw);
      final timeOut = PhilippineTime.now();
      final b = CheckoutPricing.computeFromPreviewRates(
        timeIn: timeIn,
        timeOut: timeOut,
        rates: previewRates,
        flatBlockHours: CheckoutPricing.defaultFlatBlockHours,
      );
      emit(
        state.copyWith(
          breakdown: b,
          rates: StandardParkingRates(
            flatRatePesos: previewRates.flatRate.round(),
            succeedingHourPesos: previewRates.succeedingRate.round(),
            overnightFeePesos: previewRates.overnightFee.round(),
            lostTicketFeePesos: previewRates.lostTicketFee.round(),
          ),
        ),
      );
      return;
    }

    final t = state.ticket;
    final rates = state.rates;
    if (t == null || rates == null) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }
    final checkInRaw = t.checkInAt.trim();
    if (checkInRaw.isEmpty) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }
    final start = state.overnightStart.trim().isNotEmpty
        ? state.overnightStart.trim()
        : CheckoutPricing.defaultOvernightStart;
    final end = state.overnightEnd.trim().isNotEmpty
        ? state.overnightEnd.trim()
        : CheckoutPricing.defaultOvernightEnd;
    final b = CheckoutPricing.compute(
      timeIn: PhilippineTime.fromApiIso(checkInRaw),
      timeOut: PhilippineTime.now(),
      rates: rates,
      flatBlockHours: state.flatBlockHours,
      overnightStart: start,
      overnightEnd: end,
    );
    emit(state.copyWith(breakdown: b));
  }

  void refreshBreakdown() => _recomputeBreakdown();

  double? parsedTendered() {
    final s = state.amountTenderedInput.trim().replaceAll(',', '');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  double? changeDue() {
    final total = state.authoritativeTotal;
    final t = parsedTendered();
    if (total == null || t == null) return null;
    return t - total;
  }

  List<Map<String, dynamic>> _conditionCheckoutBody() {
    final merged = [...state.checkInDamage, ...state.checkoutAddedDamage];
    return conditionCheckoutPayload(merged);
  }

  Future<void> _enqueueOfflineCheckoutFinalize({
    required String ticketId,
    required String? serverTicketId,
    required double amount,
    required List<Map<String, dynamic>> conditionBody,
    required bool isOvernight,
    required bool ticketLost,
  }) async {
    final timeOutIso = PhilippineTime.now().toUtc().toIso8601String();
    await _tickets.enqueueCheckoutFinalize(
      ticketId: ticketId,
      serverTicketId: serverTicketId,
      amount: amount,
      timeOut: timeOutIso,
      isOvernight: isOvernight,
      ticketLost: ticketLost,
      driverOut: state.driverOut,
      conditionCheckout: conditionBody,
    );
  }

  /// Returns error message for snackbar, or `null` on success.
  Future<String?> finalizeCheckout(BuildContext context) async {
    final t = state.ticket;
    final total = state.authoritativeTotal;
    if (t == null || total == null) {
      return 'Checkout data is not ready. Wait for preview or try again.';
    }

    final tendered = parsedTendered();
    if (tendered == null) {
      return 'Enter amount received.';
    }
    if (tendered + 1e-6 < total) {
      return 'Amount is less than total due.';
    }

    final change = tendered - total;
    final timeOut = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final merged = [...state.checkInDamage, ...state.checkoutAddedDamage];
    final markersJson = encodeTicketDamageMarkersForCheckout(merged);
    final checkOutIso =
        DateTime.fromMillisecondsSinceEpoch(timeOut * 1000).toIso8601String();
    final driverOut = state.driverOut ?? '';

    emit(state.copyWith(isSubmitting: true));

    try {
      final fresh = await _tickets.ticketById(t.id);
      if (fresh == null) {
        emit(state.copyWith(isSubmitting: false));
        return 'Ticket not found.';
      }
      if (fresh.status != 'active') {
        emit(state.copyWith(isSubmitting: false));
        return 'This ticket is no longer active.';
      }

      CheckOutResponse? response;
      var invoice = state.invoiceNumber;
      var serverTotal = total;

      final session = await _auth.getActiveSession();
      final token = session?.authToken;
      final pathId = _checkOutPathId();
      final conditionBody = _conditionCheckoutBody();
      final isOvernight = state.breakdown?.overnightApplied ?? false;
      final ticketLost = state.isLostTicket;
      final hasInternet = await InternetReachability.hasInternet();

      if (token != null && token.isNotEmpty) {
        if (pathId == null || pathId.isEmpty) {
          emit(state.copyWith(isSubmitting: false));
          return 'Missing server transaction id.';
        }
        if (hasInternet) {
          try {
            final preview = state.preview;
            if (preview == null) {
              emit(state.copyWith(isSubmitting: false));
              return 'Checkout preview is not loaded.';
            }
            final timeOutIso =
                PhilippineTime.now().toUtc().toIso8601String();
            response = await _transactionsApi.submitCheckOut(
              token: token,
              ticketId: pathId,
              amount: total,
              timeOut: timeOutIso,
              isOvernight: isOvernight,
              ticketLost: ticketLost,
              driverOut: state.driverOut,
              conditionCheckout: conditionBody,
            );
            invoice = response.invoiceNumber;
            // Lost fee is additive — keep full total due, not server lost-fee-only.
            serverTotal = ticketLost ? total : response.total;
          } on SocketException {
            if (state.isLostTicket) {
              emit(state.copyWith(isSubmitting: false));
              return 'Lost ticket checkout requires an internet connection.';
            }
            await _enqueueOfflineCheckoutFinalize(
              ticketId: t.id,
              serverTicketId: pathId,
              amount: total,
              conditionBody: conditionBody,
              isOvernight: isOvernight,
              ticketLost: ticketLost,
            );
          } on DioException catch (e) {
            if (_isOfflineDio(e)) {
              if (state.isLostTicket) {
                emit(state.copyWith(isSubmitting: false));
                return 'Lost ticket checkout requires an internet connection.';
              }
              await _enqueueOfflineCheckoutFinalize(
                ticketId: t.id,
                serverTicketId: pathId,
                amount: total,
                conditionBody: conditionBody,
                isOvernight: isOvernight,
                ticketLost: ticketLost,
              );
            } else {
              rethrow;
            }
          }
        } else {
          if (state.isLostTicket) {
            emit(state.copyWith(isSubmitting: false));
            return 'Lost ticket checkout requires an internet connection.';
          }
          await _enqueueOfflineCheckoutFinalize(
            ticketId: t.id,
            serverTicketId: pathId,
            amount: total,
            conditionBody: conditionBody,
            isOvernight: isOvernight,
            ticketLost: ticketLost,
          );
        }
      } else {
        if (state.isLostTicket) {
          emit(state.copyWith(isSubmitting: false));
          return 'Lost ticket checkout requires sign-in and a connection.';
        }
        await _enqueueOfflineCheckoutFinalize(
          ticketId: t.id,
          serverTicketId: pathId ?? state.serverTicketId,
          amount: total,
          conditionBody: conditionBody,
          isOvernight: isOvernight,
          ticketLost: ticketLost,
        );
      }

      await _tickets.completeTicketCheckout(
        ticketId: t.id,
        checkOutAtIso: checkOutIso,
        totalFee: serverTotal.toDouble(),
        damageMarkersJson: markersJson,
        driverOut: driverOut,
        status: state.isLostTicket ? 'lost' : 'completed',
      );

      final preview = state.preview;
      final snap = preview != null
          ? CheckoutReceiptSnapshot.fromPreview(
              localTicketId: t.id,
              preview: preview,
              totalPesos: serverTotal.toDouble(),
              tendered: tendered,
              change: change,
              invoiceNumber: invoice,
              branchName: state.branchName,
            )
          : state.breakdown != null
              ? CheckoutReceiptSnapshot.capture(
                  ticket: t,
                  b: state.breakdown!,
                  tendered: tendered,
                  change: change,
                  timeOutUnix: timeOut,
                  totalPesos: total,
                )
              : CheckoutReceiptSnapshot.minimal(
                  ticketNumber: t.id,
                  totalPesos: serverTotal.toDouble(),
                  changePesos: change,
                );

      emit(
        state.copyWith(
          isSubmitting: false,
          serverTotal: serverTotal.toDouble(),
          invoiceNumber: invoice,
          checkOutResponse: response,
          receiptTicket: t.id,
          receiptTotalPesos: serverTotal.toDouble(),
          receiptChangePesos: change,
          receiptSnapshot: snap,
        ),
      );

      if (context.mounted) {
        context.go('/check-out/step-5');
      }
      return null;
    } on CheckOutValidationException catch (e) {
      emit(state.copyWith(isSubmitting: false));
      return e.message;
    } on TicketAlreadyCheckedOutException catch (e) {
      emit(state.copyWith(isSubmitting: false));
      return e.message;
    } on CheckoutAuthException catch (e) {
      emit(state.copyWith(isSubmitting: false));
      return e.message;
    } on CheckoutApiException catch (e) {
      emit(state.copyWith(isSubmitting: false));
      return e.message;
    } catch (e, st) {
      ValetLog.error('CheckOutCubit.finalizeCheckout', 'failed', e, st);
      emit(state.copyWith(isSubmitting: false));
      return 'Could not complete checkout. Try again.';
    }
  }

  bool _isOfflineDio(DioException e) {
    if (e.error is SocketException) return true;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }
}
