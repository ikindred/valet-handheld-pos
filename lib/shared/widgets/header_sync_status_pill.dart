import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/sync/local_sync_notifier.dart';
import '../../features/dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../features/sync/state/sync_cubit.dart';
import '../../features/sync/state/sync_state.dart';

/// Header pill: `[count] [icon] Sync` — refresh while syncing, ✕ on errors, ✓ on success.
class HeaderSyncStatusPill extends StatefulWidget {
  const HeaderSyncStatusPill({super.key});

  @override
  State<HeaderSyncStatusPill> createState() => _HeaderSyncStatusPillState();
}

class _HeaderSyncStatusPillState extends State<HeaderSyncStatusPill>
    with SingleTickerProviderStateMixin {
  Timer? _flashTimer;
  var _syncedFlash = false;
  var _lastSyncedCount = 0;
  var _pending = 0;
  var _failed = 0;
  var _countsReady = false;
  late final AnimationController _spinController;
  LocalSyncNotifier? _localSyncNotifier;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _localSyncNotifier = context.read<LocalSyncNotifier>();
      _localSyncNotifier!.addListener(_onLocalQueueChanged);
      unawaited(_refreshCounts());
    });
  }

  @override
  void dispose() {
    _localSyncNotifier?.removeListener(_onLocalQueueChanged);
    _flashTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _refreshCounts() async {
    if (!mounted) return;
    final cubit = context.read<SyncCubit>();
    final p = await cubit.pendingCount();
    final f = await cubit.failedCount();
    if (!mounted) return;
    setState(() {
      _pending = p;
      _failed = f;
      _countsReady = true;
    });
  }

  void _onLocalQueueChanged() {
    unawaited(_refreshCounts());
  }

  void _onSyncStateChanged(SyncState state) {
    if (state is SyncInProgress) {
      _flashTimer?.cancel();
      if (mounted) {
        setState(() {
          _syncedFlash = false;
          _countsReady = true;
        });
      }
      _spinController.repeat();
      unawaited(_refreshCounts());
      return;
    }

    _spinController.stop();
    _spinController.reset();

    if (state is SyncComplete) {
      unawaited(_refreshCounts());
      if (state.pending == 0 && state.failed == 0) {
        setState(() {
          _syncedFlash = true;
          _lastSyncedCount = state.synced;
        });
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _syncedFlash = false);
        });
        return;
      }
      if (mounted) setState(() => _syncedFlash = false);
      return;
    }

    if (state is SyncError) {
      unawaited(_refreshCounts());
      if (mounted) setState(() => _syncedFlash = false);
    }
  }

  Future<void> _onTap(SyncState state) async {
    if (state is SyncInProgress) return;
    final cubit = context.read<SyncCubit>();
    if (_failed > 0) {
      await cubit.retryFailed();
      return;
    }
    if (_pending > 0) {
      await cubit.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_countsReady) return const SizedBox.shrink();

    return BlocConsumer<SyncCubit, SyncState>(
      listenWhen: (_, next) =>
          next is SyncInProgress ||
          next is SyncComplete ||
          next is SyncError,
      listener: (context, state) => _onSyncStateChanged(state),
      builder: (context, state) {
        final presentation = _resolve(state);
        if (presentation == null) return const SizedBox.shrink();
        final canTap = state is! SyncInProgress &&
            (_failed > 0 || _pending > 0 || state is SyncError);
        return _SyncPillChip(
          presentation: presentation,
          spinController: _spinController,
          onTap: canTap ? () => unawaited(_onTap(state)) : null,
        );
      },
    );
  }

  _SyncPillPresentation? _resolve(SyncState state) {
    if (state is SyncInProgress) {
      final count = _pending + _failed;
      return _SyncPillPresentation(
        count: count > 0 ? count : _pending,
        icon: LucideIcons.refreshCw,
        spinning: true,
        color: const Color(0xFF2563EB),
        bg: const Color(0xFFEFF6FF),
      );
    }
    if (_syncedFlash) {
      return _SyncPillPresentation(
        count: _lastSyncedCount,
        icon: LucideIcons.checkCircle2,
        color: DashboardStyles.green,
        bg: const Color(0xFFF4FBF7),
        showCount: _lastSyncedCount > 0,
      );
    }
    if (state is SyncError || _failed > 0) {
      return _SyncPillPresentation(
        count: _failed > 0 ? _failed : 1,
        icon: LucideIcons.xCircle,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFFF5F5),
      );
    }
    if (_pending > 0) {
      return _SyncPillPresentation(
        count: _pending,
        icon: LucideIcons.cloudOff,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFFFBEB),
      );
    }
    return null;
  }
}

class _SyncPillPresentation {
  const _SyncPillPresentation({
    required this.count,
    required this.icon,
    required this.color,
    required this.bg,
    this.spinning = false,
    this.showCount = true,
  });

  final int count;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool spinning;
  final bool showCount;
}

class _SyncPillChip extends StatelessWidget {
  const _SyncPillChip({
    required this.presentation,
    required this.spinController,
    this.onTap,
  });

  final _SyncPillPresentation presentation;
  final AnimationController spinController;
  final VoidCallback? onTap;

  String _label(_SyncPillPresentation p) {
    if (p.spinning) return 'Syncing';
    if (p.icon == LucideIcons.xCircle) {
      return p.showCount && p.count > 1 ? 'Retry (${p.count})' : 'Retry';
    }
    if (p.icon == LucideIcons.checkCircle2) {
      return p.showCount && p.count > 0 ? 'Synced (${p.count})' : 'Synced';
    }
    return p.showCount && p.count > 0 ? 'Sync (${p.count})' : 'Sync';
  }

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    final borderColor = p.color.withValues(alpha: 0.38);
    final labelStyle = DashboardStyles.headerPillLabel().copyWith(
      color: p.color,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1,
      fontSize: 11,
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SyncIcon(
            icon: p.icon,
            color: p.color,
            spinning: p.spinning,
            spinController: spinController,
          ),
          const SizedBox(width: 6),
          Text(_label(p), style: labelStyle),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashColor: p.color.withValues(alpha: 0.12),
        highlightColor: p.color.withValues(alpha: 0.06),
        child: chip,
      ),
    );
  }
}

class _SyncIcon extends StatelessWidget {
  const _SyncIcon({
    required this.icon,
    required this.color,
    required this.spinning,
    required this.spinController,
  });

  final IconData icon;
  final Color color;
  final bool spinning;
  final AnimationController spinController;

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, size: 13, color: color);

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: spinning
          ? RotationTransition(turns: spinController, child: child)
          : child,
    );
  }
}
