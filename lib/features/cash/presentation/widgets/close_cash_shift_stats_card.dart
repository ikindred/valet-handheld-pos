import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/close_cash_shift_stats.dart';
import 'cash_figma_text_styles.dart';

class CloseCashShiftStatsCard extends StatelessWidget {
  const CloseCashShiftStatsCard({
    super.key,
    required this.stats,
    required this.activeCheckInCount,
    this.accentColor = const Color(0xFFE8831A),
  });

  final CloseCashShiftStats stats;
  final int activeCheckInCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ACTIVE CHECK-INS', style: CashFigmaStyles.sectionCaps()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: activeCheckInCount > 0
                  ? const Color(0xFFFFF4F0)
                  : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeCheckInCount > 0
                    ? AppColors.error.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Active check-ins',
                    style: CashFigmaStyles.fieldLabel(),
                  ),
                ),
                Text(
                  '$activeCheckInCount',
                  style: CashFigmaStyles.openingAmountInline().copyWith(
                    color: activeCheckInCount > 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          if (activeCheckInCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Vehicles still checked in. They stay on the server for the next '
              'cashier once all check-ins and checkouts are synced.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          Text('SHIFT CHECKOUTS', style: CashFigmaStyles.sectionCaps()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total checkouts',
                    style: CashFigmaStyles.fieldLabel(),
                  ),
                ),
                Text(
                  '${stats.checkoutCount}',
                  style: CashFigmaStyles.openingAmountInline().copyWith(
                    color: accentColor,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('BY VEHICLE TYPE', style: CashFigmaStyles.fieldLabel()),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final cardWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final stat in stats.vehicleTypes)
                    SizedBox(
                      width: cardWidth,
                      child: _VehicleTypeCard(
                        stat: stat,
                        accentColor: accentColor,
                      ),
                    ),
                ],
              );
            },
          ),
          if (stats.checkoutCount == 0) ...[
            const SizedBox(height: 10),
            Text(
              'No checkouts recorded since this shift opened.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.stat,
    required this.accentColor,
  });

  final CloseCashVehicleTypeStat stat;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasCount = stat.count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: hasCount ? const Color(0xFFFFF7EC) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCount
              ? accentColor.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.label,
              style: CashFigmaStyles.fieldValue().copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${stat.count}',
            style: CashFigmaStyles.fieldValue().copyWith(
              fontWeight: FontWeight.w700,
              color: hasCount ? accentColor : AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
