import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/services/device_id_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/close_cash_purge_service.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../state/auth_bloc.dart';

enum LogoutChoice {
  logoutOnly,
  closeCashAndLogout,
}

/// Branded dialog shell shared by logout steps.
class _LogoutDialogShell extends StatelessWidget {
  const _LogoutDialogShell({
    required this.title,
    required this.icon,
    required this.content,
    this.actions,
  });

  final String title;
  final IconData icon;
  final Widget content;
  final Widget? actions;

  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Dialog(
      backgroundColor: tc.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tc.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DashboardStyles.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: DashboardStyles.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: tc.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
              if (actions != null) ...[
                const SizedBox(height: 18),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutOptionCard extends StatelessWidget {
  const _LogoutOptionCard({
    required this.icon,
    required this.title,
    required this.body,
    this.emphasized = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final accent = DashboardStyles.orange;
    final borderColor = emphasized
        ? accent.withValues(alpha: 0.55)
        : tc.cardBorder;
    final bg = emphasized ? tc.accentSurface : tc.hintFill;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: emphasized ? accent : tc.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: tc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded logout confirmation. Returns `true` when the user confirms.
Future<bool> showLogoutConfirmDialog(
  BuildContext context, {
  String title = 'Logout',
  required String message,
}) async {
  final tc = AppThemeColors.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _LogoutDialogShell(
      title: title,
      icon: LucideIcons.logOut,
      content: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: tc.textSecondary,
        ),
      ),
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: tc.textSecondary),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DashboardStyles.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 40),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}

Future<void> navigateAfterLogout(BuildContext context) async {
  context.read<AuthBloc>().add(const AuthLoggedOut());
  await context.read<AuthBloc>().stream.firstWhere((s) => s is AuthUnauthenticated);
  if (context.mounted) context.go('/login');
}

/// After close cash — end session, purge ended rows, then return to login.
Future<void> logoutAfterCloseCash(BuildContext context) async {
  final confirmed = await showLogoutConfirmDialog(
    context,
    message: 'Your shift is closed. Are you sure you want to logout?',
  );
  if (!context.mounted || !confirmed) return;
  final deviceId = await DeviceIdService.getOrCreate();
  if (!context.mounted) return;
  final repo = context.read<AuthRepository>();
  final purge = context.read<CloseCashPurgeService>();
  await repo.logoutOnly(deviceId: deviceId);
  await purge.purgeEndedSessions();
  if (!context.mounted) return;
  await navigateAfterLogout(context);
}

/// Simple "Are you sure?" used when there is no open cash session.
Future<void> _logoutWithSimpleConfirm(BuildContext context) async {
  final confirmed = await showLogoutConfirmDialog(
    context,
    message:
        'You have no open cash session. Are you sure you want to logout?',
  );
  if (!context.mounted || !confirmed) return;
  final deviceId = await DeviceIdService.getOrCreate();
  if (!context.mounted) return;
  await context.read<AuthRepository>().logoutOnly(deviceId: deviceId);
  if (!context.mounted) return;
  await navigateAfterLogout(context);
}

/// Shared logout UX from Dashboard, Open Cash, and Settings.
Future<void> showLogoutFlow(BuildContext context) async {
  final authState = context.read<AuthBloc>().state;
  final hasCashOpen = authState is AuthAuthenticated &&
      authState.cashSessionStatus == CashSessionStatus.open;

  if (!hasCashOpen) {
    await _logoutWithSimpleConfirm(context);
    return;
  }

  final choice = await showDialog<LogoutChoice>(
    context: context,
    builder: (context) {
      final tc = AppThemeColors.of(context);
      return _LogoutDialogShell(
        title: 'Logout',
        icon: LucideIcons.logOut,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You are signing out of this device. Choose what should happen '
              'to your open cash shift:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: tc.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _LogoutOptionCard(
              icon: LucideIcons.doorOpen,
              title: 'Logout only',
              body:
                  'End this session but keep the shift open on the server. '
                  'Sign in again later to continue where you left off.',
              onTap: () =>
                  Navigator.of(context).pop(LogoutChoice.logoutOnly),
            ),
            const SizedBox(height: 10),
            _LogoutOptionCard(
              icon: LucideIcons.wallet,
              title: 'Close cash + logout',
              body:
                  'Close your shift, reconcile cash, then sign out. '
                  'Use this when you are finished for the day.',
              emphasized: true,
              onTap: () => Navigator.of(context)
                  .pop(LogoutChoice.closeCashAndLogout),
            ),
            const SizedBox(height: 10),
            _LogoutOptionCard(
              icon: LucideIcons.x,
              title: 'Cancel',
              body:
                  'Stay signed in and return without making any changes.',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted || choice == null) return;

  if (choice == LogoutChoice.logoutOnly) {
    final deviceId = await DeviceIdService.getOrCreate();
    if (!context.mounted) return;
    await context.read<AuthRepository>().logoutOnly(deviceId: deviceId);
    if (!context.mounted) return;
    await navigateAfterLogout(context);
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
    final tc = AppThemeColors.of(context);
    return _LogoutDialogShell(
      title: 'Confirm password',
      icon: LucideIcons.lock,
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
              color: tc.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LabeledAppTextField(
            label: 'Password',
            labelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: tc.textSecondary,
            ),
            child: AppTextField(
              controller: _ctrl,
              obscureText: true,
              hint: '************',
              autofocus: true,
              style: AppTextField.defaultValueStyle(context),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: tc.textSecondary),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: DashboardStyles.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(96, 40),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
