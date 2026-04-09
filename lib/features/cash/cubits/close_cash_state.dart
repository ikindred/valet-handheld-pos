import 'package:equatable/equatable.dart';

import '../../../data/local/db/app_database.dart';
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
    required this.openingFloat,
    required this.totalSales,
    required this.expectedCash,
    required this.actualCash,
    required this.variance,
    required this.salesToRemit,
    required this.transactionsCount,
    required this.openTransactions,
    required this.closingNotes,
  });

  final Shift shift;
  final double openingFloat;
  final double totalSales;
  final double expectedCash;
  final double actualCash;
  final double variance;
  final double salesToRemit;
  final int transactionsCount;
  final List<OpenTransaction> openTransactions;
  final String closingNotes;

  CloseCashLoaded copyWith({
    double? actualCash,
    String? closingNotes,
  }) {
    final nextActual = actualCash ?? this.actualCash;
    final nextExpected = expectedCash;
    return CloseCashLoaded(
      shift: shift,
      openingFloat: openingFloat,
      totalSales: totalSales,
      expectedCash: nextExpected,
      actualCash: nextActual,
      variance: nextActual - nextExpected,
      salesToRemit: salesToRemit,
      transactionsCount: transactionsCount,
      openTransactions: openTransactions,
      closingNotes: closingNotes ?? this.closingNotes,
    );
  }

  @override
  List<Object?> get props => [
        shift,
        openingFloat,
        totalSales,
        expectedCash,
        actualCash,
        variance,
        salesToRemit,
        transactionsCount,
        openTransactions,
        closingNotes,
      ];
}

class CloseCashHasOpenTransactions extends CloseCashState {
  const CloseCashHasOpenTransactions({required this.openTransactions});

  final List<OpenTransaction> openTransactions;

  @override
  List<Object?> get props => [openTransactions];
}

class CloseCashConfirming extends CloseCashState {
  const CloseCashConfirming();
}

class CloseCashSuccess extends CloseCashState {
  const CloseCashSuccess();
}

class CloseCashError extends CloseCashState {
  const CloseCashError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
