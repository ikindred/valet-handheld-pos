import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../domain/ticket_number_generator.dart';
import '../domain/vehicle_body_type.dart';

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
    ];
  }
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit() : super(const CheckInState());

  /// Ensures a ticket number exists for this check-in session (idempotent).
  void ensureTicket() {
    if (state.ticketNumber.isNotEmpty) return;
    emit(state.copyWith(ticketNumber: TicketNumberGenerator.generateLocal()));
  }

  void resetSession() {
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
}
