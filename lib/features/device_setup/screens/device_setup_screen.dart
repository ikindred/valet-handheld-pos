import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../cubit/device_setup_cubit.dart';
import '../cubit/device_setup_state.dart';

/// Brand / layout (spec Step 6).
abstract final class _DeviceSetupTheme {
  static const bg = Color(0xFF1C1C1A);
  static const orange = Color(0xFFE87722);
  static const greyMuted = Color(0xFF9E9E9E);
  static const greySubtitle = Color(0xFFAEAEAE);
  static const white = Color(0xFFFFFFFF);
  static const badgeActive = Color(0xFF2E7D32);
  static const badgeInactive = Color(0xFF757575);
  static const cardBorder = Color(0xFF3C3434);
}

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeviceSetupCubit>().fetchDevices();
    });
  }

  TextStyle _poppins(
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
        backgroundColor: _DeviceSetupTheme.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<DeviceSetupCubit, DeviceSetupState>(
                  builder: (context, state) {
                    switch (state) {
                      case DeviceSetupInitial():
                      case DeviceSetupLoading():
                      case DeviceClaimSuccess():
                        return _LoadingBody(poppins: _poppins);
                      case DeviceListLoaded(:final devices):
                        return _DeviceListBody(
                          devices: devices,
                          poppins: _poppins,
                          onClaim: (id) =>
                              context.read<DeviceSetupCubit>().claimDevice(id),
                        );
                      case DeviceClaimPendingActivation():
                        return _PendingActivationBody(poppins: _poppins);
                      case DeviceSetupError(:final message):
                        return _ErrorBody(
                          message: message,
                          poppins: _poppins,
                          onRetry: () =>
                              context.read<DeviceSetupCubit>().fetchDevices(),
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.poppins});

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: _DeviceSetupTheme.orange,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading devices...',
            style: poppins(16, FontWeight.w500, _DeviceSetupTheme.greyMuted),
          ),
        ],
      ),
    );
  }
}

class _DeviceListBody extends StatelessWidget {
  const _DeviceListBody({
    required this.devices,
    required this.poppins,
    required this.onClaim,
  });

  final List<DeviceModel> devices;
  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;
  final void Function(String serverDeviceId) onClaim;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text(
            'No devices found. Contact your administrator.',
            textAlign: TextAlign.center,
            style: poppins(16, FontWeight.w500, _DeviceSetupTheme.greySubtitle),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Device',
            style: poppins(20, FontWeight.w700, _DeviceSetupTheme.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the terminal identity for this tablet.',
            style: poppins(15, FontWeight.w400, _DeviceSetupTheme.greySubtitle),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = devices[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onClaim(d.serverDeviceId),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _DeviceSetupTheme.cardBorder),
                        color: const Color(0xFF252522),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.deviceLabel.isEmpty
                                      ? d.serverDeviceId
                                      : d.deviceLabel,
                                  style: poppins(
                                    17,
                                    FontWeight.w700,
                                    _DeviceSetupTheme.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${d.branch} · ${d.area}',
                                  style: poppins(
                                    14,
                                    FontWeight.w400,
                                    _DeviceSetupTheme.greySubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(active: d.isActive, poppins: poppins),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
    final bg = active
        ? _DeviceSetupTheme.badgeActive
        : _DeviceSetupTheme.badgeInactive;
    final label = active ? 'ACTIVE' : 'INACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: poppins(11, FontWeight.w700, bg),
      ),
    );
  }
}

class _PendingActivationBody extends StatelessWidget {
  const _PendingActivationBody({required this.poppins});

  final TextStyle Function(double, FontWeight, Color, {double height}) poppins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clock,
              size: 56,
              color: _DeviceSetupTheme.greySubtitle,
            ),
            const SizedBox(height: 24),
            Text(
              'Device Not Yet Activated',
              textAlign: TextAlign.center,
              style: poppins(20, FontWeight.w700, _DeviceSetupTheme.white),
            ),
            const SizedBox(height: 16),
            Text(
              'This terminal has not been activated in the system. '
              'Please contact your administrator to activate it, '
              'then restart the app.',
              textAlign: TextAlign.center,
              style: poppins(
                15,
                FontWeight.w400,
                _DeviceSetupTheme.greySubtitle,
                height: 1.45,
              ),
            ),
          ],
        ),
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
                    color: _DeviceSetupTheme.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: poppins(
                      15,
                      FontWeight.w500,
                      _DeviceSetupTheme.greySubtitle,
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
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _DeviceSetupTheme.orange,
                foregroundColor: _DeviceSetupTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: poppins(16, FontWeight.w700, _DeviceSetupTheme.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
