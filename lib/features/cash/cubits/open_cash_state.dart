import 'package:equatable/equatable.dart';

import '../models/open_transaction.dart';

sealed class OpenCashState extends Equatable {
  const OpenCashState();

  @override
  List<Object?> get props => [];
}

class OpenCashInitial extends OpenCashState {
  const OpenCashInitial();
}

class OpenCashLoading extends OpenCashState {
  const OpenCashLoading();
}

class OpenCashReady extends OpenCashState {
  const OpenCashReady();
}

class OpenCashHasInheritedTransactions extends OpenCashState {
  const OpenCashHasInheritedTransactions({required this.inheritedTransactions});

  final List<OpenTransaction> inheritedTransactions;

  @override
  List<Object?> get props => [inheritedTransactions];
}

class OpenCashError extends OpenCashState {
  const OpenCashError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
