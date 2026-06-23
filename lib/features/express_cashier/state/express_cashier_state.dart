import 'package:equatable/equatable.dart';

import '../../../data/local/db/app_database.dart';

class ExpressCashierTransaction extends Equatable {
  const ExpressCashierTransaction({
    required this.ticketId,
    required this.plateNumber,
    required this.amount,
    required this.syncStatus,
    this.vrNo,
  });

  factory ExpressCashierTransaction.fromTicket(Ticket ticket) {
    return ExpressCashierTransaction(
      ticketId: ticket.id,
      plateNumber: ticket.plateNumber,
      amount: ticket.fee ?? 0,
      syncStatus: ticket.syncStatus,
      vrNo: ticket.vrNo,
    );
  }

  final String ticketId;
  final String plateNumber;
  final double amount;
  final String syncStatus;
  final String? vrNo;

  bool get isSynced => syncStatus == 'synced';

  @override
  List<Object?> get props => [ticketId, plateNumber, amount, syncStatus, vrNo];
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
