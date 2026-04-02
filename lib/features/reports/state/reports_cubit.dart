import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit() : super(const ReportsState());
}

