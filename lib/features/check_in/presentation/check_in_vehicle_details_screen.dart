import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../data/remote/area_detail.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/parking_layout_service.dart';
import '../../../data/services/rate_fetch_service.dart';
import '../../../data/services/rate_service.dart';
import '../domain/vehicle_body_type.dart';
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
  Set<VehicleBodyType> _ratedBodyTypes = {};

  late final TextEditingController _plateCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _vrNoCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<CheckInCubit>().state;
    _plateCtrl = TextEditingController(text: s.plateNumber);
    _brandCtrl = TextEditingController(text: s.vehicleBrand);
    _colorCtrl = TextEditingController(text: s.vehicleColor);
    _vrNoCtrl = TextEditingController(text: s.vehicleVrNo);
    _loadAreaLevels();
    _loadRatedVehicleTypes();
  }

  Future<void> _loadRatedVehicleTypes() async {
    final auth = context.read<AuthRepository>();
    final rateFetch = context.read<RateFetchService>();
    final rateService = context.read<RateService>();
    final branchUuid = await auth.branchUuidForApi();
    final areaUuid = await auth.areaUuidForApi();
    if (!mounted) return;

    Set<VehicleBodyType> rated = {};
    final online =
        !AppConfig.useStubApi && await InternetReachability.hasInternet();
    if (online && branchUuid.isNotEmpty && areaUuid.isNotEmpty) {
      final detail = await rateFetch.fetchAreaDetail(
        branchId: branchUuid,
        areaId: areaUuid,
      );
      final snapshot = await rateFetch.fetchBranchRatesForArea(
        branchId: branchUuid,
        areaId: areaUuid,
        areaCode: detail?.code ?? '',
      );
      if (snapshot != null) {
        rated = BranchRatesSnapshot.ratedBodyTypes(
          vehicleTypeRates: snapshot.vehicleTypeRates,
        );
      }
    }
    if (rated.isEmpty && branchUuid.isNotEmpty) {
      final keys = await rateService.getDistinctVehicleTypesForBranch(branchUuid);
      rated = BranchRatesSnapshot.ratedBodyTypesFromDriftKeys(keys);
    }

    if (!mounted) return;
    setState(() => _ratedBodyTypes = rated);

    if (rated.isNotEmpty) {
      final cubit = context.read<CheckInCubit>();
      if (!rated.contains(cubit.state.vehicleBodyType)) {
        cubit.updateVehicleStep(vehicleBodyType: rated.first);
      }
    }
  }

  Future<void> _loadAreaLevels() async {
    final auth = context.read<AuthRepository>();
    final rateFetch = context.read<RateFetchService>();
    final parkingLayout = context.read<ParkingLayoutService>();
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

    var levels = <AreaParkingLevel>[];
    final online =
        !AppConfig.useStubApi && await InternetReachability.hasInternet();
    if (online) {
      final detail = await rateFetch.fetchAreaDetail(
        branchId: branchUuid,
        areaId: areaUuid,
      );
      if (detail != null && detail.levels.isNotEmpty) {
        levels = detail.levels;
        await parkingLayout.saveLevels(
          branchId: branchUuid,
          areaId: areaUuid,
          levels: levels,
        );
      }
    }
    if (levels.isEmpty) {
      levels = await parkingLayout.loadLevels(
        branchId: branchUuid,
        areaId: areaUuid,
      );
    }

    if (!mounted) return;
    setState(() {
      _areaLevels = levels;
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

  List<AreaParkingSlot> _slotsForLevel(String levelName) {
    final level = _levelForName(levelName);
    return level?.slots ?? const [];
  }

  List<String> get _levelItems {
    if (_areaLevels.isNotEmpty) {
      return _areaLevels.map((l) => l.name).toList();
    }
    return CheckInVehicleDetailsScreen._fallbackLevels;
  }

  List<String> _slotItemsForLevel(String levelName) {
    if (_areaLevels.isNotEmpty) {
      return _slotsForLevel(levelName).map((s) => s.label).toList();
    }
    return CheckInVehicleDetailsScreen._fallbackSlots;
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _colorCtrl.dispose();
    _vrNoCtrl.dispose();
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
      vehicleBrand: _brandCtrl.text.trim(),
      vehicleColor: _colorCtrl.text.trim(),
      vehicleVrNo: _vrNoCtrl.text.trim(),
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

  Widget _brandVrNoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CheckInFormField(
            label: 'BRAND / MODEL',
            child: CheckInTextField(
              controller: _brandCtrl,
              hint: 'e.g. Toyota Vios',
            ),
          ),
        ),
        const SizedBox(width: CheckInCompactTokens.fieldGap),
        Expanded(
          child: CheckInFormField(
            label: 'VR NO. (OPTIONAL)',
            child: CheckInTextField(
              controller: _vrNoCtrl,
              hint: 'e.g. VR-12345',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              ],
              valueStyle: CheckInCompactTokens.fieldValue(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorRow() {
    return CheckInFormField(
      label: 'COLOR',
      child: CheckInTextField(
        controller: _colorCtrl,
        hint: 'e.g. Silver',
      ),
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

        final useAreaLayout = _areaLevels.isNotEmpty;
        final levelSlots = levelValue == null
            ? const <AreaParkingSlot>[]
            : _slotsForLevel(levelValue);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (useAreaLayout)
              CheckInParkingLevelDropdownField(
                label: 'LEVEL',
                levels: _areaLevels,
                value: levelValue ?? '',
                onChanged: (v) {
                  final cubit = context.read<CheckInCubit>();
                  final nextLevel = v ?? '';
                  final slotsForLevel = nextLevel.isEmpty
                      ? const <AreaParkingSlot>[]
                      : _slotsForLevel(nextLevel);
                  final keepSlot = slotsForLevel.any(
                    (s) =>
                        s.label == state.parkingSlot &&
                        s.isAvailable,
                  );
                  cubit.updateVehicleStep(
                    parkingLevel: nextLevel,
                    parkingSlot: keepSlot ? state.parkingSlot : '',
                    parkingSlotId: keepSlot ? state.parkingSlotId : '',
                  );
                },
              )
            else
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
            if (useAreaLayout)
              CheckInParkingSlotDropdownField(
                label: 'SLOT',
                slots: levelSlots,
                value: slotValue ?? '',
                onChanged: levelValue == null || levelSlots.isEmpty
                    ? (_) {}
                    : (picked) {
                        context.read<CheckInCubit>().updateVehicleStep(
                              parkingSlot: picked?.label ?? '',
                              parkingSlotId: picked?.id ?? '',
                            );
                      },
              )
            else
              CheckInDropdownField(
                label: 'SLOT',
                value: slotValue ?? '',
                items: slotItems,
                onChanged: levelValue == null || slotItems.isEmpty
                    ? (_) {}
                    : (v) {
                        final label = v ?? '';
                        context.read<CheckInCubit>().updateVehicleStep(
                              parkingSlot: label,
                              parkingSlotId: '',
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
        _brandVrNoRow(),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _colorRow(),
        const SizedBox(height: CheckInCompactTokens.blockGap),
        const CheckInSectionTitle(text: 'VEHICLE TYPE'),
        const SizedBox(height: CheckInCompactTokens.sectionGap),
        CheckInVehicleBodyTypeGrid(enabledTypes: _ratedBodyTypes),
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
                          color: AppThemeColors.of(context).cardBorder,
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
