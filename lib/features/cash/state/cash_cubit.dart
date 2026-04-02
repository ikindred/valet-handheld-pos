import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class CashState extends Equatable {
  const CashState();

  @override
  List<Object?> get props => [];
}

class CashCubit extends Cubit<CashState> {
  CashCubit() : super(const CashState());
}

