import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_text_field.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_footer_actions.dart';
import 'widgets/check_in_form_fields.dart';
import 'widgets/check_in_vehicle_details_widgets.dart';

/// Step 2 — Vehicle details
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-1719)).
///
/// Two-column grid (landscape): vehicle identification | parking.
class CheckInVehicleDetailsScreen extends StatefulWidget {
  const CheckInVehicleDetailsScreen({super.key});

  static const _parkingLevels = ['Level 1', 'Level 2', 'Level 3', 'Basement'];
  static const _parkingSlots = [
    'Slot #1',
    'Slot #2',
    'Slot #3',
    'Slot #4',
    'Slot #5',
  ];

  @override
  State<CheckInVehicleDetailsScreen> createState() =>
      _CheckInVehicleDetailsScreenState();
}

class _CheckInVehicleDetailsScreenState
    extends State<CheckInVehicleDetailsScreen> {
  late final TextEditingController _plateCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<CheckInCubit>().state;
    _plateCtrl = TextEditingController(text: s.plateNumber);
    _modelCtrl = TextEditingController(text: s.vehicleModel);
    _brandCtrl = TextEditingController(text: s.vehicleBrandMake);
    _colorCtrl = TextEditingController(text: s.vehicleColor);
    _yearCtrl = TextEditingController(text: s.vehicleYear);
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _brandCtrl.dispose();
    _colorCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    final cubit = context.read<CheckInCubit>();
    final s = cubit.state;
    if (s.contactNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add cellphone on step 1 before continuing.')),
      );
      return;
    }
    cubit.updateVehicleStep(
      plateNumber: _plateCtrl.text.trim(),
      vehicleModel: _modelCtrl.text.trim(),
      vehicleBrandMake: _brandCtrl.text.trim(),
      vehicleColor: _colorCtrl.text.trim(),
      vehicleYear: _yearCtrl.text.trim(),
    );
    context.go('/check-in/step-3');
  }

  void _onCancel() {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }

  static final _helperStyle = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  Widget _plateBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckInFormField(
          label: 'PLATE NUMBER',
          child: CheckInPlateNumberField(controller: _plateCtrl),
        ),
        const SizedBox(height: 6),
        Text('Philippine format — 3 letters + 4 digits', style: _helperStyle),
      ],
    );
  }

  Widget _modelYearRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CheckInFormField(
            label: 'MODEL',
            child: CheckInTextField(controller: _modelCtrl, hint: 'e.g. Camry'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CheckInFormField(
            label: 'YEAR',
            child: CheckInTextField(
              controller: _yearCtrl,
              hint: '2024',
              keyboardType: TextInputType.number,
              valueStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
              minHeight: AppTextFieldTokens.minInputHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandColorRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CheckInFormField(
            label: 'BRAND / MAKE',
            child: CheckInTextField(
              controller: _brandCtrl,
              hint: 'e.g. Toyota',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CheckInFormField(
            label: 'COLOR',
            child: CheckInTextField(
              controller: _colorCtrl,
              hint: 'e.g. Silver',
            ),
          ),
        ),
      ],
    );
  }

  Widget _parkingDropdowns() {
    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) =>
          a.parkingLevel != b.parkingLevel || a.parkingSlot != b.parkingSlot,
      builder: (context, state) {
        final level = state.parkingLevel;
        final slot = state.parkingSlot;
        final levelValue =
            level.isEmpty ||
                !CheckInVehicleDetailsScreen._parkingLevels.contains(level)
            ? null
            : level;
        final slotValue =
            slot.isEmpty ||
                !CheckInVehicleDetailsScreen._parkingSlots.contains(slot)
            ? null
            : slot;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckInDropdownField(
              label: 'LEVEL',
              value: levelValue ?? '',
              items: CheckInVehicleDetailsScreen._parkingLevels,
              onChanged: (v) => context.read<CheckInCubit>().updateVehicleStep(
                parkingLevel: v ?? '',
              ),
            ),
            const SizedBox(height: 16),
            CheckInDropdownField(
              label: 'SLOT',
              value: slotValue ?? '',
              items: CheckInVehicleDetailsScreen._parkingSlots,
              onChanged: (v) => context.read<CheckInCubit>().updateVehicleStep(
                parkingSlot: v ?? '',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _columnVehicleId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'VEHICLE IDENTIFICATION'),
        const SizedBox(height: 12),
        _plateBlock(),
        const SizedBox(height: 16),
        _modelYearRow(),
        const SizedBox(height: 16),
        _brandColorRow(),
        const SizedBox(height: 20),
        const CheckInSectionTitle(text: 'VEHICLE TYPE'),
        const SizedBox(height: 12),
        const CheckInVehicleBodyTypeGrid(),
      ],
    );
  }

  Widget _columnParkingOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'PARKING'),
        const SizedBox(height: 12),
        _parkingDropdowns(),
      ],
    );
  }

  Widget _narrowBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _columnVehicleId(),
        const SizedBox(height: 24),
        _columnParkingOnly(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape =
                        MediaQuery.orientationOf(context) ==
                        Orientation.landscape;
                    final useTwoColumns =
                        isLandscape && constraints.maxWidth >= 400;

                    if (!useTwoColumns) {
                      return _narrowBody();
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _columnVehicleId()),
                        VerticalDivider(
                          width: 41,
                          thickness: 1,
                          color: Colors.black.withValues(alpha: 0.13),
                        ),
                        Expanded(child: _columnParkingOnly()),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckInFooterActions(
              onCancel: _onCancel,
              showBack: true,
              onBack: () => context.go('/check-in/step-1'),
              primaryLabel: 'Next: Vehicle Condition',
              onPrimary: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}
