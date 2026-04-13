import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../logging/valet_log.dart';
import '../../data/services/branch_config_service.dart';
import '../../features/sync/state/sync_cubit.dart';

/// Emits online/offline from [Connectivity] and runs **sync flush + branch config**
/// after reconnect or app resume.
class ConnectivityService {
  ConnectivityService({
    required BranchConfigService branchConfig,
    required SyncCubit syncCubit,
  })  : _branchConfig = branchConfig,
        _syncCubit = syncCubit;

  final BranchConfigService _branchConfig;
  final SyncCubit _syncCubit;

  final _online = StreamController<bool>.broadcast();
  Timer? _debounce;

  /// Latest connectivity from the platform (not a full internet proof).
  Stream<bool> get isOnline => _online.stream;

  void emitOnline(bool value) {
    if (!_online.isClosed) {
      _online.add(value);
    }
  }

  /// Called when [Connectivity] reports a transition to a “connected” state.
  void onRegainedConnection() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_runOnlineHooks());
    });
  }

  /// Same hooks as reconnect (Step 3 / Step 7 lifecycle).
  Future<void> onApplicationResumed() => _runOnlineHooks();

  Future<void> _runOnlineHooks() async {
    try {
      ValetLog.debug(
        'ConnectivityService',
        'online — SyncCubit.flush + branch_config',
      );
      await _syncCubit.flush();
      await _branchConfig.syncFromServerForDeviceBranch();
    } catch (e, st) {
      ValetLog.error('ConnectivityService', 'online hooks failed', e, st);
    }
  }

  void dispose() {
    _debounce?.cancel();
    unawaited(_online.close());
  }
}

/// Subscribes to connectivity + app lifecycle and drives [ConnectivityService].
class ConnectivityScope extends StatefulWidget {
  const ConnectivityScope({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityScope> createState() => _ConnectivityScopeState();
}

class _ConnectivityScopeState extends State<ConnectivityScope>
    with WidgetsBindingObserver {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  var _hadPlatformConnection = false;

  static bool _resultsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((e) => e != ConnectivityResult.none);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final initial = await _connectivity.checkConnectivity();
    if (!mounted) return;
    final online = _resultsOnline(initial);
    context.read<ConnectivityService>().emitOnline(online);
    _hadPlatformConnection = online;
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    if (!mounted) return;
    final online = _resultsOnline(results);
    final svc = context.read<ConnectivityService>();
    svc.emitOnline(online);
    if (online && !_hadPlatformConnection) {
      svc.onRegainedConnection();
    }
    _hadPlatformConnection = online;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<ConnectivityService>().onApplicationResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
