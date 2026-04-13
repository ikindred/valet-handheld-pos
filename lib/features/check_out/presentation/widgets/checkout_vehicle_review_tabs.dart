import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';

/// Figma: VEHICLE REVIEW — **VEHICLE INFO** | **CONDITION CHECK** tabs.
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

  static const _grey500 = Color(0xFF6C7688);
  static const _mutedTab = Color(0xFFA09E9E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VEHICLE REVIEW',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _grey500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _tabInk(
              text: 'VEHICLE INFO',
              selected: vehicleInfoSelected,
              onTap: onVehicleInfoTap,
            ),
            const SizedBox(width: 28),
            _tabInk(
              text: 'CONDITION CHECK',
              selected: !vehicleInfoSelected,
              onTap: onConditionTap,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 117,
              height: 3,
              decoration: BoxDecoration(
                color: vehicleInfoSelected
                    ? DashboardStyles.orange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 28),
            SizedBox(
              width: 140,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: !vehicleInfoSelected
                      ? DashboardStyles.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabInk({
    required String text,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final child = _TabLabel(
      text: text,
      selected: selected,
      activeColor: DashboardStyles.orange,
      inactiveColor: _mutedTab,
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.text,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String text;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? activeColor : inactiveColor,
      ),
    );
  }
}
