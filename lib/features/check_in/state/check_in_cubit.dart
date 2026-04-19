import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../core/time/unix_timestamp.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/shift_service.dart';
import '../../../data/services/ticket_service.dart';
import '../domain/check_in_form_data.dart';
import '../domain/vehicle_body_type.dart';
import '../domain/vehicle_damage.dart';
import '../domain/vehicle_damage_zones.dart';

enum ValetServiceType { standardValet, selfPark }

class CheckInState extends Equatable {
  const CheckInState({
    this.ticketNumber = '',
    this.customerFullName = '',
    this.contactNumber = '',
    this.assignedValetDriver = '',
    this.specialInstructions = '',
    this.dateTimeIn,
    this.valetServiceType = ValetServiceType.standardValet,
    this.plateNumber = '',
    this.vehicleModel = '',
    this.vehicleBrandMake = '',
    this.vehicleColor = '',
    this.vehicleYear = '',
    this.vehicleBodyType = VehicleBodyType.sedan,
    this.parkingLevel = '',
    this.parkingSlot = '',
    this.selectedBelongings = const [],
    this.otherBelongings = '',
    this.selectedDamageType = DamageType.dent,
    this.vehicleDamageEntries = const [],
    this.hasCustomerSignature = false,
    this.signaturePng,
    this.signatureCapturedAt,
  });

  final String ticketNumber;
  final String customerFullName;
  final String contactNumber;
  final String assignedValetDriver;
  final String specialInstructions;
  final DateTime? dateTimeIn;
  final ValetServiceType valetServiceType;

  final String plateNumber;
  final String vehicleModel;
  final String vehicleBrandMake;
  final String vehicleColor;
  final String vehicleYear;
  final VehicleBodyType vehicleBodyType;

  final String parkingLevel;
  final String parkingSlot;

  /// Toggle keys for the belongings grid (e.g. laptop, cellphone).
  final List<String> selectedBelongings;
  final String otherBelongings;

  /// Active damage type for the next tap on the vehicle diagram.
  final DamageType selectedDamageType;

  /// Logged damage markers (normalized coordinates on the car bitmap).
  final List<VehicleDamageEntry> vehicleDamageEntries;

  /// True after the customer completes the signature step (step 4).
  final bool hasCustomerSignature;

  /// PNG bytes from the signature pad (for local DB / sync).
  final Uint8List? signaturePng;

  /// Unix seconds when [signaturePng] was captured.
  final int? signatureCapturedAt;

  CheckInState copyWith({
    String? ticketNumber,
    String? customerFullName,
    String? contactNumber,
    String? assignedValetDriver,
    String? specialInstructions,
    DateTime? dateTimeIn,
    ValetServiceType? valetServiceType,
    String? plateNumber,
    String? vehicleModel,
    String? vehicleBrandMake,
    String? vehicleColor,
    String? vehicleYear,
    VehicleBodyType? vehicleBodyType,
    String? parkingLevel,
    String? parkingSlot,
    List<String>? selectedBelongings,
    String? otherBelongings,
    DamageType? selectedDamageType,
    List<VehicleDamageEntry>? vehicleDamageEntries,
    bool? hasCustomerSignature,
    Uint8List? signaturePng,
    int? signatureCapturedAt,
  }) {
    return CheckInState(
      ticketNumber: ticketNumber ?? this.ticketNumber,
      customerFullName: customerFullName ?? this.customerFullName,
      contactNumber: contactNumber ?? this.contactNumber,
      assignedValetDriver: assignedValetDriver ?? this.assignedValetDriver,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      dateTimeIn: dateTimeIn ?? this.dateTimeIn,
      valetServiceType: valetServiceType ?? this.valetServiceType,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleBrandMake: vehicleBrandMake ?? this.vehicleBrandMake,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleBodyType: vehicleBodyType ?? this.vehicleBodyType,
      parkingLevel: parkingLevel ?? this.parkingLevel,
      parkingSlot: parkingSlot ?? this.parkingSlot,
      selectedBelongings: selectedBelongings ?? this.selectedBelongings,
      otherBelongings: otherBelongings ?? this.otherBelongings,
      selectedDamageType: selectedDamageType ?? this.selectedDamageType,
      vehicleDamageEntries: vehicleDamageEntries ?? this.vehicleDamageEntries,
      hasCustomerSignature: hasCustomerSignature ?? this.hasCustomerSignature,
      signaturePng: signaturePng ?? this.signaturePng,
      signatureCapturedAt:
          signatureCapturedAt ?? this.signatureCapturedAt,
    );
  }

