import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/check_in_step_body.dart';

class CheckInVehicleConditionSignedScreen extends StatelessWidget {
  const CheckInVehicleConditionSignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: () => context.go('/check-in/step-4'),
      primaryLabel: 'Next: Review & Print',
      onPrimary: () => context.go('/check-in/step-6'),
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Signed confirmation — UI placeholder (Figma step 5).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
