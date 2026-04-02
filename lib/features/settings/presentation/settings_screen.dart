import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/state/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () async {
                  final choice = await showDialog<_LogoutChoice>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Do you want to close cash before logging out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(_LogoutChoice.logoutOnly),
                          child: const Text('Logout only'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(_LogoutChoice.closeCashAndLogout),
                          child: const Text('Close cash & logout'),
                        ),
                      ],
                    ),
                  );

                  if (!context.mounted) return;
                  if (choice == null) return;

                  if (choice == _LogoutChoice.closeCashAndLogout) {
                    context.go('/cash/close');
                    return;
                  }

                  context.read<AuthBloc>().add(const AuthLoggedOut());
                  context.go('/login');
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LogoutChoice {
  closeCashAndLogout,
  logoutOnly,
}

