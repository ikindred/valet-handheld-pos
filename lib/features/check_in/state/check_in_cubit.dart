import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../domain/ticket_number_generator.dart';

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
  });

  final String ticketNumber;
  final String customerFullName;
  final String contactNumber;
  final String assignedValetDriver;
  final String specialInstructions;
  final DateTime? dateTimeIn;
  final ValetServiceType valetServiceType;

  CheckInState copyWith({
    String? ticketNumber,
    String? customerFullName,
    String? contactNumber,
    String? assignedValetDriver,
    String? specialInstructions,
    DateTime? dateTimeIn,
    ValetServiceType? valetServiceType,
  }) {
    return CheckInState(
      ticketNumber: ticketNumber ?? this.ticketNumber,
      customerFullName: customerFullName ?? this.customerFullName,
      contactNumber: contactNumber ?? this.contactNumber,
      assignedValetDriver: assignedValetDriver ?? this.assignedValetDriver,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      dateTimeIn: dateTimeIn ?? this.dateTimeIn,
      valetServiceType: valetServiceType ?? this.valetServiceType,
    );
  }

  @override
  List<Object?> get props => [
    ticketNumber,
    customerFullName,
    contactNumber,
    assignedValetDriver,
    specialInstructions,
    dateTimeIn,
    valetServiceType,
  ];
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
}
