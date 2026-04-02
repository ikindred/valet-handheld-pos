import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

final class SyncStarted extends SyncEvent {
  const SyncStarted();
}

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

final class SyncIdle extends SyncState {
  const SyncIdle();
}

final class SyncRunning extends SyncState {
  const SyncRunning();
}

final class SyncFailed extends SyncState {
  const SyncFailed();
}

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc() : super(const SyncIdle()) {
    on<SyncStarted>((event, emit) {
      emit(const SyncRunning());
      emit(const SyncIdle());
    });
  }
}

