import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy route: payment is collected on [CheckOutPaymentSummaryScreen] (step 4).
class CheckOutPaymentCollectScreen extends StatefulWidget {
  const CheckOutPaymentCollectScreen({super.key});

  @override
  State<CheckOutPaymentCollectScreen> createState() =>
      _CheckOutPaymentCollectScreenState();
}

class _CheckOutPaymentCollectScreenState
    extends State<CheckOutPaymentCollectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/check-out/step-4');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
