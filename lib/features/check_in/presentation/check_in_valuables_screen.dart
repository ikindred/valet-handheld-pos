import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_form_fields.dart';
import 'widgets/check_in_step_body.dart';

/// Step 3 — Personal belongings / valuables (multi-select). None required.
class CheckInValuablesScreen extends StatefulWidget {
  const CheckInValuablesScreen({super.key});

  @override
  State<CheckInValuablesScreen> createState() => _CheckInValuablesScreenState();
}

class _CheckInValuablesScreenState extends State<CheckInValuablesScreen> {
  static const _otherLabel = 'Other Valuables';

  static const _options = <String>[
    'iPad',
    'Cellphone / Charger',
    'Laptop / Notebook',
    'Sunglasses',
    _otherLabel,
  ];

  late final TextEditingController _otherBelongingsCtrl;

  @override
  void initState() {
    super.initState();
    _otherBelongingsCtrl = TextEditingController(
      text: context.read<CheckInCubit>().state.otherBelongings,
    );
    _otherBelongingsCtrl.addListener(_onOtherTextChanged);
  }

  void _onOtherTextChanged() {
    if (!mounted) return;
    context.read<CheckInCubit>().updateVehicleStep(
          otherBelongings: _otherBelongingsCtrl.text,
        );
  }

  @override
  void dispose() {
    _otherBelongingsCtrl.removeListener(_onOtherTextChanged);
    _otherBelongingsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      scrollable: false,
      showBack: true,
      onBack: () => context.go('/check-in/step-2'),
      primaryLabel: 'Next: Vehicle condition',
      onPrimary: () => context.go('/check-in/step-4'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PERSONAL BELONGINGS',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any items the customer left in the vehicle (optional).',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<CheckInCubit, CheckInState>(
              buildWhen: (a, b) =>
                  a.selectedBelongings != b.selectedBelongings ||
                  a.otherBelongings != b.otherBelongings,
              builder: (context, state) {
                final selected = state.selectedBelongings.toSet();
                final otherChecked = selected.contains(_otherLabel);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final label = _options[i];
                          final on = selected.contains(label);
                          return Material(
                            color: on
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            child: CheckboxListTile(
                              value: on,
                              onChanged: (v) {
                                final next =
                                    List<String>.from(state.selectedBelongings);
                                if (v == true) {
                                  if (!next.contains(label)) next.add(label);
                                  context
                                      .read<CheckInCubit>()
                                      .updateVehicleStep(
                                        selectedBelongings: next,
                                      );
                                } else {
                                  next.remove(label);
                                  if (label == _otherLabel) {
                                    _otherBelongingsCtrl.clear();
                                    context
                                        .read<CheckInCubit>()
                                        .updateVehicleStep(
                                          selectedBelongings: next,
                                          otherBelongings: '',
                                        );
                                  } else {
                                    context
                                        .read<CheckInCubit>()
                                        .updateVehicleStep(
                                          selectedBelongings: next,
                                        );
                                  }
                                }
                              },
                              title: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (otherChecked) ...[
                      const SizedBox(height: 16),
                      CheckInFormField(
                        label: 'OTHER (SPECIFY)',
                        child: CheckInTextField(
                          controller: _otherBelongingsCtrl,
                          maxLines: 3,
                          minHeight: 88,
                          hint: 'e.g. wallet, documents, jewelry…',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
