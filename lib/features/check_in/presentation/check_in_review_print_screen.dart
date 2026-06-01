import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/valet_log.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import 'widgets/check_in_footer_actions.dart';
import '../domain/vehicle_body_type.dart';
import '../domain/vehicle_damage.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_compact_tokens.dart';
import 'widgets/check_in_step_body.dart';

/// Step 5 — Review (confirm saves ticket, then `/check-in/print`).
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=32-861)).
class CheckInReviewPrintScreen extends StatefulWidget {
  const CheckInReviewPrintScreen({super.key});

  @override
  State<CheckInReviewPrintScreen> createState() =>
      _CheckInReviewPrintScreenState();
}

class _CheckInReviewPrintScreenState extends State<CheckInReviewPrintScreen> {
  /// Two-column grid (customer+vehicle | condition+time).
  static const double _wideBreakpoint = 680.0;

  /// Two-column fallback for narrow landscape.
  static const double _mediumBreakpoint = 480.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final signed =
          context.read<CheckInCubit>().state.isCustomerSignatureComplete;
      if (!signed) {
        context.go('/check-in/step-4');
      }
    });
  }

  Future<void> _commitAndLeave() async {
    if (!mounted) return;
    final cubit = context.read<CheckInCubit>();
    if (!cubit.state.isCustomerSignatureComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer signature is required.'),
        ),
      );
      context.go('/check-in/step-4');
      return;
    }
    if (cubit.state.isSubmitting) return;
    ValetLog.info(
      'check_in/review_print/_commitAndLeave',
      'start check-in confirm',
    );
    await cubit.confirmCheckIn(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (prev, next) => prev.isSubmitting != next.isSubmitting,
      builder: (context, submitState) {
        return CheckInStepBody(
          showBack: true,
          onBack: submitState.isSubmitting
              ? () {}
              : () => context.go('/check-in/step-4'),
          footer: CheckInFooterActions(
            onCancel: () {
              if (!submitState.isSubmitting) {
                context.read<CheckInCubit>().resetSession();
                context.go('/dashboard');
              }
            },
            showBack: true,
            onBack: submitState.isSubmitting
                ? () {}
                : () => context.go('/check-in/step-4'),
            primaryLabel: 'Confirm',
            onPrimary: () => unawaited(_commitAndLeave()),
            primaryBusy: submitState.isSubmitting,
          ),
          child: BlocBuilder<CheckInCubit, CheckInState>(
            builder: (context, state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  if (w >= _wideBreakpoint) {
                    return _ReviewWideGrid(state: state);
                  }
                  if (w >= _mediumBreakpoint) {
                    return _ReviewMediumGrid(state: state);
                  }
                  return _ReviewNarrowStack(state: state);
                },
              );
            },
          ),
        );
      },
    );
  }

}

// --- Data helpers ---

String _valetTypeLabel(ValetServiceType t) {
  return switch (t) {
    ValetServiceType.standardValet => 'Standard Valet',
    ValetServiceType.selfPark => 'Self Park',
  };
}

String _vehicleLine(CheckInState s) {
  final parts = <String>[
    if (s.vehicleBrand.trim().isNotEmpty) s.vehicleBrand.trim(),
    if (s.vehicleColor.trim().isNotEmpty) s.vehicleColor.trim(),
    if (s.vehicleVrNo.trim().isNotEmpty) s.vehicleVrNo.trim(),
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _belongingsLine(CheckInState s) {
  final parts = <String>[...s.selectedBelongings];
  if (s.otherBelongings.trim().isNotEmpty) {
    parts.add(s.otherBelongings.trim());
  }
  if (parts.isEmpty) return 'None declared';
  return parts.join(', ');
}

String _slotLine(CheckInState s) {
  final a = s.parkingLevel.trim();
  final b = s.parkingSlot.trim();
  if (a.isEmpty && b.isEmpty) return '—';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a · $b';
}

String _timeInFormatted(DateTime? d) {
  final dt = d ?? DateTime.now();
  return DateFormat('MMMM d, yyyy · h:mm a').format(dt);
}

// --- Layout grids (two columns on tablet) ---

class _ReviewWideGrid extends StatelessWidget {
  const _ReviewWideGrid({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CustomerValetCard(state: state),
              const SizedBox(height: CheckInCompactTokens.fieldGap),
              _VehicleCard(state: state),
            ],
          ),
        ),
        const SizedBox(width: CheckInCompactTokens.fieldGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConditionLogCard(state: state),
              const SizedBox(height: CheckInCompactTokens.fieldGap),
              _TimeCard(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewMediumGrid extends StatelessWidget {
  const _ReviewMediumGrid({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _CustomerValetCard(state: state),
                  const SizedBox(height: CheckInCompactTokens.fieldGap),
                  _VehicleCard(state: state),
                ],
              ),
            ),
            const SizedBox(width: CheckInCompactTokens.fieldGap),
            Expanded(
              child: Column(
                children: [
                  _ConditionLogCard(state: state),
                  const SizedBox(height: CheckInCompactTokens.fieldGap),
                  _TimeCard(state: state),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewNarrowStack extends StatelessWidget {
  const _ReviewNarrowStack({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerValetCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _ConditionLogCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _VehicleCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _TimeCard(state: state),
      ],
    );
  }
}

// --- Shared styles ---

class _ReviewTokens {
  static const cardRadius = 10.0;

  static TextStyle sectionTitle(BuildContext context) =>
      CheckInCompactTokens.pageHeadingOf(context);

  static TextStyle label(BuildContext context) =>
      CheckInCompactTokens.helperText().copyWith(
        fontWeight: FontWeight.w500,
        color: AppThemeColors.of(context).textSecondary,
      );

  static TextStyle value(BuildContext context) =>
      CheckInCompactTokens.fieldValueOf(context).copyWith(
        fontWeight: FontWeight.w500,
      );

  static TextStyle plateValue(BuildContext context) =>
      CheckInCompactTokens.fieldValueOf(context).copyWith(
        fontWeight: FontWeight.w700,
        color: DashboardStyles.plateBlue,
      );

  static TextStyle damageCount(BuildContext context) =>
      CheckInCompactTokens.bodyHintOf(context);
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.borderRadius,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final double borderRadius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: tc.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: _ReviewTokens.label(context)),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: valueStyle ?? _ReviewTokens.value(context),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 6),
          Container(height: 1, color: AppThemeColors.of(context).cardBorder),
        ],
      ],
    );
  }
}

