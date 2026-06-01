import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_background.dart';
import '../cubit/device_setup_cubit.dart';
import '../cubit/device_setup_state.dart';

/// Light palette aligned with [LoginScreen] / [AppBackground].
abstract final class _T {
  static const orange = Color(0xFFF68D00);
  static const textPrimary = AppColors.textPrimary;
  static const greyMuted = Color(0xFF9DA4B0);
  static const greySubtitle = Color(0xFFAEAEAE);
  static const onOrange = Color(0xFFFFFFFF);
  static const badgeActive = Color(0xFF2E7D32);
  static const badgeInactive = Color(0xFF757575);
  static const cardBorder = Color(0xFFE7E8EB);
  static const cardBorderStrong = Color(0xFFD0D4DC);
  static const cardBg = Color(0xFFFFFFFF);
  static const chipSelectedBg = Color(0xFFFFF3E0);
  static const skeleton = Color(0xFFE8EAED);
  static const errorTint = Color(0xFFC62828);
}

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final TextEditingController _search = TextEditingController();
  String? _branchFilter;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeviceSetupCubit>().fetchDevices();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TextStyle poppins(
    double size,
    FontWeight w,
    Color color, {
    double height = 1.2,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
    );
  }

  /// Monospace for serials / IDs. Does not use [GoogleFonts] so it works when
  /// [GoogleFonts.config.allowRuntimeFetching] is false (only bundled Poppins).
  TextStyle mono(double size, FontWeight w, Color color) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      fontWeight: w,
      color: color,
      height: 1.25,
    );
  }

  bool _siteDataInvalid(DeviceModel d) {
    return d.branchName.trim().isEmpty || d.areaName.trim().isEmpty;
  }

  List<String> _uniqueBranches(List<DeviceModel> devices) {
    final set = <String>{};
    for (final d in devices) {
      final b = d.branchName.trim();
      if (b.isNotEmpty) set.add(b);
    }
    final list = set.toList()
      ..sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return list;
  }

  List<DeviceModel> _filtered(List<DeviceModel> all) {
    var list = List<DeviceModel>.from(all);
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) {
        final label = d.deviceLabel.toLowerCase();
        final serial = d.serialNumber.toLowerCase();
        return label.contains(q) || serial.contains(q);
      }).toList();
    }
    final branch = _branchFilter?.trim();
    if (branch != null && branch.isNotEmpty) {
      list = list.where((d) => d.branchName.trim() == branch).toList();
    }
    return list;
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _branchFilter = null;
    });
  }

  Widget _branchFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: poppins(
          13,
          selected ? FontWeight.w700 : FontWeight.w500,
          selected ? _T.orange : _T.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: _T.chipSelectedBg,
      checkmarkColor: _T.orange,
      backgroundColor: _T.cardBg,
      side: BorderSide(
        color: selected ? _T.orange : _T.cardBorderStrong,
        width: selected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showClaimSheet(
    BuildContext context,
    DeviceModel device,
  ) async {
    final cubit = context.read<DeviceSetupCubit>();
    final label =
        device.deviceLabel.trim().isEmpty ? device.serverDeviceId : device.deviceLabel;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up as $label?',
                style: poppins(18, FontWeight.w700, _T.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                device.branchName.trim().isEmpty &&
                        device.areaName.trim().isEmpty
                    ? 'Branch and area were not returned for this device. You can still claim if your administrator confirms the slot.'
                    : 'Branch: ${device.branchName} — Area: ${device.areaName}',
                style: poppins(14, FontWeight.w400, _T.greySubtitle, height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                'Serial: ${device.serialNumber.trim().isEmpty ? '—' : device.serialNumber}',
                style: mono(13, FontWeight.w500, _T.greyMuted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.textPrimary,
                        side: const BorderSide(color: _T.cardBorderStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: poppins(15, FontWeight.w600, _T.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        cubit.claimDevice(device.serverDeviceId);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.orange,
                        foregroundColor: _T.onOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: poppins(15, FontWeight.w700, _T.onOrange),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceSetupCubit, DeviceSetupState>(
      listenWhen: (p, c) => c is DeviceClaimSuccess,
      listener: (context, state) {
        if (state is DeviceClaimSuccess) {
          context.go('/login');
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Center(
                  child: Image.asset(
                    'assets/images/spid_logo.png',
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Device',
                      style: poppins(24, FontWeight.w700, _T.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose the terminal assigned to this tablet',
                      style: poppins(
                        14,
                        FontWeight.w400,
                        _T.greySubtitle,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<DeviceSetupCubit, DeviceSetupState>(
                  builder: (context, state) {
                    return switch (state) {
                      DeviceSetupInitial() ||
                      DeviceSetupLoadingDevices() =>
                        const _DeviceSkeletonList(),
                      DeviceSetupClaiming() => _ClaimingBody(poppins: poppins),
                      DeviceClaimSuccess() => _ClaimingBody(poppins: poppins),
                      final DeviceSetupDevicesLoaded loaded => _buildLoaded(
                          context,
                          loaded.devices,
                        ),
                      DeviceSetupError(:final message) => _ErrorBody(
                          message: message,
                          poppins: poppins,
                          onRefresh: () =>
                              context.read<DeviceSetupCubit>().fetchDevices(),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<DeviceModel> devices) {
    if (devices.isEmpty) {
      return _EmptyDevicesBody(
        poppins: poppins,
        onRefresh: () => context.read<DeviceSetupCubit>().fetchDevices(),
      );
    }

    final visible = _filtered(devices);
    final branches = _uniqueBranches(devices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _search,
            style: poppins(15, FontWeight.w400, _T.textPrimary),
            cursorColor: _T.orange,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by name or serial…',
              hintStyle: poppins(14, FontWeight.w400, _T.greyMuted),
              prefixIcon:
                  const Icon(LucideIcons.search, color: _T.greyMuted, size: 20),
              filled: true,
              fillColor: _T.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _T.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _T.cardBorderStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _T.orange, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _branchFilterChip(
                  label: 'All branches',
                  selected: _branchFilter == null,
                  onSelected: (_) => setState(() => _branchFilter = null),
                ),
              ),
              ...branches.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _branchFilterChip(
                    label: b,
                    selected: _branchFilter == b,
                    onSelected: (_) => setState(() => _branchFilter = b),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? _NoFilterResultsBody(
                  poppins: poppins,
                  onClear: _clearFilters,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = visible[i];
                    return _DeviceTile(
                      device: d,
                      siteInvalid: _siteDataInvalid(d),
                      poppins: poppins,
                      mono: mono,
                      onTap: () => _showClaimSheet(context, d),
                    );
                  },
                ),
        ),
      ],
    );
  }

}

class _DeviceSkeletonList extends StatelessWidget {
  const _DeviceSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 108,
        decoration: BoxDecoration(
          color: _T.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.cardBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18,
              width: 200,
              decoration: BoxDecoration(
                color: _T.skeleton,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 12,
              width: 140,
              decoration: BoxDecoration(
                color: _T.skeleton,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _T.skeleton,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimingBody extends StatelessWidget {
  const _ClaimingBody({required this.poppins});

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _T.orange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Claiming terminal…',
            style: poppins(16, FontWeight.w500, _T.greyMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyDevicesBody extends StatelessWidget {
  const _EmptyDevicesBody({
    required this.poppins,
    required this.onRefresh,
  });

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Icon(
                    LucideIcons.inbox,
                    size: 56,
                    color: _T.greySubtitle,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No devices available',
                    textAlign: TextAlign.center,
                    style: poppins(20, FontWeight.w700, _T.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unclaimed device identities appear here. Select one '
                    'to set up this tablet.',
                    textAlign: TextAlign.center,
                    style: poppins(
                      14,
                      FontWeight.w400,
                      _T.greySubtitle,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: _T.orange,
                foregroundColor: _T.onOrange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Refresh',
                style: poppins(16, FontWeight.w700, _T.onOrange),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NoFilterResultsBody extends StatelessWidget {
  const _NoFilterResultsBody({
    required this.poppins,
    required this.onClear,
  });

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 48,
              color: _T.greySubtitle,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices match your search',
              textAlign: TextAlign.center,
              style: poppins(17, FontWeight.w600, _T.textPrimary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onClear,
              style: FilledButton.styleFrom(
                backgroundColor: _T.orange,
                foregroundColor: _T.onOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Clear filters',
                style: poppins(15, FontWeight.w700, _T.onOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.siteInvalid,
    required this.poppins,
    required this.mono,
    required this.onTap,
  });

  final DeviceModel device;
  final bool siteInvalid;
  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final TextStyle Function(double, FontWeight, Color) mono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = device.deviceLabel.trim().isEmpty
        ? device.serverDeviceId
        : device.deviceLabel;
    final serial = device.serialNumber.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: siteInvalid
                  ? _T.errorTint.withValues(alpha: 0.85)
                  : _T.cardBorderStrong,
              width: siteInvalid ? 1.5 : 1.25,
            ),
            color: _T.cardBg,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: poppins(18, FontWeight.w700, _T.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(active: device.isActive, poppins: poppins),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                serial.isEmpty ? '—' : serial,
                style: mono(13, FontWeight.w500, _T.greySubtitle),
              ),
              const SizedBox(height: 12),
              if (siteInvalid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: _T.errorTint.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Branch or area not provided by server',
                          style: poppins(
                            13,
                            FontWeight.w500,
                            _T.errorTint.withValues(alpha: 0.95),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.mapPin, size: 18, color: _T.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.branchName,
                        style: poppins(15, FontWeight.w600, _T.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.layers, size: 18, color: _T.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.areaName,
                        style: poppins(15, FontWeight.w600, _T.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.active,
    required this.poppins,
  });

  final bool active;
  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;

  @override
  Widget build(BuildContext context) {
    final bg = active ? _T.badgeActive : _T.badgeInactive;
    final label = active ? 'Active' : 'Inactive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: poppins(11, FontWeight.w600, bg),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.poppins,
    required this.onRefresh,
  });

  final String message;
  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 56,
                    color: _T.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: poppins(
                      15,
                      FontWeight.w500,
                      _T.greySubtitle,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: _T.orange,
                foregroundColor: _T.onOrange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Refresh',
                style: poppins(16, FontWeight.w700, _T.onOrange),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
