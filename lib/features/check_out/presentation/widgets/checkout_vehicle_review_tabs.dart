import 'package:flutter/material.dart';

import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import 'check_out_ui_tokens.dart';

/// VEHICLE REVIEW — **VEHICLE INFO** | **CONDITION CHECK** tabs (compact).
class CheckoutVehicleReviewTabs extends StatelessWidget {
  const CheckoutVehicleReviewTabs({
    super.key,
    required this.vehicleInfoSelected,
    this.onVehicleInfoTap,
    this.onConditionTap,
  });

  final bool vehicleInfoSelected;
  final VoidCallback? onVehicleInfoTap;
  final VoidCallback? onConditionTap;

  static const _tabGap = 24.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReviewTab(
          label: 'VEHICLE INFO',
          selected: vehicleInfoSelected,
          onTap: onVehicleInfoTap,
        ),
        const SizedBox(width: _tabGap),
        _ReviewTab(
          label: 'CONDITION CHECK',
          selected: !vehicleInfoSelected,
          onTap: onConditionTap,
        ),
      ],
    );
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tab = IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CheckOutUiTokens.tabLabelOf(context, selected: selected),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 2,
            decoration: BoxDecoration(
              color: selected ? DashboardStyles.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tab;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: tab,
        ),
      ),
    );
  }
}
