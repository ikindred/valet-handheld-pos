import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text;

import '../../../core/ui/app_alert_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/formatting/plate_number.dart';
import '../../../core/printing/check_in_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/time/unix_timestamp.dart';
import '../../../data/remote/api_error_message.dart';
import '../../../data/remote/check_in_exceptions.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/check_in_sync_payload.dart';
import '../../../data/services/shift_service.dart';
import '../../../data/services/ticket_service.dart';
import '../domain/check_in_demo_defaults.dart';
import '../domain/check_in_validation.dart';
import '../models/receipt_part.dart';
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
    this.vehicleBrand = '',
    this.vehicleColor = '',
    this.vehicleVrNo = '',
    this.vehicleBodyType = VehicleBodyType.sedan,
    this.parkingLevel = '',
    this.parkingSlot = '',
    this.parkingSlotId = '',
    this.selectedBelongings = const [],
    this.otherBelongings = '',
    this.selectedDamageType = DamageType.dent,
    this.vehicleDamageEntries = const [],
    this.hasCustomerSignature = false,
    this.signaturePng,
    this.signatureCapturedAt,
    this.receiptParts = initialReceiptParts,
    this.serverTicketId,
    this.qrCode,
    this.isSubmitting = false,
  });

  final String ticketNumber;
  final String customerFullName;
  final String contactNumber;
  final String assignedValetDriver;
  final String specialInstructions;
  final DateTime? dateTimeIn;
  final ValetServiceType valetServiceType;

  final String plateNumber;
  final String vehicleBrand;
  final String vehicleColor;
  final String vehicleVrNo;
  final VehicleBodyType vehicleBodyType;

  final String parkingLevel;
  final String parkingSlot;

  /// Parking slot UUID from area detail (`levels[].slots[].id`) for `POST /transactions/check-in`.
  final String parkingSlotId;

  /// Toggle keys for the belongings grid (e.g. laptop, cellphone).
  final List<String> selectedBelongings;
  final String otherBelongings;

  /// Active damage type for the next tap on the vehicle diagram.
  final DamageType selectedDamageType;

  /// Logged damage markers (normalized coordinates on the car bitmap).
  final List<VehicleDamageEntry> vehicleDamageEntries;

  /// Legacy flag; prefer [isCustomerSignatureComplete] (requires [signaturePng]).
  final bool hasCustomerSignature;

  /// PNG bytes from the signature pad (for local DB / sync).
  final Uint8List? signaturePng;

  /// True only when the customer signed on step 4 (PNG bytes present).
  bool get isCustomerSignatureComplete =>
      signaturePng != null && signaturePng!.isNotEmpty;

  /// Unix seconds when [signaturePng] was captured.
  final int? signatureCapturedAt;

  final List<ReceiptPartState> receiptParts;

  final String? serverTicketId;
  final String? qrCode;
  final bool isSubmitting;

  bool get allPartsPrinted =>
      receiptParts.every((p) => p.status == ReceiptPartStatus.printed);

  CheckInState copyWith({
    String? ticketNumber,
    String? customerFullName,
    String? contactNumber,
    String? assignedValetDriver,
    String? specialInstructions,
    DateTime? dateTimeIn,
    ValetServiceType? valetServiceType,
    String? plateNumber,
    String? vehicleBrand,
    String? vehicleColor,
    String? vehicleVrNo,
    VehicleBodyType? vehicleBodyType,
    String? parkingLevel,
    String? parkingSlot,
    String? parkingSlotId,
    List<String>? selectedBelongings,
    String? otherBelongings,
    DamageType? selectedDamageType,
    List<VehicleDamageEntry>? vehicleDamageEntries,
    bool? hasCustomerSignature,
    Uint8List? signaturePng,
    int? signatureCapturedAt,
    List<ReceiptPartState>? receiptParts,
    String? serverTicketId,
    String? qrCode,
    bool? isSubmitting,
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
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleVrNo: vehicleVrNo ?? this.vehicleVrNo,
      vehicleBodyType: vehicleBodyType ?? this.vehicleBodyType,
      parkingLevel: parkingLevel ?? this.parkingLevel,
      parkingSlot: parkingSlot ?? this.parkingSlot,
      parkingSlotId: parkingSlotId ?? this.parkingSlotId,
      selectedBelongings: selectedBelongings ?? this.selectedBelongings,
      otherBelongings: otherBelongings ?? this.otherBelongings,
      selectedDamageType: selectedDamageType ?? this.selectedDamageType,
      vehicleDamageEntries: vehicleDamageEntries ?? this.vehicleDamageEntries,
      hasCustomerSignature: hasCustomerSignature ?? this.hasCustomerSignature,
      signaturePng: signaturePng ?? this.signaturePng,
      signatureCapturedAt:
          signatureCapturedAt ?? this.signatureCapturedAt,
      receiptParts: receiptParts ?? this.receiptParts,
      serverTicketId: serverTicketId ?? this.serverTicketId,
      qrCode: qrCode ?? this.qrCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
      vehicleBrand,
      vehicleColor,
      vehicleVrNo,
      vehicleBodyType,
      parkingLevel,
      parkingSlot,
      parkingSlotId,
      b.join('|'),
      otherBelongings,
      selectedDamageType,
      vehicleDamageEntries,
      hasCustomerSignature,
      signaturePng,
      signatureCapturedAt,
      receiptParts,
      serverTicketId,
      qrCode,
      isSubmitting,
    ];
  }
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit({
    TicketService? ticketService,
    AuthRepository? authRepository,
    ShiftService? shiftService,
    TransactionsApi? transactionsApi,
  })  : _ticketService = ticketService,
        _authRepository = authRepository,
        _shiftService = shiftService,
        _transactionsApi = transactionsApi,
        super(
          CheckInDemoDefaults.enabled
              ? CheckInDemoDefaults.initial()
              : const CheckInState(),
        );

  static const _uuid = Uuid();

  final TicketService? _ticketService;
  final AuthRepository? _authRepository;
  final ShiftService? _shiftService;
  final TransactionsApi? _transactionsApi;

  bool _draftReservationInFlight = false;
  Completer<void>? _draftReservationCompleter;

  int get nextPartToPrint {
    final next = state.receiptParts.firstWhere(
      (p) => p.status != ReceiptPartStatus.printed,
      orElse: () => const ReceiptPartState(
        part: 0,
        label: '',
        status: ReceiptPartStatus.printed,
      ),
    );
    return next.part;
  }

  Future<void> printPart(
    BuildContext context,
    int part,
    CheckInReceiptData data,
  ) async {
    if (part != nextPartToPrint) return;
    _updatePartStatus(part, ReceiptPartStatus.printing);
    final ok = await printCheckInPartFromContext(
      context,
      data: data,
      part: part,
    );
    _updatePartStatus(
      part,
      ok ? ReceiptPartStatus.printed : ReceiptPartStatus.failed,
    );
  }

  Future<void> reprintPart(
    BuildContext context,
    int part,
    CheckInReceiptData data,
  ) async {
    if (part < 1 || part > state.receiptParts.length) return;
    final current = state.receiptParts[part - 1];
    if (current.status != ReceiptPartStatus.printed &&
        current.status != ReceiptPartStatus.failed) {
      return;
    }
    final preceding = state.receiptParts.take(part - 1);
    if (preceding.any((p) => p.status != ReceiptPartStatus.printed)) {
      return;
    }
    _updatePartStatus(part, ReceiptPartStatus.printing);
    final ok = await printCheckInPartFromContext(
      context,
      data: data,
      part: part,
    );
    _updatePartStatus(
      part,
      ok ? ReceiptPartStatus.printed : ReceiptPartStatus.failed,
    );
  }

  void _updatePartStatus(int part, ReceiptPartStatus status) {
    final updated = state.receiptParts
        .map((p) => p.part == part ? p.copyWith(status: status) : p)
        .toList();
    emit(state.copyWith(receiptParts: updated));
  }

  /// Clears session state and awaits a new draft ticket id before check-in UI opens.
  Future<bool> prepareNewCheckInSession() async {
    resetSession();
    return _reserveDraftWithRetry();
  }

  /// Reserves a draft `tickets` row (see [TicketService.createDraftTicket]).
  /// Returns true when [CheckInState.ticketNumber] is set.
  Future<bool> ensureDraftTicketReserved() async {
    if (state.ticketNumber.trim().isNotEmpty) return true;

    if (_draftReservationInFlight) {
      await (_draftReservationCompleter?.future ?? Future<void>.value());
      return state.ticketNumber.trim().isNotEmpty;
    }

    _draftReservationInFlight = true;
    final done = Completer<void>();
    _draftReservationCompleter = done;
    try {
      final ts = _ticketService;
      final auth = _authRepository;
      final shiftSvc = _shiftService;
      if (ts == null || auth == null || shiftSvc == null) return false;
      if (state.ticketNumber.trim().isNotEmpty) return true;
      final session = await auth.getActiveSession();
      if (session == null) return false;
      final userId = await shiftSvc.shiftUserIdForLocalAccount(session.userId);
      final shift = await shiftSvc.getActiveShift(userId);
      if (shift == null) return false;
      final site = await auth.branchAndAreaFromDb();
      try {
        final id = await ts.createDraftTicket(
          shiftId: shift.id,
          userId: userId,
          branchId: site.branch,
        );
        emit(state.copyWith(ticketNumber: id));
      } catch (_) {
        return false;
      }
      return state.ticketNumber.trim().isNotEmpty;
    } finally {
      _draftReservationInFlight = false;
      if (!done.isCompleted) done.complete();
      _draftReservationCompleter = null;
    }
  }

  Future<bool> _reserveDraftWithRetry() async {
    if (await ensureDraftTicketReserved()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ensureDraftTicketReserved();
  }

  /// Confirms check-in: signature file, local Drift, then multipart API (or queue offline).
  Future<void> confirmCheckIn(BuildContext context) async {
    final ts = _ticketService;
    final auth = _authRepository;
    final shiftSvc = _shiftService;
    final api = _transactionsApi;
    if (ts == null || auth == null || shiftSvc == null || api == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in services are not configured.')),
        );
      }
      return;
    }

    final sig = state.signaturePng;
    if (sig == null || sig.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer signature is required.')),
        );
      }
      return;
    }

    final ticketId = state.ticketNumber.trim();
    if (ticketId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ticket number yet.')),
        );
      }
      return;
    }

    final step2Error = CheckInValidation.validateStep2FromState(state);
    if (step2Error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(step2Error)),
        );
      }
      return;
    }

    final data = _buildFormData();

    emit(state.copyWith(isSubmitting: true));

    late final File sigFile;
    try {
      final session = await auth.getActiveSession();
      if (session == null) {
        emit(state.copyWith(isSubmitting: false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active session. Sign in again.')),
          );
        }
        return;
      }

      final userId = await shiftSvc.shiftUserIdForLocalAccount(session.userId);
      final shift = await shiftSvc.getActiveShift(userId);
      if (shift == null) {
        emit(state.copyWith(isSubmitting: false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open a cash shift before check-in.')),
          );
        }
        return;
      }

      final site = await auth.branchAndAreaFromDb();
      sigFile = await ts.saveSignatureToFile(sig, ticketId);
      final vehicle = _buildVehicleMap();
      final belongings = _belongingsList();
      final damages = _damageMaps();

      await ts.persistCheckInLocally(
        ticketId: ticketId,
        signaturePath: sigFile.path,
        shiftId: shift.id,
        userId: userId,
        branchId: site.branch,
        plateNumber: data.plateNumber,
        vehicleBrand: data.vehicleBrand,
        vehicleColor: data.vehicleColor,
        vehicleType: _vehicleTypeApi(state.vehicleBodyType),
        cellphoneNumber: data.cellphoneNumber,
        damageMarkersJson: data.damageMarkersJson,
        personalBelongingsJson: data.personalBelongingsJson,
        vrNo: state.vehicleVrNo,
        driverIn: data.driverIn,
        customerName: state.customerFullName.trim(),
        valetType: _valetTypeApi(state.valetServiceType),
        parkingLevel: state.parkingLevel.trim(),
        parkingSlot: state.parkingSlot.trim(),
        slotId: state.parkingSlotId.trim(),
      );

      final slotId = state.parkingSlotId.trim();
      if (slotId.isEmpty) {
        emit(state.copyWith(isSubmitting: false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select a parking slot on step 2 before check-in.'),
            ),
          );
        }
        return;
      }

      final token = session.authToken;
      if (token == null || token.isEmpty) {
        throw StateError('No bearer token.');
      }

      final vrNo = state.vehicleVrNo.trim();
      final response = await api.submitCheckIn(
        token: token,
        ticketNumber: ticketId,
        slotId: slotId,
        contactNumber: state.contactNumber.trim(),
        valetType: _valetTypeApi(state.valetServiceType),
        signatureFile: sigFile,
        vehicle: vehicle,
        belongings: belongings,
        damages: damages,
        customerName: state.customerFullName.trim(),
        driverIn: data.driverIn,
        notes: _optionalTrim(state.specialInstructions),
        vrNo: vrNo,
      );

      await ts.updateServerTicketId(ticketId, response.id);
      await ts.persistVrNo(ticketId, vrNo);

      emit(
        state.copyWith(
          isSubmitting: false,
          serverTicketId: response.id,
          qrCode: ticketId,
        ),
      );

      if (context.mounted) context.go('/check-in/print');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        await _enqueueCheckIn(
          ts: ts,
          ticketId: ticketId,
          signaturePath: sigFile.path,
        );
        emit(
          state.copyWith(
            isSubmitting: false,
            qrCode: ticketId,
          ),
        );
        if (context.mounted) context.go('/check-in/print');
        return;
      }
      emit(state.copyWith(isSubmitting: false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } on VehicleAlreadyCheckedInException catch (_) {
      emit(state.copyWith(isSubmitting: false));
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        title: 'Already checked in',
        message:
            'This vehicle is already checked in. Go to the dashboard or '
            'retrieve the existing ticket before starting a new check-in.',
        icon: AppAlertIcon.warning,
      );
    } on VrNumberAlreadyUsedException catch (_) {
      emit(state.copyWith(isSubmitting: false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This VR number is already in use.'),
          ),
        );
      }
    } on CheckInValidationException catch (e) {
      emit(state.copyWith(isSubmitting: false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on LoginApiFailure catch (e) {
      emit(state.copyWith(isSubmitting: false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      emit(state.copyWith(isSubmitting: false));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _enqueueCheckIn({
    required TicketService ts,
    required String ticketId,
    required String signaturePath,
  }) async {
    final payload = checkInSyncQueuePayload(
      localTicketId: ticketId,
      signaturePath: signaturePath,
      slotId: state.parkingSlotId.trim(),
      contactNumber: state.contactNumber.trim(),
      valetType: _valetTypeApi(state.valetServiceType),
      vehicle: _buildVehicleMap(),
      belongings: _belongingsList(),
      damages: _damageMaps(),
      customerName: _optionalTrim(state.customerFullName),
      driverIn: _optionalTrim(state.assignedValetDriver),
      notes: _optionalTrim(state.specialInstructions),
      vrNo: state.vehicleVrNo.trim(),
    );
    await ts.enqueueCheckInSync(localTicketId: ticketId, payload: payload);
  }

  /// Vehicle JSON for check-in API (`vr_no` is a separate top-level field).
  Map<String, dynamic> _buildVehicleMap() {
    return <String, dynamic>{
      'plate_number': normalizePlateNumber(state.plateNumber),
      'brand': state.vehicleBrand.trim(),
      'color': state.vehicleColor.trim(),
      'type': _vehicleTypeApi(state.vehicleBodyType),
    };
  }

  // ignore: unused_element
  Map<String, dynamic> _buildParkingMap() {
    final level = state.parkingLevel.trim();
    final slot = state.parkingSlot.trim();
    return <String, dynamic>{
      'level': level.isEmpty ? null : level,
      'slot': slot.isEmpty ? null : slot,
    };
  }

  List<String> _belongingsList() {
    final list = List<String>.from(state.selectedBelongings);
    final other = state.otherBelongings.trim();
    if (other.isNotEmpty) list.add('Other: $other');
    return list;
  }

  List<Map<String, dynamic>> _damageMaps() => [
        for (final e in state.vehicleDamageEntries)
          <String, dynamic>{
            'zone': e.zoneLabel ?? '',
            'type': e.type.name,
            'x': e.normalizedX,
            'y': e.normalizedY,
          },
      ];

  static String? _optionalTrim(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  static String _valetTypeApi(ValetServiceType t) => switch (t) {
        ValetServiceType.standardValet => 'standard_valet',
        ValetServiceType.selfPark => 'self_park',
      };

  static String _vehicleTypeApi(VehicleBodyType t) => switch (t) {
        VehicleBodyType.sedan => 'sedan',
        VehicleBodyType.suv => 'suv',
        VehicleBodyType.van => 'van',
        VehicleBodyType.luxury => 'luxury',
        VehicleBodyType.evPhev => 'ev_phev',
        VehicleBodyType.motorcycle => 'motorcycle',
      };

  CheckInFormData _buildFormData() {
    final belongings = List<String>.from(state.selectedBelongings);
    final other = state.otherBelongings.trim();
    if (other.isNotEmpty) belongings.add('Other: $other');
    final valet = state.assignedValetDriver.trim();
    return CheckInFormData(
      plateNumber: normalizePlateNumber(state.plateNumber),
      vehicleBrand: state.vehicleBrand.trim(),
      vehicleColor: state.vehicleColor.trim(),
      vehicleType: _vehicleTypeApi(state.vehicleBodyType),
      driverIn: state.valetServiceType == ValetServiceType.selfPark
          ? null
          : (valet.isEmpty ? null : valet),
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
    emit(
      CheckInDemoDefaults.enabled
          ? CheckInDemoDefaults.initial()
          : const CheckInState(receiptParts: initialReceiptParts),
    );
  }

  void updateCustomerStep({
    String? customerFullName,
    String? contactNumber,
    String? assignedValetDriver,
    String? specialInstructions,
    DateTime? dateTimeIn,
    ValetServiceType? valetServiceType,
  }) {
    final nextType = valetServiceType ?? state.valetServiceType;
    final selfPark = nextType == ValetServiceType.selfPark;
    emit(
      state.copyWith(
        customerFullName: customerFullName,
        contactNumber: contactNumber,
        assignedValetDriver: selfPark ? '' : assignedValetDriver,
        specialInstructions: specialInstructions,
        dateTimeIn: dateTimeIn,
        valetServiceType: valetServiceType,
      ),
    );
  }

  void updateVehicleStep({
    String? plateNumber,
    String? vehicleBrand,
    String? vehicleColor,
    String? vehicleVrNo,
    VehicleBodyType? vehicleBodyType,
    String? parkingLevel,
    String? parkingSlot,
    String? parkingSlotId,
    List<String>? selectedBelongings,
    String? otherBelongings,
  }) {
    emit(
      state.copyWith(
        plateNumber:
            plateNumber != null ? normalizePlateNumber(plateNumber) : null,
        vehicleBrand: vehicleBrand,
        vehicleColor: vehicleColor,
        vehicleVrNo: vehicleVrNo,
        vehicleBodyType: vehicleBodyType,
        parkingLevel: parkingLevel,
        parkingSlot: parkingSlot,
        parkingSlotId: parkingSlotId,
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
