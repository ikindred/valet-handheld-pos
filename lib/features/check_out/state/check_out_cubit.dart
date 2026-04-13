import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/session/standard_parking_rates.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/rate_service.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../domain/checkout_pricing.dart';
import '../domain/checkout_receipt_snapshot.dart';
import '../domain/ticket_damage_markers.dart';

class CheckOutState extends Equatable {
  const CheckOutState({
    this.ticket,
    this.checkInDamage = const [],
    this.checkoutAddedDamage = const [],
    this.checkoutExitIssueSignatureAcknowledged = false,
    this.selectedDamageType = DamageType.dent,
    this.rates,
    this.breakdown,
    this.amountTenderedInput = '',
    this.scanError = '',
    this.isLookupBusy = false,
    this.flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
    this.receiptTicket,
    this.receiptTotalPesos,
    this.receiptChangePesos,
    this.receiptSnapshot,
  });

  final Ticket? ticket;
  final List<VehicleDamageEntry> checkInDamage;
  final List<VehicleDamageEntry> checkoutAddedDamage;

  /// True after the add-issue flow captured a customer signature while [checkoutAddedDamage] is non-empty.
  final bool checkoutExitIssueSignatureAcknowledged;
  final DamageType selectedDamageType;
  final StandardParkingRates? rates;
  final CheckoutBreakdown? breakdown;
  final String amountTenderedInput;
  final String scanError;
  final bool isLookupBusy;

  /// From `rates.flat_rate_hours` when resolved; otherwise [CheckoutPricing.defaultFlatBlockHours].
  final int flatBlockHours;

  /// Filled after a successful [CheckOutCubit.finalizeIfValid] for the receipt step.
  final String? receiptTicket;
  final double? receiptTotalPesos;
  final double? receiptChangePesos;
  final CheckoutReceiptSnapshot? receiptSnapshot;

  List<VehicleDamageEntry> get diagramEntries => [
        ...checkInDamage,
        ...checkoutAddedDamage,
      ];

  CheckOutState copyWith({
    Ticket? ticket,
    List<VehicleDamageEntry>? checkInDamage,
    List<VehicleDamageEntry>? checkoutAddedDamage,
    bool? checkoutExitIssueSignatureAcknowledged,
    DamageType? selectedDamageType,
    StandardParkingRates? rates,
    CheckoutBreakdown? breakdown,
    bool clearBreakdown = false,
    String? amountTenderedInput,
    String? scanError,
    bool? isLookupBusy,
    int? flatBlockHours,
    String? receiptTicket,
    double? receiptTotalPesos,
    double? receiptChangePesos,
    CheckoutReceiptSnapshot? receiptSnapshot,
    bool clearReceipt = false,
  }) {
    return CheckOutState(
      ticket: ticket ?? this.ticket,
      checkInDamage: checkInDamage ?? this.checkInDamage,
      checkoutAddedDamage: checkoutAddedDamage ?? this.checkoutAddedDamage,
      checkoutExitIssueSignatureAcknowledged:
          checkoutExitIssueSignatureAcknowledged ??
              this.checkoutExitIssueSignatureAcknowledged,
      selectedDamageType: selectedDamageType ?? this.selectedDamageType,
      rates: rates ?? this.rates,
      breakdown: clearBreakdown ? null : (breakdown ?? this.breakdown),
      amountTenderedInput: amountTenderedInput ?? this.amountTenderedInput,
      scanError: scanError ?? this.scanError,
      isLookupBusy: isLookupBusy ?? this.isLookupBusy,
      flatBlockHours: flatBlockHours ?? this.flatBlockHours,
      receiptTicket: clearReceipt ? null : (receiptTicket ?? this.receiptTicket),
      receiptTotalPesos:
          clearReceipt ? null : (receiptTotalPesos ?? this.receiptTotalPesos),
      receiptChangePesos:
          clearReceipt ? null : (receiptChangePesos ?? this.receiptChangePesos),
      receiptSnapshot:
          clearReceipt ? null : (receiptSnapshot ?? this.receiptSnapshot),
    );
  }

  @override
  List<Object?> get props => [
        ticket,
        checkInDamage,
        checkoutAddedDamage,
        checkoutExitIssueSignatureAcknowledged,
        selectedDamageType,
        rates,
        breakdown,
        amountTenderedInput,
        scanError,
        isLookupBusy,
        flatBlockHours,
        receiptTicket,
        receiptTotalPesos,
        receiptChangePesos,
        receiptSnapshot,
      ];
}

