import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../routing/check_in_step.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_flow_header.dart';

class CheckInShell extends StatefulWidget {
  const CheckInShell({super.key, required this.child});

  final Widget child;

  @override
  State<CheckInShell> createState() => _CheckInShellState();
}

class _CheckInShellState extends State<CheckInShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CheckInCubit>().ensureTicket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final stepIndex = checkInStepIndexFromPath(path);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
                  CheckInFlowHeader(stepIndex: stepIndex),
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
