import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../domain/vehicle_body_type.dart';
import '../../state/check_in_cubit.dart';
import 'check_in_compact_tokens.dart';
import 'check_in_form_fields.dart';

/// Standalone plate input: light orange fill + orange border (no [AppTextField] / shadow).
class CheckInPlateNumberField extends StatelessWidget {
  const CheckInPlateNumberField({
    super.key,
    required this.controller,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  /// Light orange field surface (unified — no inner white [TextField] fill).
  static const _lightOrange = Color(0xFFFFEED7);
  static const _orange = Color(0xFFF68D00);

  @override
  Widget build(BuildContext context) {
    final hintStyle = CheckInCompactTokens.plateHint();
    final isDark = AppThemeColors.isDark(context);
    final fill = isDark
        ? AppThemeColors.of(context).inputFill
        : _lightOrange;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: CheckInCompactTokens.plateMinHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _orange, width: 2),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          cursorColor: _orange,
          textCapitalization: TextCapitalization.characters,
          style: CheckInCompactTokens.plateValue(),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'ABC 1234',
            hintStyle: hintStyle,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
          ],
        ),
      ),
    );
  }
}

/// Vehicle type cards: row 1 (Sedan | SUV | Van), row 2 (Luxury | EV/PHEV), same widths as row 1.
class CheckInVehicleBodyTypeGrid extends StatelessWidget {
  const CheckInVehicleBodyTypeGrid({super.key});

  static const _row1 = [
    VehicleBodyType.sedan,
    VehicleBodyType.suv,
    VehicleBodyType.van,
  ];
  static const _row2 = [
    VehicleBodyType.luxury,
    VehicleBodyType.evPhev,
    VehicleBodyType.motorcycle,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) => a.vehicleBodyType != b.vehicleBodyType,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = CheckInCompactTokens.bodyTypeGridGap;
            final w = constraints.maxWidth;
            final cellW = (w - 2 * gap) / 3;

            Widget card(VehicleBodyType t) => SizedBox(
              width: cellW,
              child: _VehicleTypeCard(
                type: t,
                selected: state.vehicleBodyType == t,
                onTap: () => context.read<CheckInCubit>().updateVehicleStep(
                  vehicleBodyType: t,
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    card(_row1[0]),
                    const SizedBox(width: gap),
                    card(_row1[1]),
                    const SizedBox(width: gap),
                    card(_row1[2]),
                  ],
                ),
                const SizedBox(height: gap),
                Row(
                  children: [
                    card(_row2[0]),
                    const SizedBox(width: gap),
                    card(_row2[1]),
                    const SizedBox(width: gap),
                    card(_row2[2]),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final VehicleBodyType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF68D00);
    const creamSelected = Color(0xFFFFEED7);
    final tc = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = selected
        ? (isDark ? tc.inputFill : creamSelected)
        : tc.cardBg;
    final borderColor = selected ? orange : tc.cardBorder;
    final borderWidth = selected ? 2.0 : 1.0;
    final labelColor = selected ? orange : tc.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: CheckInCompactTokens.bodyTypeCardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.emoji,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: tc.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Belongings ids (Figma grid order).
abstract final class CheckInBelongingsIds {
  static const laptop = 'laptop';
  static const otherValuables = 'other_valuables';
  static const chargerCable = 'charger_cable';
  static const cellphone = 'cellphone';
  static const ipadTablet = 'ipad_tablet';
  static const sunglasses = 'sunglasses';

  static const List<(String id, String label)> entries = [
    (laptop, 'Laptop'),
    (otherValuables, 'Other valuables'),
    (chargerCable, 'Charger/Cable'),
    (cellphone, 'Cellphone'),
    (ipadTablet, 'iPad/Tablet'),
    (sunglasses, 'Sunglasses'),
  ];
}

class CheckInBelongingsGrid extends StatelessWidget {
  const CheckInBelongingsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) {
        final sa = List<String>.from(a.selectedBelongings)..sort();
        final sb = List<String>.from(b.selectedBelongings)..sort();
        return !listEquals(sa, sb);
      },
      builder: (context, state) {
        final selected = state.selectedBelongings.toSet();
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            const gap = CheckInCompactTokens.bodyTypeGridGap;
            final cellW = (w - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: CheckInBelongingsIds.entries.map((e) {
                final id = e.$1;
                final label = e.$2;
                final isOn = selected.contains(id);
                return SizedBox(
                  width: cellW,
                  child: _BelongingTile(
                    label: label,
                    selected: isOn,
                    onTap: () {
                      final next = List<String>.from(state.selectedBelongings);
                      if (isOn) {
                        next.remove(id);
                      } else {
                        next.add(id);
                      }
                      context.read<CheckInCubit>().updateVehicleStep(
                        selectedBelongings: next,
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _BelongingTile extends StatelessWidget {
  const _BelongingTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF68D00);
    const creamSelected = Color(0xFFFFEED7);
    final tc = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = selected
        ? (isDark ? tc.inputFill : creamSelected)
        : tc.cardBg;
    final borderColor = selected ? orange : tc.cardBorder;
    final borderWidth = selected ? 2.0 : 1.0;
    final textColor = selected ? orange : tc.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown row matching `AppReadOnlyField` + chevron (Figma Level / Slot).
class CheckInDropdownField extends StatelessWidget {
  const CheckInDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return CheckInFormField(
      label: label,
      child: AppTextFieldShadow(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: CheckInCompactTokens.inputMinHeight,
          ),
          padding: CheckInCompactTokens.inputPadding,
          decoration: BoxDecoration(
            color: tc.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tc.cardBorder, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value.isEmpty ? null : value,
              hint: Text(
                'Select',
                style: CheckInCompactTokens.fieldValueOf(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: tc.textSubtitleMuted,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: tc.textSecondary,
                size: 20,
              ),
              style: CheckInCompactTokens.fieldValueOf(context),
              items: items
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
