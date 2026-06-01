import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_bloc.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../routing/check_out_step.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_flow_header.dart';

class CheckOutShell extends StatefulWidget {
  const CheckOutShell({super.key, required this.child});

  final Widget child;

  @override
  State<CheckOutShell> createState() => _CheckOutShellState();
}

class _CheckOutShellState extends State<CheckOutShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CheckOutCubit>();
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        cubit.setRates(auth.standardRates);
      }
      unawaited(cubit.hydrateBranchRatesFromDrift());
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final stepIndex = checkOutStepIndexFromPath(path);

    return Scaffold(
      backgroundColor: AppThemeColors.of(context).scaffoldBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardLeftRail(),
          Expanded(
            child: SafeArea(
              left: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckOutFlowHeader(stepIndex: stepIndex),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
