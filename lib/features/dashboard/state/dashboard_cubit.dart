import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());
}

