import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../data/local/db/app_database.dart';
import '../../data/remote/auth_api.dart';
import '../../data/remote/dashboard_api.dart';
import '../../data/remote/dio_client.dart';
import '../../data/remote/transactions_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/printing/bluetooth_pos_printer.dart';
import '../../core/printing/bluetooth_valet_print_service.dart';
import '../../core/printing/printer_connection_notifier.dart';
import '../../core/printing/valet_print_service.dart';
import '../../data/services/branch_config_service.dart';
import '../../data/services/close_cash_purge_service.dart';
import '../../data/services/debug_local_data_service.dart';
import '../../data/services/parking_layout_service.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../data/services/shift_service.dart';
import '../../data/services/ticket_service.dart';
import '../../services/device_conflict_service.dart';
import '../../widgets/device_conflict_listener.dart';
import '../connectivity/connectivity_service.dart';
import '../routing/router_refresh_notifier.dart';
import '../sync/local_sync_notifier.dart';
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
        ChangeNotifierProvider(create: (_) => LocalSyncNotifier()),
        Provider<AppDatabase>(create: (_) => AppDatabase(), dispose: (_, db) => db.close()),
        Provider<Dio>(create: (_) => createAppDio()),
        Provider<AuthApi>(create: (c) => AuthApi(c.read<Dio>())),
        Provider<TransactionsApi>(create: (c) => TransactionsApi(c.read<Dio>())),
        Provider<DashboardApi>(create: (c) => DashboardApi(c.read<Dio>())),
        Provider<RateService>(
          create: (c) => RateService(c.read<AppDatabase>()),
        ),
        Provider<ParkingLayoutService>(
          create: (c) => ParkingLayoutService(c.read<AppDatabase>()),
        ),
        Provider<RateFetchService>(
          create: (c) => RateFetchService(
            c.read<AppDatabase>(),
            c.read<Dio>(),
            c.read<ParkingLayoutService>(),
          ),
        ),
        Provider<TicketService>(
          create: (c) => TicketService(
            c.read<AppDatabase>(),
            c.read<Dio>(),
            c.read<TransactionsApi>(),
            c.read<DashboardApi>(),
            c.read<RateService>(),
            c.read<RateFetchService>(),
            c.read<ParkingLayoutService>(),
            localSyncNotifier: c.read<LocalSyncNotifier>(),
          ),
        ),
        Provider<ShiftService>(
          create: (c) => ShiftService(
            c.read<AppDatabase>(),
            c.read<Dio>(),
            ticketService: c.read<TicketService>(),
            onShiftMutated: () => c.read<RouterRefreshNotifier>().notifyAuthChanged(),
            localSyncNotifier: c.read<LocalSyncNotifier>(),
          ),
        ),
        Provider<CloseCashPurgeService>(
          create: (c) => CloseCashPurgeService(c.read<AppDatabase>()),
        ),
        Provider<DebugLocalDataService>(
          create: (c) => DebugLocalDataService(
            c.read<AppDatabase>(),
            localSyncNotifier: c.read<LocalSyncNotifier>(),
          ),
        ),
        Provider<BluetoothPosPrinter>(
          create: (_) => BluetoothPosPrinter(),
        ),
        ChangeNotifierProvider<PrinterConnectionNotifier>(
          create: (c) => PrinterConnectionNotifier(
            printer: c.read<BluetoothPosPrinter>(),
          ),
        ),
        Provider<ValetPrintService>(
          create: (c) => BluetoothValetPrintService(
            c.read<BluetoothPosPrinter>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (c) => AuthRepository(
            c.read<AppDatabase>(),
            c.read<AuthApi>(),
            c.read<RouterRefreshNotifier>(),
            c.read<ShiftService>(),
            c.read<RateService>(),
            c.read<RateFetchService>(),
            c.read<DashboardApi>(),
          ),
        ),
        Provider<DeviceConflictService>(
          create: (_) => DeviceConflictServiceStub(),
        ),
        BlocProvider<SyncCubit>(
          create: (c) => SyncCubit(
            database: c.read<AppDatabase>(),
            dio: c.read<Dio>(),
            authRepository: c.read<AuthRepository>(),
            ticketService: c.read<TicketService>(),
            localSyncNotifier: c.read<LocalSyncNotifier>(),
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
            authRepository: c.read<AuthRepository>(),
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
            dashboardApi: c.read<DashboardApi>(),
            rateFetchService: c.read<RateFetchService>(),
            syncCubit: c.read<SyncCubit>(),
          ),
        ),
        BlocProvider(
          create: (c) => CheckInCubit(
            ticketService: c.read<TicketService>(),
            authRepository: c.read<AuthRepository>(),
            shiftService: c.read<ShiftService>(),
            transactionsApi: c.read<TransactionsApi>(),
          ),
        ),
        BlocProvider(
          create: (c) => CheckOutCubit(
            c.read<TicketService>(),
            c.read<RateService>(),
            c.read<AuthRepository>(),
            c.read<TransactionsApi>(),
          ),
        ),
        BlocProvider(
          create: (c) => ReportsCubit(
            authRepository: c.read<AuthRepository>(),
            ticketService: c.read<TicketService>(),
            transactionsApi: c.read<TransactionsApi>(),
            rateService: c.read<RateService>(),
            syncCubit: c.read<SyncCubit>(),
          ),
        ),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: DeviceConflictListener(
        child: ConnectivityScope(child: child),
      ),
    );
  }
}