  @override
  List<Object?> get props {
    final b = List<String>.from(selectedBelongings)..sort();
    return [
      ticketNumber,
      customerFullName,
      contactNumber,
      assignedValetDriver,
      specialInstructions,
      dateTimeIn,
      valetServiceType,
      plateNumber,
      vehicleModel,
      vehicleBrandMake,
      vehicleColor,
      vehicleYear,
      vehicleBodyType,
      parkingLevel,
      parkingSlot,
      b.join('|'),
      otherBelongings,
      selectedDamageType,
      vehicleDamageEntries,
      hasCustomerSignature,
      signaturePng,
      signatureCapturedAt,
    ];
  }
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit({
    TicketService? ticketService,
    AuthRepository? authRepository,
    ShiftService? shiftService,
  })  : _ticketService = ticketService,
        _authRepository = authRepository,
        _shiftService = shiftService,
        super(const CheckInState());

  static const _uuid = Uuid();

  final TicketService? _ticketService;
  final AuthRepository? _authRepository;
  final ShiftService? _shiftService;

  /// Reserves a sequential ticket id via a draft `tickets` row (see [TicketService.createDraftTicket]).
  /// Call when the check-in shell opens. Safe to call repeatedly while [CheckInState.ticketNumber] is empty.
  Future<void> ensureDraftTicketReserved() async {
    final ts = _ticketService;
    final auth = _authRepository;
    final shiftSvc = _shiftService;
    if (ts == null || auth == null || shiftSvc == null) return;
    if (state.ticketNumber.trim().isNotEmpty) return;
    final session = await auth.getActiveSession();
    if (session == null) return;
    final userId = await shiftSvc.shiftUserIdForLocalAccount(session.userId);
    final shift = await shiftSvc.getActiveShift(userId);
    if (shift == null) return;
    final site = await auth.branchAndAreaFromDb();
    try {
      final id = await ts.createDraftTicket(
        shiftId: shift.id,
        userId: userId,
        branchId: site.branch,
      );
      emit(state.copyWith(ticketNumber: id));
    } catch (_) {
      // Leave empty; header shows … until a draft can be created (e.g. shift opened).
    }
  }

