import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/device_id_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../state/auth_bloc.dart';

enum LogoutChoice {
  logoutOnly,
  closeCashAndLogout,
}

/// Shared logout UX from Dashboard, Open Cash, and Settings.
Future<void> showLogoutFlow(BuildContext context) async {
  final choice = await showDialog<LogoutChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text(
        'Close cash and log out, or log out and leave the shift open on the server?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(LogoutChoice.logoutOnly),
          child: const Text('Logout only'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(LogoutChoice.closeCashAndLogout),
          child: const Text('Close Cash + Logout'),
        ),
      ],
    ),
  );

  if (!context.mounted || choice == null) return;

  if (choice == LogoutChoice.logoutOnly) {
    final deviceId = await DeviceIdService.getOrCreate();
    if (!context.mounted) return;
    await context.read<AuthRepository>().logoutOnly(deviceId: deviceId);
    if (!context.mounted) return;
    context.read<AuthBloc>().add(const AuthLoggedOut());
    context.go('/login');
    return;
  }

  final password = await _promptPassword(context);
  if (!context.mounted || password == null || password.isEmpty) return;

  final ok = await context.read<AuthRepository>().verifyCurrentPassword(
        password,
      );
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect password.')),
    );
    return;
  }

  context.go('/cash/close');
}

Future<String?> _promptPassword(BuildContext context) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm password'),
      content: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
        autofocus: true,
        onSubmitted: (_) => Navigator.of(context).pop(ctrl.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ctrl.text),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
