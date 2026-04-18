import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_bloc.dart';

class AuthRouterGuard {
  AuthRouterGuard(this.context);

  final BuildContext context;

  String? redirect(BuildContext _, GoRouterState state) {
    final auth = context.read<AuthBloc>().state;
    final loc = state.uri.path;

    final isPublic = loc == '/splash' ||
        loc == '/login' ||
        loc == '/offline-login' ||
        loc == '/device-setup';
    final isCashOpen = loc.startsWith('/cash/open');
    final isCashClose = loc.startsWith('/cash/close');

    if (auth is AuthUnauthenticated) {
      return isPublic ? null : '/login';
    }

    if (auth is AuthAuthenticated) {
      if (loc == '/splash' ||
          loc == '/login' ||
          loc == '/offline-login' ||
          loc == '/device-setup') {
        return auth.cashSessionStatus == CashSessionStatus.closed
            ? '/cash/open'
            : '/dashboard';
      }

      if (auth.cashSessionStatus == CashSessionStatus.closed) {
        if (isCashOpen || isCashClose) return null;
        return '/cash/open';
      }
    }

    return null;
  }
}
