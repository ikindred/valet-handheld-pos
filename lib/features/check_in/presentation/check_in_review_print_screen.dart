import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../state/check_in_cubit.dart';
import 'widgets/check_in_step_body.dart';

class CheckInReviewPrintScreen extends StatelessWidget {
  const CheckInReviewPrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: () => context.go('/check-in/step-5'),
      primaryLabel: 'Done',
      onPrimary: () {
        context.read<CheckInCubit>().resetSession();
        context.go('/dashboard');
      },
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Review and print — UI placeholder (Figma step 6).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
