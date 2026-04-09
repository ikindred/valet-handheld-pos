import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/valet_log.dart';
import '../../../core/platform/device_info_payload.dart';
import '../../../core/services/device_id_service.dart';
import '../../../core/storage/offline_mode_prefs.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/auth_session_sync.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    final repo = context.read<AuthRepository>();
    final prefs = await SharedPreferences.getInstance();
    try {
      ValetLog.d('splash/_bootstrap', 'start');
      final deviceId = await DeviceIdService.getOrCreate();
      final deviceInfo = await buildDeviceInfoPayload();

      bool online = false;
      try {
        online = await InternetConnection()
            .hasInternetAccess
            .timeout(const Duration(seconds: 4), onTimeout: () => false);
      } catch (_) {
        online = false;
      }
      ValetLog.d('splash/_bootstrap', 'online=$online');
      if (online) {
        await repo.registerDevice(
          deviceId: deviceId,
          deviceInfo: deviceInfo,
          prefs: prefs,
        );
      }
      await repo.seedDevDeviceSiteIfNeeded(deviceId);

      final session = await repo.getActiveSession();
      if (session == null) {
        ValetLog.d('splash/_bootstrap', 'no session, navigating to login');
        await OfflineModePrefs.write(prefs, !online);
        if (mounted) context.go('/login');
        return;
      }

      Future<void> restoreLocalSession() async {
        await OfflineModePrefs.write(prefs, true);
        final email = await repo.emailForOfflineAccountId(session.userId);
        if (!mounted) return;
        await syncAuthBlocAndNavigate(
          context,
          repo: repo,
          localUserId: session.userId,
          email: email,
          standardRates: null,
        );
      }

      // Offline sessions never have a bearer token — do not treat as logged out.
      if (session.isOfflineSession) {
        ValetLog.d(
          'splash/_bootstrap',
          'offline session, restoring local state',
        );
        await restoreLocalSession();
        return;
      }

      if (online) {
        if (session.authToken == null || session.authToken!.isEmpty) {
          await repo.logoutOnly(deviceId: deviceId);
          if (mounted) context.go('/login');
          return;
        }
        try {
          final rates = await repo.revalidateActiveSession(deviceId: deviceId);
          await OfflineModePrefs.write(prefs, false);
          final email = await repo.emailForOfflineAccountId(session.userId);
          if (!mounted) return;
          await syncAuthBlocAndNavigate(
            context,
            repo: repo,
            localUserId: session.userId,
            email: email,
            standardRates: rates,
          );
        } catch (e, st) {
          ValetLog.e(
            'splash/_bootstrap',
            'revalidate failed, logging out',
            e,
            st,
          );
          await repo.logoutOnly(deviceId: deviceId);
          if (mounted) context.go('/login');
        }
        return;
      }

      // Online-originated session but no network: resume from local DB (shift / cash state).
      ValetLog.d(
        'splash/_bootstrap',
        'offline path, restoring local session',
      );
      await restoreLocalSession();
    } catch (e, st) {
      ValetLog.e('splash/_bootstrap', 'bootstrap error', e, st);
      await OfflineModePrefs.write(prefs, false);
      if (mounted) context.go('/login');
    }
  }

  TextStyle _poppins(
    double size,
    FontWeight w,
    Color color, {
    double height = 1.0,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFFFFFAF0),
              Color(0xFFF1F5FF),
            ],
            transform: GradientRotation(105 * math.pi / 180),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valet Master',
                style: _poppins(40, FontWeight.w700, const Color(0xFFF68D00)),
              ),
              const SizedBox(height: 10),
              Text(
                'SMART PARKING TECHNOLOGIES',
                style: _poppins(20, FontWeight.w500, const Color(0xFFAFAFAF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
