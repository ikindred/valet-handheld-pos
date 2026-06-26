import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/vehicle_damage.dart';
import '../state/check_in_cubit.dart';
import 'check_in_flow_exit.dart';
import 'widgets/check_in_compact_tokens.dart';
import 'widgets/check_in_footer_actions.dart';
import 'widgets/check_in_step_body.dart';
import 'widgets/customer_signature_modal.dart';
import 'widgets/vehicle_condition_diagram.dart';

class CheckInVehicleConditionScreen extends StatelessWidget {
  const CheckInVehicleConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      scrollable: false,
      footer: BlocBuilder<CheckInCubit, CheckInState>(
        buildWhen: (prev, next) =>
            prev.isCustomerSignatureComplete != next.isCustomerSignatureComplete,
        builder: (context, state) {
          final signed = state.isCustomerSignatureComplete;
          return CheckInVehicleConditionFooter(
            hasCustomerSignature: signed,
            onCancel: () => exitCheckInToDashboard(context),
            onSignature: () => showCustomerSignatureModal(context),
            onBack: () => context.go('/check-in/step-3'),
            onNext: () {
              if (!signed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Customer signature is required before continuing.',
                    ),
                  ),
                );
                showCustomerSignatureModal(context);
                return;
              }
              context.go('/check-in/step-5');
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
                const SizedBox(width: CheckInCompactTokens.fieldGap),
                Expanded(flex: 4, child: _DamageSidePanel()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: _DiagramPanel()),
              const SizedBox(height: CheckInCompactTokens.blockGap),
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
              style: CheckInCompactTokens.sectionTitleOf(context),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Selected: ',
                    style: CheckInCompactTokens.bodyHintOf(context),
                  ),
                  TextSpan(
                    text: state.selectedDamageType.label,
                    style: CheckInCompactTokens.fieldValueOf(context).copyWith(
                      color: _selectedTypeAccent(state.selectedDamageType),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppThemeColors.of(context).cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppThemeColors.of(context).cardBorder,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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

/// Selected-state fill / border / label for MARK DAMAGE TYPE buttons.
({Color fill, Color border, Color foreground}) _damageTypeButtonStyle(
  BuildContext context,
  DamageType t, {
  required bool selected,
}) {
  final tc = AppThemeColors.of(context);
  if (!selected) {
    return (fill: tc.cardBg, border: tc.cardBorder, foreground: tc.textPrimary);
  }
  if (AppThemeColors.isDark(context)) {
    return switch (t) {
      DamageType.crack => (
          fill: const Color(0xFF1E3A5F),
          border: const Color(0xFF60A5FA),
          foreground: const Color(0xFF60A5FA),
        ),
      DamageType.scratch => (
          fill: const Color(0xFF422006),
          border: const Color(0xFFFBBF24),
          foreground: const Color(0xFFFBBF24),
        ),
      DamageType.dent => (
          fill: const Color(0xFF3D1F24),
          border: const Color(0xFFF87171),
          foreground: const Color(0xFFF87171),
        ),
    };
  }
  return switch (t) {
    DamageType.crack => (
        fill: const Color(0xFFECEEFF),
        border: const Color(0xFF0068D3),
        foreground: const Color(0xFF0068D3),
      ),
    DamageType.scratch => (
        fill: const Color(0xFFFFF4EC),
        border: const Color(0xFFF68D00),
        foreground: const Color(0xFFF68D00),
      ),
    DamageType.dent => (
        fill: const Color(0xFFFFECEC),
        border: const Color(0xFFEC2231),
        foreground: const Color(0xFFEC2231),
      ),
  };
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
              style: CheckInCompactTokens.sectionTitleOf(context),
            ),
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            SizedBox(
              height: CheckInCompactTokens.damageTypeButtonHeight,
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
                  const SizedBox(width: CheckInCompactTokens.bodyTypeGridGap),
                  Expanded(
                    child: _DamageTypeButton(
                      type: DamageType.scratch,
                      selected: state.selectedDamageType == DamageType.scratch,
                      onTap: () => context
                          .read<CheckInCubit>()
                          .selectDamageType(DamageType.scratch),
                    ),
                  ),
                  const SizedBox(width: CheckInCompactTokens.bodyTypeGridGap),
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
            const SizedBox(height: CheckInCompactTokens.blockGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'LOGGED DAMAGE (${state.vehicleDamageEntries.length})',
                    style: CheckInCompactTokens.sectionTitleOf(context),
                  ),
                ),
                TextButton(
                  onPressed: state.vehicleDamageEntries.isEmpty
                      ? null
                      : () => context.read<CheckInCubit>().clearLoggedDamage(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppThemeColors.of(context).textPrimary,
                    disabledForegroundColor:
                        AppThemeColors.of(context).textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear logged damage',
                    style: CheckInCompactTokens.bodyHintOf(context).copyWith(
                      color: AppThemeColors.of(context).textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            Expanded(
              child: state.vehicleDamageEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No damage logged yet.',
                        style: CheckInCompactTokens.bodyHintOf(context),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.vehicleDamageEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
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
    final style = _damageTypeButtonStyle(context, type, selected: selected);

    return Material(
      color: style.fill,
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
              border: Border.all(color: style.border, width: 1),
            ),
            child: Text(
              type.label,
              textAlign: TextAlign.center,
              style: CheckInCompactTokens.fieldValueOf(context).copyWith(
                fontWeight: FontWeight.w500,
                color: style.foreground,
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

    final tc = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _dot(entry.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: CheckInCompactTokens.fieldValueOf(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: CheckInCompactTokens.helperText().copyWith(
                    color: tc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: tc.textSecondary,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
