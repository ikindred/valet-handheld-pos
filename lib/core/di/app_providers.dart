import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../data/local/db/app_database.dart';
import '../../data/remote/auth_api.dart';
import '../../data/remote/dio_client.dart';
import '../../data/remote/transactions_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/printing/valet_print_service.dart';
import '../../data/services/branch_config_service.dart';
import '../../data/services/rate_service.dart';
import '../../data/services/shift_service.dart';
import '../../data/services/ticket_service.dart';
import '../connectivity/connectivity_service.dart';
import '../routing/router_refresh_notifier.dart';
import '../../features/auth/state/auth_bloc.dart';
import '../../features/check_in/state/check_in_cubit.dart';
import '../../features/check_out/state/check_out_cubit.dart';
import '../../features/dashboard/state/dashboard_cubit.dart';
import '../../features/reports/state/reports_cubit.dart';
import '../../features/settings/state/settings_cubit.dart';
import '../../features/sync/state/sync_cubit.dart';

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
        Provider<TransactionsApi>(create: (c) => TransactionsApi(c.read<Dio>())),
        Provider<ShiftService>(
          create: (c) => ShiftService(
            c.read<AppDatabase>(),
            c.read<Dio>(),
            onShiftMutated: () => c.read<RouterRefreshNotifier>().notifyAuthChanged(),
          ),
        ),
        Provider<RateService>(
          create: (c) => RateService(c.read<AppDatabase>()),
        ),
        Provider<TicketService>(
          create: (c) => TicketService(c.read<AppDatabase>(), c.read<Dio>()),
        ),
        Provider<ValetPrintService>(
          create: (_) => NoopValetPrintService(),
        ),
        Provider<AuthRepository>(
          create: (c) => AuthRepository(
            c.read<AppDatabase>(),
            c.read<AuthApi>(),
            c.read<RouterRefreshNotifier>(),
            c.read<ShiftService>(),
          ),
        ),
        BlocProvider<SyncCubit>(
          create: (c) => SyncCubit(
            database: c.read<AppDatabase>(),
            dio: c.read<Dio>(),
            authRepository: c.read<AuthRepository>(),
          ),
        ),
        Provider<BranchConfigService>(
          create: (c) => BranchConfigService(
            c.read<AppDatabase>(),
            c.read<Dio>(),
            c.read<AuthRepository>(),
          ),
        ),
        Provider<ConnectivityService>(
          create: (c) => ConnectivityService(
            branchConfig: c.read<BranchConfigService>(),
            syncCubit: c.read<SyncCubit>(),
          ),
          dispose: (_, s) => s.dispose(),
        ),
        BlocProvider(create: (_) => AuthBloc()..add(const AuthStarted())),
        BlocProvider(
          create: (c) => DashboardCubit(
            authRepository: c.read<AuthRepository>(),
            ticketService: c.read<TicketService>(),
          ),
        ),
        BlocProvider(
          create: (c) => CheckInCubit(
            ticketService: c.read<TicketService>(),
            authRepository: c.read<AuthRepository>(),
            shiftService: c.read<ShiftService>(),
          ),
        ),
        BlocProvider(
          create: (c) => CheckOutCubit(
            c.read<TicketService>(),
            c.read<RateService>(),
            c.read<AuthRepository>(),
          ),
        ),
        BlocProvider(
          create: (c) => ReportsCubit(
            authRepository: c.read<AuthRepository>(),
            ticketService: c.read<TicketService>(),
            transactionsApi: c.read<TransactionsApi>(),
          ),
        ),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: ConnectivityScope(child: child),
    );
  }
}
