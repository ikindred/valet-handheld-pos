import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_bloc.dart';

class AuthRouterGuard {
  AuthRouterGuard(this.context);

  final BuildContext context;

  String? redirect(BuildContext _, GoRouterState state) {
    final auth = context.read<AuthBloc>().state;
    final loc = state.uri.toString();

    final isLogin = loc == '/login' || loc == '/splash';
    final isCashOpen = loc.startsWith('/cash/open');
    final isCashClose = loc.startsWith('/cash/close');

    if (auth is AuthUnauthenticated) {
      return isLogin ? null : '/login';
    }

    if (auth is AuthAuthenticated) {
      if (isLogin) {
        return auth.cashSessionStatus == CashSessionStatus.closed ? '/cash/open' : '/dashboard';
      }

      if (auth.cashSessionStatus == CashSessionStatus.closed) {
        // Allow closing cash even when closed? In practice, close cash implies ending shift.
        if (isCashOpen || isCashClose) return null;
        return '/cash/open';
      }
    }

    return null;
  }
}

