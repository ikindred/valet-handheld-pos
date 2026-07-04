import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/valet_log.dart';
import '../services/device_id_service.dart';
import '../storage/prefs_keys.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/remote/api_error_message.dart';
import '../../data/services/branch_config_service.dart';
import '../../features/sync/state/sync_cubit.dart';
import 'internet_reachability.dart';

/// Emits online/offline from [Connectivity] and runs **token revalidate → sync flush
/// + branch config** after reconnect or app resume.
class ConnectivityService {
  ConnectivityService({
    required AuthRepository authRepository,
    required BranchConfigService branchConfig,
    required SyncCubit syncCubit,
  }) : _auth = authRepository,
       _branchConfig = branchConfig,
       _syncCubit = syncCubit;

  final AuthRepository _auth;
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
  Future<void> onApplicationResumed() {
    return _hooksFuture ??= _runOnlineHooks().whenComplete(() {
      _hooksFuture = null;
    });
  }

  Future<void>? _hooksFuture;

  Future<void> _runOnlineHooks() async {
    try {
      if (!await _revalidateTokenBeforeSync()) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final autoSync = prefs.getBool(PrefsKeys.autoSyncOnConnect) ?? true;
      if (autoSync) {
        ValetLog.debug(
          'ConnectivityService',
          'online — SyncCubit.flush + branch_config',
        );
        await _syncCubit.flush();
      } else {
        ValetLog.debug(
          'ConnectivityService',
          'online — auto-sync off, branch_config only',
        );
      }
      await _branchConfig.syncFromServerForDeviceBranch();
    } catch (e, st) {
      ValetLog.error('ConnectivityService', 'online hooks failed', e, st);
    }
  }

  /// Revalidate JWT before sync. Returns **false** when the token is invalid and
  /// the user was logged out (skip sync).
  ///
  /// Offline sessions are upgraded to online via [AuthRepository.upgradeOfflineSessionToOnline]
  /// first, then revalidated.
  Future<bool> _revalidateTokenBeforeSync() async {
    if (!await InternetReachability.hasInternet()) {
      return true;
    }

    final session = await _auth.getActiveSession();
    if (session == null) {
      return true;
    }

    if (session.isOfflineSession) {
      return _upgradeOfflineSessionThenRevalidate();
    }

    final token = session.authToken?.trim() ?? '';
    if (token.isEmpty) {
      return true;
    }

    return _revalidateOnlineSessionToken();
  }

  Future<bool> _upgradeOfflineSessionThenRevalidate() async {
    try {
      ValetLog.debug(
        'ConnectivityService',
        'online — upgrade offline session to online',
      );
      final upgraded = await _auth.upgradeOfflineSessionToOnline();
      if (upgraded == null) {
        final stillOffline = (await _auth.getActiveSession())?.isOfflineSession;
        if (stillOffline == true) {
          ValetLog.warning(
            'ConnectivityService',
            'offline session — auto online login skipped (no stored credentials)',
          );
        }
        return true;
      }
      return _revalidateOnlineSessionToken();
    } on LoginApiFailure catch (e) {
      ValetLog.warning(
        'ConnectivityService',
        'auto online login rejected — stay offline (${e.message})',
      );
      return true;
    } on DioException catch (e) {
      ValetLog.warning(
        'ConnectivityService',
        'auto online login failed (${e.type}) — stay offline',
      );
      return true;
    } catch (e, st) {
      if (e is StateError && e.message == 'TOKEN_INVALID') {
        rethrow;
      }
      ValetLog.error(
        'ConnectivityService',
        'auto online login failed',
        e,
        st,
      );
      return true;
    }
  }

  Future<bool> _revalidateOnlineSessionToken() async {
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      ValetLog.debug('ConnectivityService', 'online — revalidate token');
      await _auth.revalidateActiveSession(deviceId: deviceId);
      return true;
    } on StateError catch (e) {
      if (e.message == 'TOKEN_INVALID') {
        ValetLog.debug('ConnectivityService', 'token invalid — logout');
        final deviceId = await DeviceIdService.getOrCreate();
        await _auth.logoutOnly(deviceId: deviceId);
        return false;
      }
      rethrow;
    } on DioException catch (e) {
      ValetLog.warning(
        'ConnectivityService',
        'revalidate failed (${e.type}) — sync with existing token',
      );
      return true;
    } catch (e, st) {
      ValetLog.error('ConnectivityService', 'revalidate failed', e, st);
      return true;
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
    final svc = context.read<ConnectivityService>();
    svc.emitOnline(online);
    _hadPlatformConnection = online;
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
    if (online) {
      unawaited(svc.onApplicationResumed());
    }
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
