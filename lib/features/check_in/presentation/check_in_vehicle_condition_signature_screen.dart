import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/check_in_step_body.dart';

class CheckInVehicleConditionSignatureScreen extends StatelessWidget {
  const CheckInVehicleConditionSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: () => context.go('/check-in/step-3'),
      primaryLabel: 'Next: Signed',
      onPrimary: () => context.go('/check-in/step-5'),
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Signature capture — UI placeholder (Figma step 4).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
