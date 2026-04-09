import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_text_field.dart';
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
      scrollable: false,
      title: Text(
        'Logout',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose how you want to end your session on this device.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Close cash and log out, or log out only and leave the shift open '
            'on the server?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actionsAlignment: MainAxisAlignment.end,
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
  return showDialog<String>(
    context: context,
    builder: (context) => const _ConfirmPasswordDialog(),
  );
}

class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog();

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: false,
      title: Text(
        'Confirm password',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your account password to verify before closing cash and '
            'continuing.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LabeledAppTextField(
            label: 'Password',
            child: AppTextField(
              controller: _ctrl,
              obscureText: true,
              hint: '************',
              autofocus: true,
              style: AppTextField.defaultValueStyle(),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
