import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'parking_slot_status_style.dart';

/// Fixed card size for the parking slots grid (modal + layouts).
abstract final class ParkingSlotCardMetrics {
  static const double height = 56;
  static const double gap = 8;
  static const double minTileWidth = 76;
  static const int minColumns = 4;
  static const int maxColumns = 6;
}

/// One level: title, availability summary, and uniform slot cards.
class AreaParkingLevelPanel extends StatelessWidget {
  const AreaParkingLevelPanel({
    super.key,
    required this.level,
    this.showTitle = true,
  });

  final AreaParkingLevel level;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final slots = level.slots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Expanded(child: Text(level.name, style: _levelTitle())),
              Text(
                '${level.availableCount} available · ${level.occupiedCount} occupied',
                style: _levelMeta(),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = _columnCount(constraints.maxWidth);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: ParkingSlotCardMetrics.gap,
                crossAxisSpacing: ParkingSlotCardMetrics.gap,
                mainAxisExtent: ParkingSlotCardMetrics.height,
              ),
              itemBuilder: (context, index) =>
                  ParkingSlotCard(slot: slots[index]),
            );
          },
        ),
      ],
    );
  }

  static int _columnCount(double maxWidth) {
    if (maxWidth <= 0) return ParkingSlotCardMetrics.minColumns;
    final cols = ((maxWidth + ParkingSlotCardMetrics.gap) /
            (ParkingSlotCardMetrics.minTileWidth + ParkingSlotCardMetrics.gap))
        .floor();
    return cols.clamp(
      ParkingSlotCardMetrics.minColumns,
      ParkingSlotCardMetrics.maxColumns,
    );
  }
}

/// All levels stacked (legacy combined modal).
class AreaParkingLayoutSection extends StatelessWidget {
  const AreaParkingLayoutSection({
    super.key,
    required this.levels,
    this.title = 'PARKING SLOTS',
  });

  final List<AreaParkingLevel> levels;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: _sectionCaps()),
        const SizedBox(height: 8),
        for (var i = 0; i < levels.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          AreaParkingLevelPanel(level: levels[i]),
        ],
      ],
    );
  }
}

/// Uniform slot card — label + status, green available / red occupied.
class ParkingSlotCard extends StatelessWidget {
  const ParkingSlotCard({super.key, required this.slot});

  final AreaParkingSlot slot;

  @override
  Widget build(BuildContext context) {
    final statusColor = ParkingSlotStatusStyle.textFor(slot);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ParkingSlotStatusStyle.backgroundFor(slot),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ParkingSlotStatusStyle.borderFor(slot),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    ParkingSlotStatusStyle.statusLabel(slot),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: statusColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _sectionCaps() => GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    );

TextStyle _levelTitle() => GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

TextStyle _levelMeta() => GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: DashboardStyles.grey500,
    );
