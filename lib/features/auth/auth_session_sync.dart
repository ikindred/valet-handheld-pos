import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/session/standard_parking_rates.dart';
import '../../data/repositories/auth_repository.dart';
import 'state/auth_bloc.dart';

/// Updates [AuthBloc] from [AuthRepository.shiftRouteForLocalUser] then navigates
/// (after the bloc emits, so [GoRouter] redirects see the correct state).
///
/// [localUserId] is [OfflineAccounts.id] for the logged-in user.
Future<void> syncAuthBlocAndNavigate(
  BuildContext context, {
  required AuthRepository repo,
  required int localUserId,
  String? email,
  StandardParkingRates? standardRates,
}) async {
  final route = await repo.shiftRouteForLocalUser(localUserId);
  final open = route == '/dashboard';
  if (!context.mounted) return;
  context.read<AuthBloc>().add(
        AuthLoggedIn(
          cashSessionStatus:
              open ? CashSessionStatus.open : CashSessionStatus.closed,
          standardRates: standardRates,
          userId: localUserId.toString(),
          email: email,
        ),
      );
  await context.read<AuthBloc>().stream.firstWhere((s) => s is AuthAuthenticated);
  if (context.mounted) context.go(route);
}
