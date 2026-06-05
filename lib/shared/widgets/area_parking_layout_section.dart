import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'parking_slot_status_style.dart';

/// One level: title, free/used counts, and slot chips.
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
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final slot in level.slots) _SlotChip(slot: slot)],
        ),
      ],
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

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot});

  final AreaParkingSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ParkingSlotStatusStyle.backgroundFor(slot),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ParkingSlotStatusStyle.borderFor(slot)),
      ),
      child: Text(
        slot.label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ParkingSlotStatusStyle.textFor(slot),
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
