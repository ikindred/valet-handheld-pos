import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../state/check_in_cubit.dart';
import 'check_in_compact_tokens.dart';

class CheckInValetTypeCards extends StatelessWidget {
  const CheckInValetTypeCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) => a.valetServiceType != b.valetServiceType,
      builder: (context, state) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TypeCard(
                emoji: '🚘',
                label: 'Standard Valet',
                selected:
                    state.valetServiceType == ValetServiceType.standardValet,
                onTap: () => context.read<CheckInCubit>().updateCustomerStep(
                  valetServiceType: ValetServiceType.standardValet,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                emoji: '🅿️',
                label: 'Self-Park',
                selected: state.valetServiceType == ValetServiceType.selfPark,
                onTap: () => context.read<CheckInCubit>().updateCustomerStep(
                  valetServiceType: ValetServiceType.selfPark,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// Selected (either type): cream `#FFEED7`, orange `#F68D00` border + label.
    /// Unselected: card surface + adaptive border.
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
          height: CheckInCompactTokens.valetCardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: tc.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
