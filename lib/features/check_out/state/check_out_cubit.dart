import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/pricing/transaction_payment_calculator.dart';
import '../../../core/formatting/valet_type_format.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/formatting/plate_number.dart';
import '../../../core/logging/valet_log.dart';
import '../../../core/session/standard_parking_rates.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/area_detail.dart';
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
import '../domain/checkout_rate_resolution.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../domain/checkout_valet_type.dart';
import '../domain/ticket_damage_markers.dart';
import '../models/check_out_response.dart';
import '../models/checkout_preview_rates.dart';
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
    this.checkoutBlockMessage,
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

  /// Non-dismissable checkout block (e.g. pending void request).
  final String? checkoutBlockMessage;

  /// True when check-in was self-park (no returning valet attendant).
  bool get isSelfPark {
    final previewType = preview?.valetType;
    if (previewType != null && previewType.trim().isNotEmpty) {
      return CheckoutValetType.isSelfPark(previewType);
    }
    return CheckoutValetType.isSelfParkFromDriverOutMeta(ticket?.driverOut);
  }

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
    String? checkoutBlockMessage,
    bool clearCheckoutBlockMessage = false,
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
      serverTicketId: clearServerTicketId
          ? null
          : (serverTicketId ?? this.serverTicketId),
      serverTotal: clearServerTotal ? null : (serverTotal ?? this.serverTotal),
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      checkOutResponse: clearCheckOutResponse
          ? null
          : (checkOutResponse ?? this.checkOutResponse),
      flatBlockHours: flatBlockHours ?? this.flatBlockHours,
      overnightStart: overnightStart ?? this.overnightStart,
      overnightEnd: overnightEnd ?? this.overnightEnd,
      receiptTicket: clearReceipt
          ? null
          : (receiptTicket ?? this.receiptTicket),
      receiptTotalPesos: clearReceipt
          ? null
          : (receiptTotalPesos ?? this.receiptTotalPesos),
      receiptChangePesos: clearReceipt
          ? null
          : (receiptChangePesos ?? this.receiptChangePesos),
      receiptSnapshot: clearReceipt
          ? null
          : (receiptSnapshot ?? this.receiptSnapshot),
      branchName: branchName ?? this.branchName,
      mallHours: mallHours ?? this.mallHours,
      checkoutBlockMessage: clearCheckoutBlockMessage
          ? null
          : (checkoutBlockMessage ?? this.checkoutBlockMessage),
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
    checkoutBlockMessage,
  ];
}

