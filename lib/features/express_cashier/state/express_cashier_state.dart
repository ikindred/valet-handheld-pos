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
    this.includedInCloseCash = false,
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
      includedInCloseCash: ticket.includedInCloseCash,
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

  /// True when the server already counted this row in a prior close-cash
  /// session — shown in the list but excluded from the current shift total.
  final bool includedInCloseCash;

  bool get isSynced => syncStatus == 'synced';

  bool get isVoided => status == 'void';

  bool get hasServerId => serverTicketId?.trim().isNotEmpty == true;

  bool get canVoid => !isVoided;

  /// Sale time for ordering (works for offline-created and server-synced rows).
  DateTime get saleInstant {
    for (final raw in [checkOutAt, checkInAt, createdAt]) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Current-shift rows first (newest first), then prior close-cash rows
  /// (newest first). Safe for offline-only and mixed online/offline lists.
  static List<ExpressCashierTransaction> sortedForDisplay(
    Iterable<ExpressCashierTransaction> rows,
  ) {
    final list = rows.toList();
    list.sort(_compareDisplayOrder);
    return list;
  }

  static int _compareDisplayOrder(
    ExpressCashierTransaction a,
    ExpressCashierTransaction b,
  ) {
    final aClosed = a.includedInCloseCash ? 1 : 0;
    final bClosed = b.includedInCloseCash ? 1 : 0;
    if (aClosed != bClosed) return aClosed.compareTo(bClosed);

    final byTime = b.saleInstant.compareTo(a.saleInstant);
    if (byTime != 0) return byTime;
    return b.ticketId.compareTo(a.ticketId);
  }

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
        includedInCloseCash,
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
