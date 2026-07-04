import 'package:equatable/equatable.dart';

import '../../../data/local/db/app_database.dart';

class ExpressCashierTransaction extends Equatable {
  const ExpressCashierTransaction({
    required this.ticketId,
    required this.plateNumber,
    required this.amount,
    required this.syncStatus,
    required this.status,
    required this.checkInAt,
    this.checkOutAt = '',
    required this.createdAt,
    this.vrNo,
    this.serverTicketId,
    this.driverIn,
    this.driverOut,
    this.voidReason,
  });

  factory ExpressCashierTransaction.fromTicket(Ticket ticket) {
    return ExpressCashierTransaction(
      ticketId: ticket.id,
      plateNumber: ticket.plateNumber,
      amount: ticket.fee ?? 0,
      syncStatus: ticket.syncStatus,
      status: ticket.status,
      checkInAt: ticket.checkInAt,
      checkOutAt: ticket.checkOutAt ?? '',
      createdAt: ticket.createdAt,
      vrNo: ticket.vrNo,
      serverTicketId: ticket.serverTicketId,
      driverIn: ticket.driverIn,
      driverOut: ticket.driverOut,
      voidReason: ticket.voidReason,
    );
  }

  final String ticketId;
  final String plateNumber;
  final double amount;
  final String syncStatus;
  final String status;
  final String checkInAt;
  final String checkOutAt;
  final String createdAt;
  final String? vrNo;
  final String? serverTicketId;
  final String? driverIn;
  final String? driverOut;
  final String? voidReason;

  bool get isSynced => syncStatus == 'synced';

  bool get isVoided => status == 'void';

  bool get hasServerId => serverTicketId?.trim().isNotEmpty == true;

  bool get canVoid => !isVoided;

  @override
  List<Object?> get props => [
        ticketId,
        plateNumber,
        amount,
        syncStatus,
        status,
        checkInAt,
        checkOutAt,
        createdAt,
        vrNo,
        serverTicketId,
        driverIn,
        driverOut,
        voidReason,
      ];
}

sealed class ExpressCashierState extends Equatable {
  const ExpressCashierState();

  @override
  List<Object?> get props => [];
}

class ExpressCashierInitial extends ExpressCashierState {
  const ExpressCashierInitial();
}

class ExpressCashierLoading extends ExpressCashierState {
  const ExpressCashierLoading();
}

class ExpressCashierLoaded extends ExpressCashierState {
  const ExpressCashierLoaded({
    required this.transactions,
    this.isSaving = false,
  });

  final List<ExpressCashierTransaction> transactions;
  final bool isSaving;

  ExpressCashierLoaded copyWith({
    List<ExpressCashierTransaction>? transactions,
    bool? isSaving,
  }) {
    return ExpressCashierLoaded(
      transactions: transactions ?? this.transactions,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [transactions, isSaving];
}

class ExpressCashierSaved extends ExpressCashierState {
  const ExpressCashierSaved({
    required this.ticketId,
    required this.transactions,
  });

  final String ticketId;
  final List<ExpressCashierTransaction> transactions;

  @override
  List<Object?> get props => [ticketId, transactions];
}

class ExpressCashierError extends ExpressCashierState {
  const ExpressCashierError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
