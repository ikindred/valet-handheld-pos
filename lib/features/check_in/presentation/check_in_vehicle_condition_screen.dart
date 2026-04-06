import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/check_in_step_body.dart';

class CheckInVehicleConditionScreen extends StatelessWidget {
  const CheckInVehicleConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: () => context.go('/check-in/step-2'),
      primaryLabel: 'Next: Signature',
      onPrimary: () => context.go('/check-in/step-4'),
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Vehicle condition — UI placeholder (Figma step 3).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
