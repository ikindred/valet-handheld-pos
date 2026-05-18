import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../../check_in/presentation/widgets/vehicle_condition_diagram.dart';
import '../../check_in/presentation/widgets/check_in_compact_tokens.dart';
import '../state/check_out_cubit.dart';
import 'widgets/check_out_add_issue_footer.dart';
import 'widgets/check_out_step_body.dart';
import 'widgets/check_out_ui_tokens.dart';

const _kBorder = Color(0xFFC0C0BF);

/// Checkout **Add new Issue** — same interaction model as [CheckInVehicleConditionScreen].
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=37-2503)).
class CheckOutAddIssueScreen extends StatefulWidget {
  const CheckOutAddIssueScreen({super.key});

  @override
  State<CheckOutAddIssueScreen> createState() => _CheckOutAddIssueScreenState();
}

class _CheckOutAddIssueScreenState extends State<CheckOutAddIssueScreen> {
  static const _uuid = Uuid();
  var _seeded = false;
  late List<VehicleDamageEntry> _draft;
  late DamageType _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final c = context.read<CheckOutCubit>();
    _draft = List.from(c.state.checkoutAddedDamage);
    _selected = c.state.selectedDamageType;
  }

  void _addAt(double nx, double ny) {
    final label = lookupVehicleZoneLabel(nx, ny);
    setState(() {
      _draft.add(
        VehicleDamageEntry(
          id: _uuid.v4(),
          normalizedX: nx,
          normalizedY: ny,
          type: _selected,
          zoneLabel: label,
        ),
      );
    });
  }

  void _remove(String id) {
    setState(() {
      _draft.removeWhere((e) => e.id == id);
    });
  }

  void _clearDraft() {
    setState(() {
      _draft = [];
    });
  }

  List<VehicleDamageEntry> get _diagramEntries {
    final c = context.read<CheckOutCubit>();
    return [...c.state.checkInDamage, ..._draft];
  }

  void _onSave() {
    final cubit = context.read<CheckOutCubit>();
    cubit.setSelectedDamage(_selected);
    cubit.applyCheckoutIssueSession(damage: List.from(_draft));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckOutCubit, CheckOutState>(
      buildWhen: (a, b) => a.ticket != b.ticket,
      builder: (context, state) {
        if (state.ticket == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/check-out/step-1');
          });
          return const SizedBox.shrink();
        }

        return CheckOutStepBody(
          scrollable: false,
          footer: CheckOutAddIssueFooter(
            onBack: () => context.pop(),
            onConfirm: _onSave,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _DiagramPanel(selected: _selected, entries: _diagramEntries, onTap: _addAt)),
                    const SizedBox(width: CheckInCompactTokens.columnDividerWidth),
                    Expanded(
                      flex: 4,
                      child: _DamageSidePanel(
                        draft: _draft,
                        selected: _selected,
                        onSelect: (t) => setState(() => _selected = t),
                        onRemove: _remove,
                        onClear: _draft.isEmpty ? null : _clearDraft,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _DiagramPanel(selected: _selected, entries: _diagramEntries, onTap: _addAt)),
                  const SizedBox(height: CheckInCompactTokens.blockGap),
                  Expanded(
                    flex: 4,
                    child: _DamageSidePanel(
                      draft: _draft,
                      selected: _selected,
                      onSelect: (t) => setState(() => _selected = t),
                      onRemove: _remove,
                      onClear: _draft.isEmpty ? null : _clearDraft,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DiagramPanel extends StatelessWidget {
  const _DiagramPanel({
    required this.selected,
    required this.entries,
    required this.onTap,
  });

  final DamageType selected;
  final List<VehicleDamageEntry> entries;
  final void Function(double nx, double ny) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TAP DIAGRAM TO MARK DAMAGE', style: CheckOutUiTokens.fieldLabel()),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Selected: ', style: CheckOutUiTokens.hint()),
              TextSpan(
                text: selected.label,
                style: CheckOutUiTokens.body().copyWith(
                  color: _selectedTypeAccent(selected),
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
                  entries: entries,
                  onImageTap: onTap,
                ),
              ),
            ),
          ),
        ),
      ],
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
  const _DamageSidePanel({
    required this.draft,
    required this.selected,
    required this.onSelect,
    required this.onRemove,
    required this.onClear,
  });

  final List<VehicleDamageEntry> draft;
  final DamageType selected;
  final void Function(DamageType) onSelect;
  final void Function(String id) onRemove;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MARK DAMAGE TYPE', style: CheckOutUiTokens.fieldLabel()),
        const SizedBox(height: 8),
        SizedBox(
          height: CheckInCompactTokens.damageTypeButtonHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DamageTypeButton(
                  type: DamageType.crack,
                  selected: selected == DamageType.crack,
                  onTap: () => onSelect(DamageType.crack),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DamageTypeButton(
                  type: DamageType.scratch,
                  selected: selected == DamageType.scratch,
                  onTap: () => onSelect(DamageType.scratch),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DamageTypeButton(
                  type: DamageType.dent,
                  selected: selected == DamageType.dent,
                  onTap: () => onSelect(DamageType.dent),
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
                'LOGGED DAMAGE (${draft.length})',
                style: CheckOutUiTokens.fieldLabel(),
              ),
            ),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear logged damage',
                style: CheckOutUiTokens.body(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: draft.isEmpty
              ? Center(
                  child: Text(
                    'No new damage logged yet.',
                    style: CheckOutUiTokens.hint(),
                  ),
                )
              : ListView.separated(
                  itemCount: draft.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = draft[i];
                    return _LoggedDamageRow(
                      entry: e,
                      onDelete: () => onRemove(e.id),
                    );
                  },
                ),
        ),
      ],
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
              style: CheckOutUiTokens.body().copyWith(color: fg),
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
      padding: CheckOutUiTokens.cardPaddingDense,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
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
                Text(entry.type.label, style: CheckOutUiTokens.body()),
                Text(subtitle, style: CheckOutUiTokens.helper()),
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
