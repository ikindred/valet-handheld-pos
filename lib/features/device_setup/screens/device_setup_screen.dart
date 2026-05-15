import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/device_id_service.dart';
import '../cubit/device_setup_cubit.dart';
import '../cubit/device_setup_state.dart';

abstract final class _T {
  static const bg = Color(0xFF1C1C1A);
  static const orange = Color(0xFFE87722);
  static const greyMuted = Color(0xFF9E9E9E);
  static const greySubtitle = Color(0xFFAEAEAE);
  static const white = Color(0xFFFFFFFF);
  static const badgeActive = Color(0xFF2E7D32);
  static const badgeInactive = Color(0xFF757575);
  static const cardBorder = Color(0xFF3C3434);
  static const cardBg = Color(0xFF252522);
  static const skeleton = Color(0xFF3A3A36);
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

  Future<void> _showClaimSheet(
    BuildContext context,
    DeviceModel device,
  ) async {
    final cubit = context.read<DeviceSetupCubit>();
    final label =
        device.deviceLabel.trim().isEmpty ? device.serverDeviceId : device.deviceLabel;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _T.cardBg,
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
                style: poppins(18, FontWeight.w700, _T.white),
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
                        foregroundColor: _T.white,
                        side: const BorderSide(color: _T.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: poppins(15, FontWeight.w600, _T.white),
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
                        foregroundColor: _T.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: poppins(15, FontWeight.w700, _T.white),
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
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    height: 56,
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
                      style: poppins(24, FontWeight.w700, _T.white),
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
                      final DeviceSetupPendingActivation pending =>
                        _buildPendingInline(context, pending),
                      DeviceSetupError(:final message) => _ErrorBody(
                          message: message,
                          poppins: poppins,
                          onRetry: () =>
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
    );
  }

  Widget _buildLoaded(BuildContext context, List<DeviceModel> devices) {
    if (devices.isEmpty) {
      return _EmptyDevicesBody(
        poppins: poppins,
        mono: mono,
        onRetry: () => context.read<DeviceSetupCubit>().fetchDevices(),
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
            style: poppins(15, FontWeight.w400, _T.white),
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
                borderSide: const BorderSide(color: _T.cardBorder),
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
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    'All branches',
                    style: poppins(13, FontWeight.w500, _T.white),
                  ),
                  selected: _branchFilter == null,
                  onSelected: (_) => setState(() => _branchFilter = null),
                  selectedColor: _T.orange.withValues(alpha: 0.22),
                  checkmarkColor: _T.orange,
                  backgroundColor: _T.cardBg,
                  side: const BorderSide(color: _T.cardBorder),
                ),
              ),
              ...branches.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      b,
                      style: poppins(13, FontWeight.w500, _T.white),
                    ),
                    selected: _branchFilter == b,
                    onSelected: (_) => setState(() => _branchFilter = b),
                    selectedColor: _T.orange.withValues(alpha: 0.22),
                    checkmarkColor: _T.orange,
                    backgroundColor: _T.cardBg,
                    side: const BorderSide(color: _T.cardBorder),
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

  Widget _buildPendingInline(
    BuildContext context,
    DeviceSetupPendingActivation pending,
  ) {
    final serverId = (pending.selectedServerDeviceId ?? '').trim();
    final cubit = context.read<DeviceSetupCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Icon(
                    LucideIcons.clock,
                    size: 52,
                    color: _T.greySubtitle,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Device claimed but not yet activated',
                    textAlign: TextAlign.center,
                    style: poppins(20, FontWeight.w700, _T.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact your administrator to activate this device.',
                    textAlign: TextAlign.center,
                    style: poppins(
                      14,
                      FontWeight.w400,
                      _T.greySubtitle,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Server device ID',
                    style: poppins(13, FontWeight.w600, _T.greyMuted),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _T.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _T.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        serverId.isEmpty ? '—' : serverId,
                        style: mono(13, FontWeight.w500, _T.white),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: serverId.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: serverId),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Server device ID copied'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      icon: const Icon(LucideIcons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                  if (pending.polling) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _T.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Checking…',
                          style: poppins(
                            13,
                            FontWeight.w500,
                            _T.greyMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Text(
            'Auto-check runs every 30 seconds.',
            textAlign: TextAlign.center,
            style: poppins(12, FontWeight.w400, _T.greyMuted),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => cubit.returnToDeviceList(),
            icon: const Icon(LucideIcons.arrowLeft, size: 18, color: _T.white),
            label: Text(
              'Back to device list',
              style: poppins(15, FontWeight.w600, _T.white),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _T.white,
              side: const BorderSide(color: _T.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => cubit.checkPendingAgain(),
            style: FilledButton.styleFrom(
              backgroundColor: _T.orange,
              foregroundColor: _T.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Check again',
              style: poppins(16, FontWeight.w700, _T.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
    required this.mono,
    required this.onRetry,
  });

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final TextStyle Function(double, FontWeight, Color) mono;
  final VoidCallback onRetry;

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
                    style: poppins(20, FontWeight.w700, _T.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ask your administrator to register this tablet in the '
                    'portal. Your device ID is:',
                    textAlign: TextAlign.center,
                    style: poppins(
                      14,
                      FontWeight.w400,
                      _T.greySubtitle,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<String>(
                    future: DeviceIdService.getOrCreate(),
                    builder: (context, snap) {
                      final id = snap.data ?? (snap.hasError ? '(unavailable)' : '…');
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: _T.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _T.cardBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            id,
                            style: mono(13, FontWeight.w500, _T.white),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _T.orange,
              foregroundColor: _T.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: poppins(16, FontWeight.w700, _T.white),
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
              style: poppins(17, FontWeight.w600, _T.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onClear,
              style: FilledButton.styleFrom(
                backgroundColor: _T.orange,
                foregroundColor: _T.white,
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
                style: poppins(15, FontWeight.w700, _T.white),
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
                  ? _T.errorTint.withValues(alpha: 0.65)
                  : _T.cardBorder,
            ),
            color: _T.cardBg,
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
                      style: poppins(18, FontWeight.w700, _T.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(active: device.isActive, poppins: poppins),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                serial.isEmpty ? '—' : serial,
                style: mono(12, FontWeight.w500, _T.greyMuted),
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
                    Icon(LucideIcons.mapPin, size: 16, color: _T.greySubtitle),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        device.branchName,
                        style: poppins(14, FontWeight.w500, _T.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.layers, size: 16, color: _T.greySubtitle),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        device.areaName,
                        style: poppins(14, FontWeight.w500, _T.white),
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
    required this.onRetry,
  });

  final String message;
  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final VoidCallback onRetry;

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
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _T.orange,
              foregroundColor: _T.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: poppins(16, FontWeight.w700, _T.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
