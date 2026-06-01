import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../data/remote/area_detail.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/rate_fetch_service.dart';
import '../../data/services/rate_service.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'area_detail_dialog_data.dart';
import 'area_dialog_loader.dart';
import 'area_dialog_shell.dart';
import 'area_parking_layout_section.dart';
import 'branch_rates_dialog.dart';

/// Parking slot grid from `GET /branches/{id}/areas/{areaId}` (`levels[]`).
Future<void> showAreaParkingSlotsDialog(
  BuildContext context, {
  required AuthRepository authRepository,
  required RateFetchService rateFetchService,
  required RateService rateService,
  required String branchName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AreaDialogShell(
        maxHeight: 560,
        child: AreaDialogLoader(
          authRepository: authRepository,
          rateFetchService: rateFetchService,
          rateService: rateService,
          purpose: BranchAreaDialogPurpose.parkingSlots,
          allowOfflineFallback: false,
          builder: (context, result, retry) {
            if (result.hasError) {
              return AreaDialogErrorBody(
                title: 'Parking Slots',
                branchName: branchName,
                message: result.errorMessage!,
                onRetry: retry,
              );
            }
            final data = result.data!;
            if (data.levels.isEmpty) {
              return _EmptyParkingSlots(
                branchName: branchName,
                onRetry: retry,
              );
            }
            return _ParkingSlotsDialogContent(
              branchName: branchName,
              levels: data.levels,
            );
          },
        ),
      );
    },
  );
}

class ParkingSlotsOutlinePill extends StatelessWidget {
  const ParkingSlotsOutlinePill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const Color _border = Color(0xFF6C7688);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _border.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.layoutGrid, size: 14, color: _border),
              const SizedBox(width: 6),
              Text(
                'Slots',
                style: DashboardStyles.headerPillLabel().copyWith(
                  color: _border,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyParkingSlots extends StatelessWidget {
  const _EmptyParkingSlots({
    required this.branchName,
    required this.onRetry,
  });

  final String branchName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Parking Slots', style: branchRatesDialogTitleStyle()),
        const SizedBox(height: 2),
        Text(branchName, style: branchRatesDialogSubtitleStyle()),
        const SizedBox(height: 12),
        Text(
          'No parking levels are configured for this area yet.',
          style: branchRatesDialogSubtitleStyle(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: branchRatesDialogCloseStyle()),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: branchRatesDialogCloseStyle()),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParkingSlotsDialogContent extends StatefulWidget {
  const _ParkingSlotsDialogContent({
    required this.branchName,
    required this.levels,
  });

  final String branchName;
  final List<AreaParkingLevel> levels;

  @override
  State<_ParkingSlotsDialogContent> createState() =>
      _ParkingSlotsDialogContentState();
}

class _ParkingSlotsDialogContentState extends State<_ParkingSlotsDialogContent> {
  late String _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _selectedLevelId = widget.levels.first.id;
  }

  AreaParkingLevel get _selectedLevel {
    for (final level in widget.levels) {
      if (level.id == _selectedLevelId) return level;
    }
    return widget.levels.first;
  }

  @override
  Widget build(BuildContext context) {
    final level = _selectedLevel;
    final showLevelPicker = widget.levels.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Parking Slots', style: branchRatesDialogTitleStyle()),
        const SizedBox(height: 2),
        Text(widget.branchName, style: branchRatesDialogSubtitleStyle()),
        const SizedBox(height: 12),
        if (showLevelPicker) ...[
          Text('LEVEL', style: branchRatesSectionCapsStyle()),
          const SizedBox(height: 8),
          AreaParkingLevelDropdown(
            levels: widget.levels,
            selectedId: _selectedLevelId,
            onChanged: (id) {
              if (id == null) return;
              setState(() => _selectedLevelId = id);
            },
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: AreaParkingLevelPanel(
              level: level,
              showTitle: !showLevelPicker,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: branchRatesDialogCloseStyle()),
          ),
        ),
      ],
    );
  }
}

/// Level picker styled like the vehicle-type dropdown in branch rates.
class AreaParkingLevelDropdown extends StatelessWidget {
  const AreaParkingLevelDropdown({
    super.key,
    required this.levels,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AreaParkingLevel> levels;
  final String selectedId;
  final ValueChanged<String?> onChanged;

  static const Color _border = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF0A1B39),
            size: 22,
          ),
          hint: Text('Select level', style: _hint()),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: [
            for (final level in levels)
              DropdownMenuItem<String>(
                value: level.id,
                child: Text(
                  '${level.name} (${level.availableCount} free)',
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  TextStyle _hint() => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: DashboardStyles.grey500,
      );
}
