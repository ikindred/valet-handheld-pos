import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/check_in_step_body.dart';

class CheckInVehicleDetailsScreen extends StatelessWidget {
  const CheckInVehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: () => context.go('/check-in/step-1'),
      primaryLabel: 'Next: Vehicle Condition',
      onPrimary: () => context.go('/check-in/step-3'),
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Vehicle details — UI placeholder (Figma step 2).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