  /// Persists `valet_tickets` + sync queue. Returns null on success, else error text.
  Future<String?> submitValetTicket() async {
    final ts = _ticketService;
    final auth = _authRepository;
    final shiftSvc = _shiftService;
    if (ts == null || auth == null || shiftSvc == null) {
      return 'Check-in services are not configured.';
    }
    final session = await auth.getActiveSession();
    if (session == null) return 'No active session.';
    final userId = await shiftSvc.shiftUserIdForLocalAccount(session.userId);
    final shift = await shiftSvc.getActiveShift(userId);
    if (shift == null) return 'Open a cash shift before check-in.';
    final site = await auth.branchAndAreaFromDb();
    final data = _buildFormData();
    if (!data.isComplete) {
      return 'Complete plate, brand, color, and cellphone.';
    }
    try {
      final existingId = state.ticketNumber.trim();
      if (existingId.isNotEmpty) {
        final row = await ts.ticketById(existingId);
        if (row != null && row.status == 'draft') {
          final ticket = await ts.finalizeDraftTicket(
            ticketId: existingId,
            data: data,
            shiftId: shift.id,
            userId: userId,
            branchId: site.branch,
          );
          emit(state.copyWith(ticketNumber: ticket.id));
          return null;
        }
      }
      final ticket = await ts.createTicket(
        data: data,
        shiftId: shift.id,
        userId: userId,
        branchId: site.branch,
      );
      emit(state.copyWith(ticketNumber: ticket.id));
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  CheckInFormData _buildFormData() {
    final belongings = List<String>.from(state.selectedBelongings);
    final other = state.otherBelongings.trim();
    if (other.isNotEmpty) belongings.add('Other: $other');
    final valet = state.assignedValetDriver.trim();
    return CheckInFormData(
      plateNumber: state.plateNumber.trim(),
      vehicleBrand: '${state.vehicleBrandMake} ${state.vehicleModel}'.trim(),
      vehicleColor: state.vehicleColor.trim(),
      vehicleType: '',
      driverIn: valet.isEmpty ? null : valet,
      cellphoneNumber: state.contactNumber.trim(),
      damageMarkersJson: _damageMarkersJson(state.vehicleDamageEntries),
      personalBelongingsJson: jsonEncode(belongings),
    );
  }

  static String _damageMarkersJson(List<VehicleDamageEntry> entries) =>
      jsonEncode([
        for (final e in entries)
          {
            'zone': e.zoneLabel ?? '',
            'type': e.type.name,
            'x': e.normalizedX,
            'y': e.normalizedY,
          },
      ]);

  void resetSession() {
    final id = state.ticketNumber.trim();
    if (id.isNotEmpty) {
      unawaited(_ticketService?.deleteDraftTicket(id) ?? Future.value());
    }
    emit(const CheckInState());
  }

  void updateCustomerStep({
    String? customerFullName,
    String? contactNumber,
    String? assignedValetDriver,
    String? specialInstructions,
    DateTime? dateTimeIn,
    ValetServiceType? valetServiceType,
  }) {
    emit(
      state.copyWith(
        customerFullName: customerFullName,
        contactNumber: contactNumber,
        assignedValetDriver: assignedValetDriver,
        specialInstructions: specialInstructions,
        dateTimeIn: dateTimeIn,
        valetServiceType: valetServiceType,
      ),
    );
  }

  void updateVehicleStep({
    String? plateNumber,
    String? vehicleModel,
    String? vehicleBrandMake,
    String? vehicleColor,
    String? vehicleYear,
    VehicleBodyType? vehicleBodyType,
    String? parkingLevel,
    String? parkingSlot,
    List<String>? selectedBelongings,
    String? otherBelongings,
  }) {
    emit(
      state.copyWith(
        plateNumber: plateNumber,
        vehicleModel: vehicleModel,
        vehicleBrandMake: vehicleBrandMake,
        vehicleColor: vehicleColor,
        vehicleYear: vehicleYear,
        vehicleBodyType: vehicleBodyType,
        parkingLevel: parkingLevel,
        parkingSlot: parkingSlot,
        selectedBelongings: selectedBelongings,
        otherBelongings: otherBelongings,
      ),
    );
  }

  void selectDamageType(DamageType type) {
    emit(state.copyWith(selectedDamageType: type));
  }

  /// Adds a damage entry at normalized coordinates \[0, 1\] using [CheckInState.selectedDamageType].
  void addDamageAt(double normalizedX, double normalizedY) {
    final type = state.selectedDamageType;
    final zone = lookupVehicleZoneLabel(normalizedX, normalizedY);
    final entry = VehicleDamageEntry(
      id: _uuid.v4(),
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      type: type,
      zoneLabel: zone,
    );
    emit(
      state.copyWith(
        vehicleDamageEntries: [...state.vehicleDamageEntries, entry],
      ),
    );
  }

  void removeDamage(String id) {
    emit(
      state.copyWith(
        vehicleDamageEntries: [
          for (final e in state.vehicleDamageEntries)
            if (e.id != id) e,
        ],
      ),
    );
  }

  /// Removes all logged damage markers for this check-in session.
  void clearLoggedDamage() {
    emit(state.copyWith(vehicleDamageEntries: const []));
  }

  void setCustomerSignatureCaptured(Uint8List pngBytes) {
    emit(
      state.copyWith(
        hasCustomerSignature: true,
        signaturePng: pngBytes,
        signatureCapturedAt: unixNowSeconds(),
      ),
    );
  }
}
