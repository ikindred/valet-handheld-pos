import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/offline_login_screen.dart';
import '../../features/cash/presentation/close_cash_screen.dart';
import '../../features/cash/presentation/open_cash_screen.dart';
import '../../features/check_in/presentation/check_in_customer_valet_screen.dart';
import '../../features/check_in/presentation/check_in_review_print_screen.dart';
import '../../features/check_in/presentation/check_in_shell.dart';
import '../../features/check_in/presentation/check_in_vehicle_condition_screen.dart';
import '../../features/check_in/presentation/check_in_vehicle_details_screen.dart';
import '../../features/check_out/presentation/check_out_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'auth_router_guard.dart';
import 'router_refresh_notifier.dart';

GoRouter createAppRouter(
  BuildContext context,
  RouterRefreshNotifier refresh,
) {
  final guard = AuthRouterGuard(context);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: guard.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/offline-login',
        builder: (context, state) => const OfflineLoginScreen(),
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
        redirect: (context, state) {
          if (state.uri.path == '/check-in') {
            return '/check-in/step-1';
          }
          return null;
        },
        routes: [
          ShellRoute(
            builder: (context, state, child) => CheckInShell(child: child),
            routes: [
              GoRoute(
                path: 'step-1',
                builder: (context, state) => const CheckInCustomerValetScreen(),
              ),
              GoRoute(
                path: 'step-2',
                builder: (context, state) =>
                    const CheckInVehicleDetailsScreen(),
              ),
              GoRoute(
                path: 'step-3',
                builder: (context, state) =>
                    const CheckInVehicleConditionScreen(),
              ),
              GoRoute(
                path: 'step-4',
                redirect: (context, state) => '/check-in/step-3',
              ),
              GoRoute(
                path: 'step-5',
                builder: (context, state) => const CheckInReviewPrintScreen(),
              ),
              GoRoute(
                path: 'step-6',
                redirect: (context, state) => '/check-in/step-5',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/check-out',
        builder: (context, state) => const CheckOutScreen(),
      ),
      GoRoute(path: '/cash', redirect: (_, __) => '/cash/open'),
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
