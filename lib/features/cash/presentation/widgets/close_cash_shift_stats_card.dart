import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/close_cash_shift_stats.dart';
import 'cash_figma_text_styles.dart';

class CloseCashShiftStatsCard extends StatelessWidget {
  const CloseCashShiftStatsCard({
    super.key,
    required this.stats,
    this.accentColor = const Color(0xFFF68D00),
    this.hideVehicleTypes = false,
  });

  final CloseCashShiftStats stats;
  final Color accentColor;
  final bool hideVehicleTypes;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.cardBorder),
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
          Text(
            'SHIFT CHECKOUTS',
            style: CashFigmaStyles.sectionCaps().copyWith(
              color: tc.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tc.accentSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total checkouts',
                    style: CashFigmaStyles.fieldLabel().copyWith(
                      color: tc.textSecondary,
                    ),
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
          if (!hideVehicleTypes) ...[
            Text(
              'BY VEHICLE TYPE',
              style: CashFigmaStyles.fieldLabel().copyWith(
                color: tc.textSecondary,
              ),
            ),
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
          ],
          if (stats.checkoutCount == 0) ...[
            const SizedBox(height: 10),
            Text(
              'No checkouts recorded since this shift opened.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tc.textSecondary,
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
    final tc = AppThemeColors.of(context);
    final hasCount = stat.count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: hasCount ? tc.accentSurface : tc.hintFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCount
              ? accentColor.withValues(alpha: 0.35)
              : tc.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.label,
              style: CashFigmaStyles.fieldValue().copyWith(
                fontSize: 12,
                color: tc.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${stat.count}',
            style: CashFigmaStyles.fieldValue().copyWith(
              fontWeight: FontWeight.w700,
              color: hasCount ? accentColor : tc.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