// --- Cards ---

class _CustomerValetCard extends StatelessWidget {
  const _CustomerValetCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final special = state.specialInstructions.trim();
    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CUSTOMER & VALET', style: _ReviewTokens.sectionTitle(context)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Name',
            value: state.customerFullName.trim().isEmpty
                ? '—'
                : state.customerFullName.trim(),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Contact',
            value: state.contactNumber.trim().isEmpty
                ? '—'
                : state.contactNumber.trim(),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Valet Type',
            value: _valetTypeLabel(state.valetServiceType),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Valet Driver',
            value: state.assignedValetDriver.trim().isEmpty
                ? '—'
                : state.assignedValetDriver.trim(),
            showDivider: special.isNotEmpty,
          ),
          if (special.isNotEmpty) ...[
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            _ReviewRow(
              label: 'Special Request',
              value: special,
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _DamageChip extends StatelessWidget {
  const _DamageChip({required this.entry});

  final VehicleDamageEntry entry;

  static const _dentFg = Color(0xFFEC2231);
  static const _scratchFg = Color(0xFFF68D00);
  static const _crackFg = Color(0xFF0068D3);

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeColors.isDark(context);
    final (fg, bg) = switch (entry.type) {
      DamageType.dent => (
          _dentFg,
          isDark ? const Color(0xFF3D1F24) : const Color(0xFFFFECEC),
        ),
      DamageType.scratch => (
          _scratchFg,
          isDark ? const Color(0xFF422006) : const Color(0xFFFFF7EC),
        ),
      DamageType.crack => (
          _crackFg,
          isDark ? const Color(0xFF1E3A5F) : const Color(0xFFECEFFF),
        ),
    };
    final zone = entry.zoneLabel?.trim();
    final text = (zone != null && zone.isNotEmpty)
        ? '${entry.type.label} - $zone'
        : entry.type.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: fg),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _ConditionLogCard extends StatelessWidget {
  const _ConditionLogCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final n = state.vehicleDamageEntries.length;
    final countLabel = n == 1 ? '1 item marked' : '$n items marked';

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONDITION LOG', style: _ReviewTokens.sectionTitle(context)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          Text(countLabel, style: _ReviewTokens.damageCount(context)),
          if (state.vehicleDamageEntries.isNotEmpty) ...[
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in state.vehicleDamageEntries)
                  _DamageChip(entry: e),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text('No damage logged.', style: _ReviewTokens.label(context)),
          ],
          const SizedBox(height: CheckInCompactTokens.blockGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Customer signature',
                  style: _ReviewTokens.label(context),
                ),
              ),
              Text(
                state.isCustomerSignatureComplete ? 'Signed ✓' : 'Not signed',
                style: _ReviewTokens.value(context).copyWith(
                  color: state.isCustomerSignatureComplete
                      ? DashboardStyles.green
                      : AppThemeColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final plate = state.plateNumber.trim().isEmpty
        ? '—'
        : state.plateNumber.trim();

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEHICLE', style: _ReviewTokens.sectionTitle(context)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Plate No.',
            value: plate,
            valueStyle: plate == '—'
                ? _ReviewTokens.value(context)
                : _ReviewTokens.plateValue(context),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Vehicle', value: _vehicleLine(state)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Type',
            value: state.vehicleBodyType.label,
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Slot', value: _slotLine(state)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Belongings',
            value: _belongingsLine(state),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final ticket = state.ticketNumber.trim().isEmpty
        ? '—'
        : state.ticketNumber.trim();

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIME', style: _ReviewTokens.sectionTitle(context)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Time In',
            value: _timeInFormatted(state.dateTimeIn),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Ticket No.', value: ticket, showDivider: false),
        ],
      ),
    );
  }
}
