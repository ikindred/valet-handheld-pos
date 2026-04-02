import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => [];
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit() : super(const CheckInState());
}