class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit(this._tickets, this._rates, this._auth, this._transactionsApi)
    : super(const CheckOutState());

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
          overnightStart: '',
          overnightEnd: '',
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
          overnightStart: '',
          overnightEnd: '',
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
        driverOut: CheckoutValetType.isSelfParkFromDriverOutMeta(t.driverOut)
            ? null
            : (state.driverOut ?? driverOutNameFromColumn(t.driverOut)),
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

  static const _offlinePreviewMessage = 'Offline — showing saved ticket data.';
  static const _previewApiFallbackMessage =
      'Preview unavailable — using saved rates on this device.';
  static const _previewMissingRatesMessage =
      'Preview has no rates — using saved rates on this device.';

  /// Drift-backed checkout when offline or checkout-preview cannot supply rates.
  void _beginDriftCheckout(Ticket ticket, {required String previewError}) {
    beginFromTicket(ticket);
    if (isClosed) return;
    emit(
      state.copyWith(
        isLookupBusy: false,
        isLoadingPreview: false,
        previewError: previewError,
      ),
    );
  }

  Future<bool> _tryDriftCheckoutFallback({
    required Ticket ticket,
    required String previewError,
  }) async {
    _beginDriftCheckout(ticket, previewError: previewError);
    return true;
  }

  void _emitPreviewLoaded({
    required CheckoutPreviewResponse preview,
    required Ticket ticket,
  }) {
    final dmg = _damageFromPreview(preview);
    final hasPreviewRates = preview.rates != null;
    final previewFlatHours = preview.rates?.flatRateHours ?? 0;
    emit(
      state.copyWith(
        preview: preview,
        previewError: hasPreviewRates ? '' : _previewMissingRatesMessage,
        serverTicketId: preview.transactionId,
        clearServerTotal: true,
        ticket: ticket,
        driverIn: ticket.driverIn ?? preview.ticket.valetIn,
        driverOut: preview.valetType != null &&
                CheckoutValetType.isSelfPark(preview.valetType)
            ? null
            : (state.driverOut ??
                preview.ticket.valetOut ??
                driverOutNameFromColumn(ticket.driverOut)),
        isLookupBusy: false,
        isLoadingPreview: false,
        checkInDamage: dmg.checkIn,
        checkoutAddedDamage: dmg.checkout,
        clearBreakdown: true,
        flatBlockHours: previewFlatHours > 0
            ? previewFlatHours
            : state.flatBlockHours,
      ),
    );
    if (hasPreviewRates) {
      if (CheckoutRateResolution.previewParkingRatesEmpty(preview.rates!)) {
        unawaited(
          hydrateRatesFromDrift().then((_) {
            if (!isClosed) _recomputeBreakdown();
          }),
        );
      } else {
        _recomputeBreakdown();
      }
    } else {
      unawaited(hydrateRatesFromDrift());
    }
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
      vehicleBrand: pt.vehicleMake.isNotEmpty
          ? pt.vehicleMake
          : base.vehicleBrand,
      vehicleColor: pt.vehicleColor.isNotEmpty
          ? pt.vehicleColor
          : base.vehicleColor,
      vehicleType: pt.vehicleType.isNotEmpty
          ? pt.vehicleType
          : base.vehicleType,
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
      parkingInfo: base.parkingInfo,
      paymentSummaryJson: base.paymentSummaryJson,
      slotId: base.slotId,
      vrNo: base.vrNo,
      isOvernight: base.isOvernight,
      ticketLost: base.ticketLost,
      appliedRateJson: base.appliedRateJson,
      voidReason: base.voidReason,
      voidedByJson: base.voidedByJson,
      voidedAt: base.voidedAt,
      pendingVoidRequest: base.pendingVoidRequest,
      pendingVoidReason: base.pendingVoidReason,
      isExpressCashier: base.isExpressCashier,
    );
  }

  Future<Ticket?> _minimalTicketFromPreview(
    CheckoutPreviewResponse preview,
  ) async {
    final session = await _auth.getActiveSession();
    if (session == null) return null;
    final site = await _auth.branchAndAreaFromDb();
    final shift = await _auth.getOpenShiftForUser(session.userId);
    final pt = preview.ticket;
    final ticketId = pt.ticketNumber.isNotEmpty
        ? pt.ticketNumber
        : 'TKT-UNKNOWN';
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
      pendingVoidRequest: false,
      isExpressCashier: false,
    );
  }

  Future<CheckoutPreviewResponse> _fetchCheckoutPreview(
    String lookupKey,
  ) async {
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

  /// Server UUID when synced; otherwise local ticket id (e.g. `TKT-…`).
  String _previewLookupKeyForTicket(Ticket ticket) {
    final sid = ticket.serverTicketId?.trim() ?? '';
    if (sid.isNotEmpty) return sid;
    return ticket.id;
  }

  Future<CheckoutPreviewResponse?> _tryCheckoutPreviewLookup(
    String lookupKey,
  ) async {
    try {
      return await _fetchCheckoutPreview(lookupKey);
    } on TicketNotFoundException {
      return null;
    }
  }

  /// Resolves an active transaction UUID via reports search when not on Drift.
  Future<String?> _resolveServerTransactionIdByPlate(String plate) async {
    final session = await _auth.getActiveSession();
    final token = session?.authToken;
    if (token == null || token.isEmpty) return null;
    final normalized = normalizePlateNumber(plate).toUpperCase();
    if (normalized.isEmpty) return null;
    try {
      final page = await _transactionsApi.fetchReportsTransactions(
        token: token,
        search: normalized,
        status: 'active',
        limit: 20,
        page: 1,
      );
      for (final row in page.rows) {
        final rowPlate = normalizePlateNumber(
          row.plate == '—' ? '' : row.plate,
        ).toUpperCase();
        if (rowPlate != normalized) continue;
        final sid = row.serverTransactionId?.trim() ?? '';
        if (sid.isNotEmpty) return sid;
      }
    } catch (e, st) {
      ValetLog.error(
        'CheckOutCubit._resolveServerTransactionIdByPlate',
        'reports search failed',
        e,
        st,
      );
    }
    return null;
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
      state.copyWith(checkoutAddedDamage: [...state.checkoutAddedDamage, e]),
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
    if (state.isSelfPark) {
      if (state.driverOut != null) {
        emit(state.copyWith(driverOut: null));
      }
      return;
    }
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
      ValetLog.debug(
        'CheckOutCubit.lookupByTicketCode',
        'lookupKey=$lookupKey',
      );

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
          final local =
              await _tickets.activeTicketByTicketNumber(ticketNumber) ??
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
          final local =
              await _tickets.activeTicketByTicketNumber(lookupKey) ??
              await _tickets.activeTicketByTicketNumber(code);
          if (local != null &&
              await _tryDriftCheckoutFallback(
                ticket: local,
                previewError: _previewApiFallbackMessage,
              )) {
            return;
          }
          emit(
            state.copyWith(
              scanError: e.message,
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        } catch (e, st) {
          ValetLog.error(
            'CheckOutCubit.lookupByTicketCode',
            'checkout-preview failed',
            e,
            st,
          );
          final local =
              await _tickets.activeTicketByTicketNumber(lookupKey) ??
              await _tickets.activeTicketByTicketNumber(code);
          if (local != null &&
              await _tryDriftCheckoutFallback(
                ticket: local,
                previewError: _previewApiFallbackMessage,
              )) {
            return;
          }
          emit(
            state.copyWith(
              scanError: 'Could not load preview. Try again.',
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        }
      }

      final vt =
          await _tickets.activeTicketByTicketNumber(lookupKey) ??
          await _tickets.activeTicketByTicketNumber(code);
      if (vt != null) {
        _beginDriftCheckout(vt, previewError: _offlinePreviewMessage);
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
      final local = await _tickets.activeTicketByPlate(plate);

      if (await InternetReachability.hasInternet()) {
        try {
          final lookupKeys = <String>{
            if (local != null) _previewLookupKeyForTicket(local),
            plate,
          };
          final serverId = await _resolveServerTransactionIdByPlate(plate);
          if (serverId != null && serverId.isNotEmpty) {
            lookupKeys.add(serverId);
          }

          CheckoutPreviewResponse? preview;
          for (final key in lookupKeys) {
            ValetLog.info(
              'CheckOutCubit.lookupByPlate',
              'GET checkout-preview/$key',
            );
            preview = await _tryCheckoutPreviewLookup(key);
            if (preview != null) break;
          }

          if (preview != null) {
            if (isClosed) return;
            final tn = preview.ticket.ticketNumber;
            final byTicket = tn.isNotEmpty
                ? await _tickets.activeTicketByTicketNumber(tn)
                : null;
            final base = local ?? byTicket;
            final ticket = base != null
                ? _mergeTicketWithPreview(base, preview)
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
          }

          if (local != null &&
              await _tryDriftCheckoutFallback(
                ticket: local,
                previewError: _previewApiFallbackMessage,
              )) {
            return;
          }

          emit(
            state.copyWith(
              scanError:
                  'Ticket not found. Try scanning the QR code or entering the ticket number instead.',
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
          if (local != null &&
              await _tryDriftCheckoutFallback(
                ticket: local,
                previewError: _previewApiFallbackMessage,
              )) {
            return;
          }
          emit(
            state.copyWith(
              scanError: e.message,
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        } catch (e, st) {
          ValetLog.error(
            'CheckOutCubit.lookupByPlate',
            'checkout-preview failed',
            e,
            st,
          );
          if (local != null &&
              await _tryDriftCheckoutFallback(
                ticket: local,
                previewError: _previewApiFallbackMessage,
              )) {
            return;
          }
          emit(
            state.copyWith(
              scanError: 'Could not load preview. Try again.',
              isLookupBusy: false,
              isLoadingPreview: false,
            ),
          );
          return;
        }
      }

      if (local != null) {
        _beginDriftCheckout(local, previewError: _offlinePreviewMessage);
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

  CheckoutPreviewRates _effectivePreviewRates(CheckoutPreviewRates preview) =>
      CheckoutRateResolution.effectiveRates(
        preview: preview,
        drift: state.rates,
        driftFlatHours: state.flatBlockHours,
        driftOvernightStart: state.overnightStart,
        driftOvernightEnd: state.overnightEnd,
      );

  /// Fee lines: checkout-preview `rates` when online preview includes them;
  /// when preview parking fees are zero, full Drift row from rates sync.
  void _recomputeBreakdown() {
    final t = state.ticket;
    if (t == null) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }
    final checkInRaw = t.checkInAt.trim();
    if (checkInRaw.isEmpty) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }

    final window = CheckoutPricing.pricingWindow(checkInRaw: checkInRaw);
    final previewRates = state.preview?.rates;

    if (previewRates != null) {
      final effective = _effectivePreviewRates(previewRates);
      final overnight = CheckoutPricing.mergeOvernightTimes(
        previewStart: effective.overnightStart,
        previewEnd: effective.overnightEnd,
        cachedStart: state.overnightStart,
        cachedEnd: state.overnightEnd,
      );
      final flatHours = effective.flatRateHours > 0
          ? effective.flatRateHours
          : state.flatBlockHours;
      final effectivePreview = CheckoutPreviewRates(
        flatRate: effective.flatRate,
        succeedingRate: effective.succeedingRate,
        overnightFee: effective.overnightFee,
        lostTicketFee: effective.lostTicketFee,
        overnightStart: overnight.start,
        overnightEnd: overnight.end,
      );
      final b = CheckoutPricing.computeFromPreviewRates(
        timeIn: window.timeIn,
        timeOut: window.timeOut,
        rates: effectivePreview,
        flatBlockHours: flatHours,
      );
      emit(
        state.copyWith(
          breakdown: b,
          flatBlockHours: flatHours,
          rates: StandardParkingRates(
            flatRatePesos: effective.flatRate.round(),
            succeedingHourPesos: effective.succeedingRate.round(),
            overnightFeePesos: effective.overnightFee.round(),
            lostTicketFeePesos: effective.lostTicketFee.round(),
          ),
          overnightStart: overnight.start,
          overnightEnd: overnight.end,
        ),
      );
      return;
    }

    final rates = state.rates;
    if (rates == null) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }
    final start = state.overnightStart.trim();
    final end = state.overnightEnd.trim();
    final b = CheckoutPricing.compute(
      timeIn: window.timeIn,
      timeOut: window.timeOut,
      rates: rates,
      flatBlockHours: state.flatBlockHours,
      overnightStart: start,
      overnightEnd: end,
    );
    emit(state.copyWith(breakdown: b));
  }

  void refreshBreakdown() => _recomputeBreakdown();

  /// Rates + window captured during payment (preview or Drift).
  ({
    StandardParkingRates rates,
    int flatBlockHours,
    String overnightStart,
    String overnightEnd,
  })
  _ratesResolvedForReceipt() {
    final rates = state.rates ?? StandardParkingRates.offlineDefault;
    final start = state.overnightStart.trim();
    final end = state.overnightEnd.trim();
    return (
      rates: rates,
      flatBlockHours: state.flatBlockHours,
      overnightStart: start,
      overnightEnd: end,
    );
  }

  /// Same breakdown shown on payment — do not recompute from Drift at finalize.
  CheckoutBreakdown _breakdownForFinalize(Ticket ticket, int timeOutUnix) {
    final existing = state.breakdown;
    if (existing != null) return existing;

    final checkOut = PhilippineTime.fromUnixSeconds(timeOutUnix);
    final previewRates = state.preview?.rates;
    if (previewRates != null) {
      final effective = _effectivePreviewRates(previewRates);
      final window = CheckoutPricing.pricingWindow(
        checkInRaw: ticket.checkInAt,
      );
      final overnight = CheckoutPricing.mergeOvernightTimes(
        previewStart: effective.overnightStart,
        previewEnd: effective.overnightEnd,
        cachedStart: state.overnightStart,
        cachedEnd: state.overnightEnd,
      );
      final flatHours = effective.flatRateHours > 0
          ? effective.flatRateHours
          : state.flatBlockHours;
      return CheckoutPricing.computeFromPreviewRates(
        timeIn: window.timeIn,
        timeOut: checkOut,
        rates: CheckoutPreviewRates(
          flatRate: effective.flatRate,
          succeedingRate: effective.succeedingRate,
          overnightFee: effective.overnightFee,
          lostTicketFee: effective.lostTicketFee,
          overnightStart: overnight.start,
          overnightEnd: overnight.end,
        ),
        flatBlockHours: flatHours,
      );
    }

    final resolved = _ratesResolvedForReceipt();
    final window = CheckoutPricing.pricingWindow(checkInRaw: ticket.checkInAt);
    return CheckoutPricing.compute(
      timeIn: window.timeIn,
      timeOut: checkOut,
      rates: resolved.rates,
      flatBlockHours: resolved.flatBlockHours,
      overnightStart: resolved.overnightStart,
      overnightEnd: resolved.overnightEnd,
    );
  }

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

  Map<String, dynamic> _buildAppliedRate() {
    final pr = state.preview?.rates;
    if (pr != null) {
      final effective = _effectivePreviewRates(pr);
      return {
        'flat_rate': effective.flatRate,
        'flat_rate_hours': effective.flatRateHours > 0
            ? effective.flatRateHours
            : state.flatBlockHours,
        'succeeding_rate': effective.succeedingRate,
        'overnight_fee': effective.overnightFee,
        'lost_ticket_fee': effective.lostTicketFee,
        'overnight_start_time': effective.overnightStart,
        'overnight_end_time': effective.overnightEnd,
      };
    }
    final r = state.rates;
    return {
      'flat_rate': r?.flatRatePesos ?? 0,
      'flat_rate_hours': state.flatBlockHours,
      'succeeding_rate': r?.succeedingHourPesos ?? 0,
      'overnight_fee': r?.overnightFeePesos ?? 0,
      'lost_ticket_fee': r?.lostTicketFeePesos ?? 0,
      'overnight_start_time': state.overnightStart,
      'overnight_end_time': state.overnightEnd,
    };
  }

  int _flatHoursFromAppliedRate(Map<String, dynamic> applied) =>
      BranchRatesSnapshot.flatHoursFromMap(applied);

  Future<void> _enqueueOfflineCheckoutFinalize({
    required String ticketId,
    required String? serverTicketId,
    required double amount,
    required String timeOutIso,
    required List<Map<String, dynamic>> conditionBody,
    required bool isOvernight,
    required bool ticketLost,
    required double cashTendered,
  }) async {
    final appliedRate = _buildAppliedRate();
    await _tickets.enqueueCheckoutFinalize(
      ticketId: ticketId,
      serverTicketId: serverTicketId,
      amount: amount,
      timeOut: timeOutIso,
      isOvernight: isOvernight,
      ticketLost: ticketLost,
      driverOut: state.driverOut,
      conditionCheckout: conditionBody,
      cashTendered: cashTendered,
      appliedRate: appliedRate,
    );
    await _tickets.persistCheckoutMetadata(
      ticketId: ticketId,
      isOvernight: isOvernight,
      ticketLost: ticketLost,
      appliedRate: appliedRate,
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
    var receiptTendered = tendered;
    var receiptChange = change;
    // One checkout instant for API, Drift, receipt snapshot, and summary UI.
    final checkoutUtc = PhilippineTime.utcNow();
    final timeOutUnix = PhilippineTime.unixSecondsUtc(checkoutUtc);
    final timeOutApiIso = PhilippineTime.apiIsoInstant(checkoutUtc);
    final checkOutWallIso = PhilippineTime.formatIso(
      PhilippineTime.fromUtc(checkoutUtc),
    );
    final merged = [...state.checkInDamage, ...state.checkoutAddedDamage];
    final markersJson = encodeTicketDamageMarkersForCheckout(merged);
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
            final appliedRate = _buildAppliedRate();
            final driverOut = state.driverOut?.trim();
            if (driverOut != null && driverOut.isNotEmpty) {
              await _transactionsApi.patchTransactionDrivers(
                token: token,
                ticketId: pathId,
                driverOut: driverOut,
              );
            }
            response = await _transactionsApi.submitCheckOut(
              token: token,
              ticketId: pathId,
              amount: total,
              timeOut: timeOutApiIso,
              isOvernight: isOvernight,
              ticketLost: ticketLost,
              cashTendered: tendered,
              conditionCheckout: conditionBody,
              appliedRate: appliedRate,
            );
            await _tickets.persistCheckoutMetadata(
              ticketId: t.id,
              isOvernight: isOvernight,
              ticketLost: ticketLost,
              appliedRate: appliedRate,
            );
            invoice = response.invoiceNumber;
            // Amount collected stays what the POS computed and tendered against.
            serverTotal = total;
            if (response.cashTendered != null) {
              receiptTendered = response.cashTendered!;
            }
            receiptChange =
                TransactionPaymentCalculator.computedChange(
                  amount: serverTotal.toDouble(),
                  cashTendered: receiptTendered,
                ) ??
                receiptChange;
          } on SocketException {
            if (state.isLostTicket) {
              emit(state.copyWith(isSubmitting: false));
              return 'Lost ticket checkout requires an internet connection.';
            }
            await _enqueueOfflineCheckoutFinalize(
              ticketId: t.id,
              serverTicketId: pathId,
              amount: total,
              timeOutIso: timeOutApiIso,
              conditionBody: conditionBody,
              isOvernight: isOvernight,
              ticketLost: ticketLost,
              cashTendered: tendered,
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
                timeOutIso: timeOutApiIso,
                conditionBody: conditionBody,
                isOvernight: isOvernight,
                ticketLost: ticketLost,
                cashTendered: tendered,
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
            timeOutIso: timeOutApiIso,
            conditionBody: conditionBody,
            isOvernight: isOvernight,
            ticketLost: ticketLost,
            cashTendered: tendered,
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
          timeOutIso: timeOutApiIso,
          conditionBody: conditionBody,
          isOvernight: isOvernight,
          ticketLost: ticketLost,
          cashTendered: tendered,
        );
      }

      final breakdown = _breakdownForFinalize(t, timeOutUnix);
      final ratesRow = _ratesResolvedForReceipt();
      final appliedRateMap = _buildAppliedRate();
      final appliedFlatHours = _flatHoursFromAppliedRate(appliedRateMap);
      final flatBlockHours = appliedFlatHours > 0
          ? appliedFlatHours
          : ratesRow.flatBlockHours;
      final resolved = (
        rates: ratesRow.rates,
        flatBlockHours: flatBlockHours,
        overnightStart: ratesRow.overnightStart,
        overnightEnd: ratesRow.overnightEnd,
      );
      final chargedTotal = total.toDouble();
      receiptChange =
          TransactionPaymentCalculator.computedChange(
            amount: chargedTotal,
            cashTendered: receiptTendered,
          ) ??
          receiptChange;

      final paymentSummary = TransactionPaymentCalculator(_rates)
          .fromCheckoutBreakdown(
            breakdown: breakdown,
            rates: resolved,
            totalDue: chargedTotal,
            cashTendered: receiptTendered,
            isLostTicket: state.isLostTicket,
          );

      await _tickets.completeTicketCheckout(
        ticketId: t.id,
        checkOutAtIso: checkOutWallIso,
        totalFee: chargedTotal,
        damageMarkersJson: markersJson,
        driverOut: driverOut,
        status: state.isLostTicket ? 'lost' : 'completed',
        paymentSummary: paymentSummary,
        syncedToServer: response != null,
      );

      final preview = state.preview;
      final pt = preview?.ticket;
      final snap = CheckoutReceiptSnapshot.fromCheckoutFinalize(
        localTicketId: t.id,
        ticket: t,
        breakdown: breakdown,
        flatBlockHours: resolved.flatBlockHours,
        totalPesos: chargedTotal,
        tendered: receiptTendered,
        change: receiptChange,
        timeOutUnix: timeOutUnix,
        invoiceNumber: invoice,
        branchName: state.branchName,
        plateNumber: pt?.plate.isNotEmpty == true ? pt!.plate : null,
        vehicleReceiptLine: pt?.vehicleReceiptLine,
        slotLine: pt?.parkingLocationLine.isNotEmpty == true
            ? pt!.parkingLocationLine
            : null,
        valetIn: state.isSelfPark
            ? null
            : (pt?.valetIn ?? state.driverIn),
        valetOut: state.isSelfPark ? null : state.driverOut,
        valetTypeLabel: ValetTypeFormat.labelIfPresent(
          preview?.valetType ??
              ValetTypeFormat.fromDriverOutMeta(t.driverOut),
        ),
        overnightStart: resolved.overnightStart,
        overnightEnd: resolved.overnightEnd,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          serverTotal: chargedTotal,
          invoiceNumber: invoice,
          checkOutResponse: response,
          receiptTicket: t.id,
          receiptTotalPesos: chargedTotal,
          receiptChangePesos: receiptChange,
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
    } on TicketVoidPendingException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          checkoutBlockMessage: e.message,
        ),
      );
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
