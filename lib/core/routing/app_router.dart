import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/cash/presentation/close_cash_screen.dart';
import '../../features/cash/presentation/open_cash_screen.dart';
import '../../features/check_in/presentation/check_in_screen.dart';
import '../../features/check_out/presentation/check_out_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'auth_router_guard.dart';

GoRouter createAppRouter(BuildContext context) {
  final guard = AuthRouterGuard(context);
  return GoRouter(
    initialLocation: '/splash',
    redirect: guard.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/cash/open',
        builder: (context, state) => const OpenCashScreen(),
      ),
      GoRoute(
        path: '/cash/close',
        builder: (context, state) => const CloseCashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/check-in',
        builder: (context, state) => const CheckInScreen(),
      ),
      GoRoute(
        path: '/check-out',
        builder: (context, state) => const CheckOutScreen(),
      ),
      GoRoute(
        path: '/cash',
        redirect: (_, __) => '/cash/open',
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

