import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/session/standard_parking_rates.dart';

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
  const AuthLoggedIn({
    required this.cashSessionStatus,
    this.standardRates,
    this.userId,
    this.email,
  });

  final CashSessionStatus cashSessionStatus;

  /// From login / setup API (`standard_rates`); optional until backend is wired.
  final StandardParkingRates? standardRates;

  final String? userId;

  final String? email;

  @override
  List<Object?> get props => [cashSessionStatus, standardRates, userId, email];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}

final class AuthCashSessionUpdated extends AuthEvent {
  const AuthCashSessionUpdated(this.cashSessionStatus);

  final CashSessionStatus cashSessionStatus;

  @override
  List<Object?> get props => [cashSessionStatus];
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
  const AuthAuthenticated({
    required this.cashSessionStatus,
    this.standardRates,
    this.userId,
    this.email,
  });

  final CashSessionStatus cashSessionStatus;

  final StandardParkingRates? standardRates;

  final String? userId;

  final String? email;

  @override
  List<Object?> get props => [cashSessionStatus, standardRates, userId, email];
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
      emit(
        AuthAuthenticated(
          cashSessionStatus: event.cashSessionStatus,
          standardRates: event.standardRates,
          userId: event.userId,
          email: event.email,
        ),
      );
    });

    on<AuthLoggedOut>((event, emit) {
      emit(const AuthUnauthenticated());
    });

    on<AuthCashSessionUpdated>((event, emit) {
      final current = state;
      if (current is! AuthAuthenticated) return;
      emit(
        AuthAuthenticated(
          cashSessionStatus: event.cashSessionStatus,
          standardRates: current.standardRates,
          userId: current.userId,
          email: current.email,
        ),
      );
    });
  }
}
