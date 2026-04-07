import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../data/local/db/app_database.dart';
import '../../data/remote/auth_api.dart';
import '../../data/remote/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../routing/router_refresh_notifier.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouterRefreshNotifier()),
        Provider<AppDatabase>(create: (_) => AppDatabase(), dispose: (_, db) => db.close()),
        Provider<Dio>(create: (_) => createAppDio()),
        Provider<AuthApi>(create: (c) => AuthApi(c.read<Dio>())),
        Provider<AuthRepository>(
          create: (c) => AuthRepository(
            c.read<AppDatabase>(),
            c.read<AuthApi>(),
            c.read<RouterRefreshNotifier>(),
          ),
        ),
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
