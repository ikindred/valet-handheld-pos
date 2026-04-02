import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class CheckOutState extends Equatable {
  const CheckOutState();

  @override
  List<Object?> get props => [];
}

class CheckOutCubit extends Cubit<CheckOutState> {
  CheckOutCubit() : super(const CheckOutState());
}

