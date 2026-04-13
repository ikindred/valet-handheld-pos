import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/vehicle_damage.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_footer_actions.dart';
import 'widgets/check_in_step_body.dart';
import 'widgets/customer_signature_modal.dart';
import 'widgets/vehicle_condition_diagram.dart';

const _kGrey500 = Color(0xFF6C7688);
const _kBorder = Color(0xFFC0C0BF);

class CheckInVehicleConditionScreen extends StatelessWidget {
  const CheckInVehicleConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      scrollable: false,
      footer: BlocBuilder<CheckInCubit, CheckInState>(
        buildWhen: (prev, next) =>
            prev.hasCustomerSignature != next.hasCustomerSignature,
        builder: (context, state) {
          return CheckInVehicleConditionFooter(
            hasCustomerSignature: state.hasCustomerSignature,
            onCancel: () {
              context.read<CheckInCubit>().resetSession();
              context.go('/dashboard');
            },
            onSignature: () => showCustomerSignatureModal(context),
            onBack: () => context.go('/check-in/step-2'),
            onNext: () {
              final signed = state.hasCustomerSignature;
              if (signed) {
                context.go('/check-in/step-4');
              } else {
                showCustomerSignatureModal(context);
              }
            },
          );
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _DiagramPanel()),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: _DamageSidePanel()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _DiagramPanel()),
              const SizedBox(height: 20),
              Expanded(flex: 4, child: _DamageSidePanel()),
            ],
          );
        },
      ),
    );
  }
}

class _DiagramPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) =>
          a.vehicleDamageEntries != b.vehicleDamageEntries ||
          a.selectedDamageType != b.selectedDamageType,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TAP DIAGRAM TO MARK DAMAGE',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _kGrey500,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Selected: ',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0x936C7688),
                    ),
                  ),
                  TextSpan(
                    text: state.selectedDamageType.label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedTypeAccent(state.selectedDamageType),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.13),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: VehicleConditionDiagram(
                      entries: state.vehicleDamageEntries,
                      onImageTap: (nx, ny) {
                        context.read<CheckInCubit>().addDamageAt(nx, ny);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _selectedTypeAccent(DamageType t) {
  switch (t) {
    case DamageType.crack:
      return const Color(0xFF0068D3);
    case DamageType.scratch:
      return const Color(0xFFF68D00);
    case DamageType.dent:
      return const Color(0xFFEC2231);
  }
}

/// Selected-state fill / border / label for MARK DAMAGE TYPE buttons (aligned with diagram markers).
({Color fill, Color border, Color foreground}) _damageTypeButtonSelectedStyle(
  DamageType t,
) {
  switch (t) {
    case DamageType.crack:
      return (
        fill: const Color(0xFFECEEFF),
        border: const Color(0xFF0068D3),
        foreground: const Color(0xFF0068D3),
      );
    case DamageType.scratch:
      return (
        fill: const Color(0xFFFFF4EC),
        border: const Color(0xFFF68D00),
        foreground: const Color(0xFFF68D00),
      );
    case DamageType.dent:
      return (
        fill: const Color(0xFFFFECEC),
        border: const Color(0xFFEC2231),
        foreground: const Color(0xFFEC2231),
      );
  }
}

class _DamageSidePanel extends StatelessWidget {
  const _DamageSidePanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) =>
          a.vehicleDamageEntries != b.vehicleDamageEntries ||
          a.selectedDamageType != b.selectedDamageType,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MARK DAMAGE TYPE',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _kGrey500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _DamageTypeButton(
                      type: DamageType.crack,
                      selected: state.selectedDamageType == DamageType.crack,
                      onTap: () => context
                          .read<CheckInCubit>()
                          .selectDamageType(DamageType.crack),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DamageTypeButton(
                      type: DamageType.scratch,
                      selected: state.selectedDamageType == DamageType.scratch,
                      onTap: () => context
                          .read<CheckInCubit>()
                          .selectDamageType(DamageType.scratch),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DamageTypeButton(
                      type: DamageType.dent,
                      selected: state.selectedDamageType == DamageType.dent,
                      onTap: () => context
                          .read<CheckInCubit>()
                          .selectDamageType(DamageType.dent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'LOGGED DAMAGE (${state.vehicleDamageEntries.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kGrey500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: state.vehicleDamageEntries.isEmpty
                      ? null
                      : () => context.read<CheckInCubit>().clearLoggedDamage(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear logged damage',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.vehicleDamageEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No damage logged yet.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.vehicleDamageEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = state.vehicleDamageEntries[i];
                        return _LoggedDamageRow(
                          entry: e,
                          onDelete: () =>
                              context.read<CheckInCubit>().removeDamage(e.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DamageTypeButton extends StatelessWidget {
  const _DamageTypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DamageType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _damageTypeButtonSelectedStyle(type);
    final fill = selected ? style.fill : Colors.white;
    final border = selected ? style.border : _kBorder;
    final fg = selected ? style.foreground : AppColors.textPrimary;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox.expand(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              type.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoggedDamageRow extends StatelessWidget {
  const _LoggedDamageRow({required this.entry, required this.onDelete});

  final VehicleDamageEntry entry;
  final VoidCallback onDelete;

  static Color _dot(DamageType t) {
    switch (t) {
      case DamageType.crack:
        return const Color(0xFF0068D3);
      case DamageType.scratch:
        return const Color(0xFFF68D00);
      case DamageType.dent:
        return const Color(0xFFEC2231);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        entry.zoneLabel ??
        '${(entry.normalizedX * 100).round()}%, ${(entry.normalizedY * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0x7F0A1B39),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 22),
            color: AppColors.textSecondary,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
