import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());
}

