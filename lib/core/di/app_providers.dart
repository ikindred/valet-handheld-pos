import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/state/auth_bloc.dart';
import '../../features/cash/state/cash_cubit.dart';
import '../../features/check_in/state/check_in_cubit.dart';
import '../../features/check_out/state/check_out_cubit.dart';
import '../../features/dashboard/state/dashboard_cubit.dart';
import '../../features/reports/state/reports_cubit.dart';
import '../../features/settings/state/settings_cubit.dart';
import '../../features/sync/state/sync_bloc.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(const AuthStarted())),
        BlocProvider(create: (_) => SyncBloc()),
        BlocProvider(create: (_) => DashboardCubit()),
        BlocProvider(create: (_) => CheckInCubit()),
        BlocProvider(create: (_) => CheckOutCubit()),
        BlocProvider(create: (_) => CashCubit()),
        BlocProvider(create: (_) => ReportsCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: child,
    );
  }
}