class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit(
    this._tickets,
    this._rates,
    this._auth,
  ) : super(const CheckOutState());

  final TicketService _tickets;
  final RateService _rates;
  final AuthRepository _auth;

  void reset() => emit(
        CheckOutState(
          rates: state.rates,
          flatBlockHours: CheckoutPricing.defaultFlatBlockHours,
        ),
      );

  void setRates(StandardParkingRates? rates) {
    emit(state.copyWith(rates: rates));
    _recomputeBreakdown();
  }

  /// After a ticket is loaded, prefer `rates` table (vehicle type + branch) over login defaults.
  Future<void> hydrateRatesFromDrift() async {
    final t = state.ticket;
    if (t == null) return;
    try {
      final site = await _auth.branchAndAreaFromDb();
      final vehicleType = t.vehicleType.trim();
      final resolved = await _rates.checkoutRatesResolved(
        branchId: site.branch,
        vehicleType: vehicleType.isEmpty ? null : vehicleType,
      );
      if (isClosed || resolved == null) return;
      emit(
        state.copyWith(
          rates: resolved.rates,
          flatBlockHours: resolved.flatBlockHours,
        ),
      );
      _recomputeBreakdown();
    } catch (_) {}
  }

  void beginFromTicket(Ticket t) {
    final checkIn = parseTicketDamageMarkersForCheckout(t.damageMarkers);
    emit(
      CheckOutState(
        rates: state.rates,
        flatBlockHours: state.flatBlockHours,
        ticket: t,
        checkInDamage: checkIn,
        checkoutAddedDamage: const [],
        checkoutExitIssueSignatureAcknowledged: false,
        selectedDamageType: DamageType.dent,
      ),
    );
    _recomputeBreakdown();
    unawaited(hydrateRatesFromDrift());
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
    emit(
      state.copyWith(
        checkoutAddedDamage: next,
        checkoutExitIssueSignatureAcknowledged:
            next.isEmpty ? false : state.checkoutExitIssueSignatureAcknowledged,
      ),
    );
  }

  void applyCheckoutIssueSession({
    required List<VehicleDamageEntry> damage,
    required bool signatureAcknowledged,
  }) {
    emit(
      state.copyWith(
        checkoutAddedDamage: damage,
        checkoutExitIssueSignatureAcknowledged:
            damage.isNotEmpty && signatureAcknowledged,
      ),
    );
  }

  void setAmountTenderedInput(String s) =>
      emit(state.copyWith(amountTenderedInput: s));

  Future<void> lookupByTicketCode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return;
    emit(state.copyWith(scanError: '', isLookupBusy: true));
    try {
      final ticket = _normalizeQrPayload(code);
      final vt = await _tickets.activeTicketByTicketNumber(ticket) ??
          await _tickets.activeTicketByTicketNumber(code);
      if (vt == null) {
        emit(
          state.copyWith(
            scanError: 'No open ticket found for that code.',
            isLookupBusy: false,
          ),
        );
        return;
      }
      beginFromTicket(vt);
      emit(state.copyWith(isLookupBusy: false));
    } catch (_) {
      emit(
        state.copyWith(
          scanError: 'Could not load ticket. Try again.',
          isLookupBusy: false,
        ),
      );
    }
  }

  Future<void> lookupByPlate(String raw) async {
    final plate = raw.trim();
    if (plate.isEmpty) return;
    emit(state.copyWith(scanError: '', isLookupBusy: true));
    try {
      final vt = await _tickets.activeTicketByPlate(plate);
      if (vt == null) {
        emit(
          state.copyWith(
            scanError: 'No open ticket found for that plate.',
            isLookupBusy: false,
          ),
        );
        return;
      }
      beginFromTicket(vt);
      emit(state.copyWith(isLookupBusy: false));
    } catch (_) {
      emit(
        state.copyWith(
          scanError: 'Lookup failed. Try again.',
          isLookupBusy: false,
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

  int _timeInUnixForTicket(Ticket t) {
    final parsed = DateTime.tryParse(t.checkInAt);
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch ~/ 1000;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void _recomputeBreakdown() {
    final t = state.ticket;
    final rates = state.rates;
    if (t == null || rates == null) {
      emit(state.copyWith(clearBreakdown: true));
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final b = CheckoutPricing.compute(
      timeInUnix: _timeInUnixForTicket(t),
      timeOutUnix: now,
      rates: rates,
      flatBlockHours: state.flatBlockHours,
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
    final b = state.breakdown;
    final t = parsedTendered();
    if (b == null || t == null) return null;
    return t - b.totalPesos;
  }

  /// Returns `null` on success, otherwise an error message.
  Future<String?> finalizeIfValid() async {
    final t = state.ticket;
    final b = state.breakdown;
    final rates = state.rates;
    if (t == null || b == null || rates == null) {
      return 'No ticket loaded.';
    }
    final tendered = parsedTendered();
    if (tendered == null) {
      return 'Enter amount received.';
    }
    if (tendered + 1e-6 < b.totalPesos) {
      return 'Amount is less than total due.';
    }
    final change = tendered - b.totalPesos;
    final timeOut = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final merged = [...state.checkInDamage, ...state.checkoutAddedDamage];
    final markersJson = encodeTicketDamageMarkersForCheckout(merged);
    final checkOutIso =
        DateTime.fromMillisecondsSinceEpoch(timeOut * 1000).toIso8601String();

    try {
      final fresh = await _tickets.ticketById(t.id);
      if (fresh == null) return 'Ticket not found.';
      if (fresh.status != 'active') {
        return 'This ticket is no longer active.';
      }
      await _tickets.completeTicketCheckout(
        ticketId: t.id,
        checkOutAtIso: checkOutIso,
        totalFee: b.totalPesos.toDouble(),
        damageMarkersJson: markersJson,
      );
      final snapshot = CheckoutReceiptSnapshot.capture(
        ticket: t,
        b: b,
        tendered: tendered,
        change: change,
        timeOutUnix: timeOut,
      );
      emit(
        CheckOutState(
          rates: state.rates,
          flatBlockHours: state.flatBlockHours,
          receiptTicket: t.id,
          receiptTotalPesos: b.totalPesos.toDouble(),
          receiptChangePesos: change,
          receiptSnapshot: snapshot,
        ),
      );
      return null;
    } catch (_) {
      return 'Save failed. Try again.';
    }
  }
}
