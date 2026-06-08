import 'package:equatable/equatable.dart';

import '../../../data/local/db/app_database.dart';
import '../../../core/printing/close_cash_receipt_data.dart';
import '../models/close_cash_shift_stats.dart';
import '../models/open_transaction.dart';

sealed class CloseCashState extends Equatable {
  const CloseCashState();

  @override
  List<Object?> get props => [];
}

class CloseCashInitial extends CloseCashState {
  const CloseCashInitial();
}

class CloseCashLoading extends CloseCashState {
  const CloseCashLoading();
}

class CloseCashLoaded extends CloseCashState {
  const CloseCashLoaded({
    required this.shift,
    required this.actualCash,
    required this.openTransactions,
    required this.stats,
  });

  final Shift shift;
  final double actualCash;
  final List<OpenTransaction> openTransactions;
  final CloseCashShiftStats stats;

  CloseCashLoaded copyWith({double? actualCash}) {
    return CloseCashLoaded(
      shift: shift,
      actualCash: actualCash ?? this.actualCash,
      openTransactions: openTransactions,
      stats: stats,
    );
  }

  @override
  List<Object?> get props => [shift, actualCash, openTransactions, stats];
}

class CloseCashConfirming extends CloseCashState {
  const CloseCashConfirming();
}

class CloseCashSuccess extends CloseCashState {
  const CloseCashSuccess({required this.receipt});

  final CloseCashReceiptData receipt;

  @override
  List<Object?> get props => [receipt];
}

class CloseCashBlocked extends CloseCashState {
  const CloseCashBlocked(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CloseCashError extends CloseCashState {
  const CloseCashError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
