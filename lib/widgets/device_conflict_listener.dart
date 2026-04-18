import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/device_id_service.dart';
import '../core/storage/prefs_keys.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/state/auth_bloc.dart';
import '../services/device_conflict_service.dart';

/// Subscribes to [DeviceConflictService.onConflictDetected] after login and shows a blocking dialog.
class DeviceConflictListener extends StatefulWidget {
  const DeviceConflictListener({super.key, required this.child});

  final Widget child;

  @override
  State<DeviceConflictListener> createState() => _DeviceConflictListenerState();
}

class _DeviceConflictListenerState extends State<DeviceConflictListener> {
  StreamSubscription<bool>? _conflictSub;
  bool _dialogOpen = false;

  static const _orange = Color(0xFFE87722);
  static const _white = Color(0xFFFFFFFF);
  static const _bodyGrey = Color(0xFFAEAEAE);

  @override
  void dispose() {
    unawaited(_conflictSub?.cancel());
    super.dispose();
  }

  Future<void> _onAuthAuthenticated() async {
    final svc = context.read<DeviceConflictService>();
    final repo = context.read<AuthRepository>();
    await _conflictSub?.cancel();
    await svc.disconnect();

    final session = await repo.getActiveSession();
    final token = session?.authToken ?? '';
    final prefs = await SharedPreferences.getInstance();
    final serverDeviceId = prefs.getString(PrefsKeys.deviceIdentityKey) ?? '';

    await svc.connect(token, serverDeviceId);

    if (!mounted) return;
    _conflictSub = svc.onConflictDetected.listen((conflict) {
      if (!conflict || !mounted) return;
      _showConflictDialog();
    });
  }

  Future<void> _onAuthLeft() async {
    await _conflictSub?.cancel();
    _conflictSub = null;
    if (!mounted) return;
    await context.read<DeviceConflictService>().disconnect();
  }

  void _showConflictDialog() {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFF252522),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Device Conflict Detected',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Another device is attempting to use this terminal identity. '
                    'If this was not authorized, contact your administrator. '
                    'Note: Any unsynced offline transactions on this device will NOT '
                    'transfer to the new device.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: _bodyGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      _dialogOpen = false;
                      if (!mounted) return;

                      final svc = context.read<DeviceConflictService>();
                      final repo = context.read<AuthRepository>();
                      final auth = context.read<AuthBloc>();
                      await svc.disconnect();
                      final deviceId = await DeviceIdService.getOrCreate();
                      await repo.logoutOnly(deviceId: deviceId);
                      auth.add(const AuthLoggedOut());
                      if (!mounted) return;
                      context.go('/login');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, next) {
        if (next is AuthAuthenticated && prev is! AuthAuthenticated) {
          return true;
        }
        if (next is AuthUnauthenticated && prev is AuthAuthenticated) {
          return true;
        }
        return false;
      },
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          await _onAuthAuthenticated();
        } else if (state is AuthUnauthenticated) {
          await _onAuthLeft();
        }
      },
      child: widget.child,
    );
  }
}
