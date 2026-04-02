import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

enum CashSessionStatus {
  open,
  closed,
}

final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn({required this.cashSessionStatus});

  final CashSessionStatus cashSessionStatus;

  @override
  List<Object?> get props => [cashSessionStatus];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.cashSessionStatus});

  final CashSessionStatus cashSessionStatus;

  @override
  List<Object?> get props => [cashSessionStatus];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthUnknown()) {
    on<AuthStarted>((event, emit) {
      emit(const AuthUnauthenticated());
    });

    on<AuthLoggedIn>((event, emit) {
      emit(AuthAuthenticated(cashSessionStatus: event.cashSessionStatus));
    });

    on<AuthLoggedOut>((event, emit) {
      emit(const AuthUnauthenticated());
    });
  }
}

