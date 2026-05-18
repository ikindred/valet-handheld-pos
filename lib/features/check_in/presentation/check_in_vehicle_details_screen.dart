import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../data/remote/area_detail.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/rate_fetch_service.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_compact_tokens.dart';
import 'widgets/check_in_footer_actions.dart';
import 'widgets/check_in_form_fields.dart';
import 'widgets/check_in_vehicle_details_widgets.dart';

/// Step 2 — Vehicle details
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=30-1719)).
///
/// Two-column grid (landscape): vehicle identification | parking.
class CheckInVehicleDetailsScreen extends StatefulWidget {
  const CheckInVehicleDetailsScreen({super.key});

  static const _fallbackLevels = ['Level 1', 'Level 2', 'Level 3', 'Basement'];
  static const _fallbackSlots = [
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
  List<AreaParkingLevel> _areaLevels = [];
  bool _areaLevelsLoading = true;

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
    _loadAreaLevels();
  }

  Future<void> _loadAreaLevels() async {
    final auth = context.read<AuthRepository>();
    final rateFetch = context.read<RateFetchService>();
    final branchUuid = await auth.branchUuidForApi();
    final areaUuid = await auth.areaUuidForApi();
    if (!mounted) return;
    if (branchUuid.isEmpty || areaUuid.isEmpty) {
      setState(() {
        _areaLevels = [];
        _areaLevelsLoading = false;
      });
      return;
    }
    final detail = await rateFetch.fetchAreaDetail(
      branchId: branchUuid,
      areaId: areaUuid,
    );
    if (!mounted) return;
    setState(() {
      _areaLevels = detail?.levels ?? [];
      _areaLevelsLoading = false;
    });
    if (AppConfig.checkInPrefillEnabled && mounted) {
      _applyDemoParking();
    }
  }

  void _applyDemoParking() {
    final cubit = context.read<CheckInCubit>();
    if (_areaLevels.isNotEmpty) {
      final level = _areaLevels.first;
      final first = level.availableSlots.isNotEmpty
          ? level.availableSlots.first
          : null;
      cubit.updateVehicleStep(
        parkingLevel: level.name,
        parkingSlot: first?.label ?? '',
        parkingSlotId: first?.id ?? '',
      );
    } else {
      cubit.updateVehicleStep(
        parkingLevel: CheckInVehicleDetailsScreen._fallbackLevels.first,
        parkingSlot: CheckInVehicleDetailsScreen._fallbackSlots.first,
        parkingSlotId: '',
      );
    }
  }

  AreaParkingLevel? _levelForName(String levelName) {
    for (final l in _areaLevels) {
      if (l.name == levelName) return l;
    }
    return null;
  }

  AreaParkingSlot? _slotForLabel(String levelName, String slotLabel) {
    final level = _levelForName(levelName);
    if (level == null) return null;
    for (final s in level.availableSlots) {
      if (s.label == slotLabel) return s;
    }
    return null;
  }

  List<String> get _levelItems {
    if (_areaLevels.isNotEmpty) {
      return _areaLevels.map((l) => l.name).toList();
    }
    return CheckInVehicleDetailsScreen._fallbackLevels;
  }

  List<String> _slotItemsForLevel(String levelName) {
    if (_areaLevels.isNotEmpty) {
      final match = _areaLevels.where((l) => l.name == levelName);
      if (match.isNotEmpty) {
        return match.first.availableSlots.map((s) => s.label).toList();
      }
      return const [];
    }
    return CheckInVehicleDetailsScreen._fallbackSlots;
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
    if (_areaLevels.isNotEmpty && cubit.state.parkingSlotId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a parking slot before continuing.')),
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
    final normalizedPlate = cubit.state.plateNumber;
    if (_plateCtrl.text != normalizedPlate) {
      _plateCtrl.text = normalizedPlate;
    }
    context.go('/check-in/step-3');
  }

  void _onCancel() {
    context.read<CheckInCubit>().resetSession();
    context.go('/dashboard');
  }


  Widget _plateBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckInFormField(
          label: 'PLATE NUMBER',
          child: CheckInPlateNumberField(controller: _plateCtrl),
        ),
        const SizedBox(height: 6),
        Text(
          'Philippine format — 3 letters + 4 digits',
          style: CheckInCompactTokens.helperText(),
        ),
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
        const SizedBox(width: CheckInCompactTokens.fieldGap),
        Expanded(
          child: CheckInFormField(
            label: 'YEAR',
            child: CheckInTextField(
              controller: _yearCtrl,
              hint: '2024',
              keyboardType: TextInputType.number,
              valueStyle: CheckInCompactTokens.fieldValue(),
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
        const SizedBox(width: CheckInCompactTokens.fieldGap),
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
    if (_areaLevelsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return BlocBuilder<CheckInCubit, CheckInState>(
      buildWhen: (a, b) =>
          a.parkingLevel != b.parkingLevel ||
          a.parkingSlot != b.parkingSlot ||
          a.parkingSlotId != b.parkingSlotId,
      builder: (context, state) {
        final level = state.parkingLevel;
        final slot = state.parkingSlot;
        final levelItems = _levelItems;
        final slotItems = level.isEmpty ? const <String>[] : _slotItemsForLevel(level);

        final levelValue =
            level.isEmpty || !levelItems.contains(level) ? null : level;
        final slotValue =
            slot.isEmpty || !slotItems.contains(slot) ? null : slot;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckInDropdownField(
              label: 'LEVEL',
              value: levelValue ?? '',
              items: levelItems,
              onChanged: (v) {
                final cubit = context.read<CheckInCubit>();
                final nextLevel = v ?? '';
                final slotsForLevel = nextLevel.isEmpty
                    ? const <String>[]
                    : _slotItemsForLevel(nextLevel);
                final keepSlot = slotsForLevel.contains(state.parkingSlot);
                cubit.updateVehicleStep(
                  parkingLevel: nextLevel,
                  parkingSlot: keepSlot ? state.parkingSlot : '',
                  parkingSlotId: keepSlot ? state.parkingSlotId : '',
                );
              },
            ),
            const SizedBox(height: CheckInCompactTokens.fieldGap),
            CheckInDropdownField(
              label: 'SLOT',
              value: slotValue ?? '',
              items: slotItems,
              onChanged: levelValue == null || slotItems.isEmpty
                  ? (_) {}
                  : (v) {
                      final label = v ?? '';
                      final picked = _slotForLabel(levelValue, label);
                      context.read<CheckInCubit>().updateVehicleStep(
                            parkingSlot: label,
                            parkingSlotId: picked?.id ?? '',
                          );
                    },
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
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        _plateBlock(),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _modelYearRow(),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _brandColorRow(),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        const CheckInSectionTitle(text: 'VEHICLE TYPE'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        const CheckInVehicleBodyTypeGrid(),
      ],
    );
  }

  Widget _columnParkingOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CheckInSectionTitle(text: 'PARKING'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        _parkingDropdowns(),
      ],
    );
  }

  Widget _narrowBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _columnVehicleId(),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        _columnParkingOnly(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CheckInCompactTokens.screenPaddingH,
        CheckInCompactTokens.screenPaddingTop,
        CheckInCompactTokens.screenPaddingH,
        CheckInCompactTokens.screenPaddingBottom,
      ),
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
                          width: CheckInCompactTokens.columnDividerWidth,
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
            const SizedBox(height: CheckInCompactTokens.footerGap),
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
