import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/logging/valet_log.dart';
import '../../../core/printing/check_in_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/printing/printer_connection_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';
import '../../sync/state/sync_cubit.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../domain/vehicle_body_type.dart';
import '../domain/vehicle_damage.dart';
import '../state/check_in_cubit.dart';
import 'widgets/check_in_compact_tokens.dart';
import 'widgets/check_in_step_body.dart';

/// Step 5 — Review (confirm saves ticket, then `/check-in/print`).
/// ([Figma](https://www.figma.com/design/70RU38Zhijrag1kwt33uMp/Valet-Parking?node-id=32-861)).
class CheckInReviewPrintScreen extends StatefulWidget {
  const CheckInReviewPrintScreen({super.key});

  @override
  State<CheckInReviewPrintScreen> createState() =>
      _CheckInReviewPrintScreenState();
}

class _CheckInReviewPrintScreenState extends State<CheckInReviewPrintScreen> {
  bool _saving = false;

  /// Three-column Figma grid (customer | condition+time | QR+print).
  static const double _wideBreakpoint = 680.0;

  /// Two-column fallback for narrow landscape.
  static const double _mediumBreakpoint = 480.0;

  Future<void> _commitAndLeave() async {
    if (!mounted || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      ValetLog.info(
        'check_in/review_print/_commitAndLeave',
        'start valet ticket save',
      );
      final auth = context.read<AuthRepository>();
      final cubit = context.read<CheckInCubit>();
      final sync = context.read<SyncCubit>();

      final session = await auth.getActiveSession();
      if (session == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No active session. Sign in again.')),
        );
        return;
      }

      final err = await cubit.submitValetTicket();
      if (err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      if (!mounted) return;
      await sync.flush();
      if (!mounted) return;
      ValetLog.info(
        'check_in/review_print/_commitAndLeave',
        'success, navigating to print',
      );
      context.go('/check-in/print');
    } catch (e, st) {
      ValetLog.error(
        'check_in/review_print/_commitAndLeave',
        'save failed',
        e,
        st,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not save ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckInStepBody(
      showBack: true,
      onBack: _saving ? () {} : () => context.go('/check-in/step-4'),
      primaryLabel: _saving ? 'Saving…' : 'Confirm',
      onPrimary: () => unawaited(_commitAndLeave()),
      child: BlocBuilder<CheckInCubit, CheckInState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (w >= _wideBreakpoint) {
                return _ReviewWideGrid(
                  state: state,
                  onPrintTap: () => unawaited(_onPrintTap(context)),
                );
              }
              if (w >= _mediumBreakpoint) {
                return _ReviewMediumGrid(
                  state: state,
                  onPrintTap: () => unawaited(_onPrintTap(context)),
                );
              }
              return _ReviewNarrowStack(
                state: state,
                onPrintTap: () => _onPrintTap(context),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onPrintTap(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final state = cubit.state;
    final id = state.ticketNumber.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ticket number yet.')),
      );
      return;
    }
    final row = await context.read<TicketService>().ticketById(id);
    if (!context.mounted) return;
    if (row == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the ticket before printing.')),
      );
      return;
    }
    final auth = context.read<AuthRepository>();
    final base = CheckInReceiptData(
      ticket: row,
      branchName: '',
      customerName: state.customerFullName,
      contactNumber: state.contactNumber,
      parkingLevel: state.parkingLevel,
      parkingSlot: state.parkingSlot,
      valetTypeLabel: _valetTypeLabel(state.valetServiceType),
      specialRequest: state.specialInstructions,
      hasSignature: state.hasCustomerSignature,
    );
    final data = await withBranchName(auth, base);
    if (!context.mounted) return;
    await printCheckInFromContext(context, data: data);
  }
}

// --- Data helpers ---

String _valetTypeLabel(ValetServiceType t) {
  return switch (t) {
    ValetServiceType.standardValet => 'Standard Valet',
    ValetServiceType.selfPark => 'Self Park',
  };
}

String _vehicleLine(CheckInState s) {
  final parts = <String>[
    if (s.vehicleBrandMake.trim().isNotEmpty) s.vehicleBrandMake.trim(),
    if (s.vehicleModel.trim().isNotEmpty) s.vehicleModel.trim(),
    if (s.vehicleColor.trim().isNotEmpty) s.vehicleColor.trim(),
    if (s.vehicleYear.trim().isNotEmpty) s.vehicleYear.trim(),
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _belongingsLine(CheckInState s) {
  final parts = <String>[...s.selectedBelongings];
  if (s.otherBelongings.trim().isNotEmpty) {
    parts.add(s.otherBelongings.trim());
  }
  if (parts.isEmpty) return 'None declared';
  return parts.join(', ');
}

String _slotLine(CheckInState s) {
  final a = s.parkingLevel.trim();
  final b = s.parkingSlot.trim();
  if (a.isEmpty && b.isEmpty) return '—';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a · $b';
}

String _timeInFormatted(DateTime? d) {
  final dt = d ?? DateTime.now();
  return DateFormat('MMMM d, yyyy · h:mm a').format(dt);
}

// --- Layout grids (Figma: 3 columns on tablet) ---

class _ReviewWideGrid extends StatelessWidget {
  const _ReviewWideGrid({
    required this.state,
    required this.onPrintTap,
  });

  final CheckInState state;
  final VoidCallback onPrintTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CustomerValetCard(state: state),
              const SizedBox(height: CheckInCompactTokens.fieldGap),
              _VehicleCard(state: state),
            ],
          ),
        ),
        const SizedBox(width: CheckInCompactTokens.fieldGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConditionLogCard(state: state),
              const SizedBox(height: CheckInCompactTokens.fieldGap),
              _TimeCard(state: state),
            ],
          ),
        ),
        const SizedBox(width: CheckInCompactTokens.fieldGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QrCard(state: state, compact: false),
              const SizedBox(height: CheckInCompactTokens.fieldGap),
              _PrintBluetoothCard(onTap: onPrintTap),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewMediumGrid extends StatelessWidget {
  const _ReviewMediumGrid({
    required this.state,
    required this.onPrintTap,
  });

  final CheckInState state;
  final VoidCallback onPrintTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _CustomerValetCard(state: state),
                  const SizedBox(height: CheckInCompactTokens.fieldGap),
                  _VehicleCard(state: state),
                ],
              ),
            ),
            const SizedBox(width: CheckInCompactTokens.fieldGap),
            Expanded(
              child: Column(
                children: [
                  _ConditionLogCard(state: state),
                  const SizedBox(height: CheckInCompactTokens.fieldGap),
                  _TimeCard(state: state),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _QrCard(state: state, compact: true)),
            const SizedBox(width: CheckInCompactTokens.fieldGap),
            Expanded(child: _PrintBluetoothCard(onTap: onPrintTap)),
          ],
        ),
      ],
    );
  }
}

class _ReviewNarrowStack extends StatelessWidget {
  const _ReviewNarrowStack({
    required this.state,
    required this.onPrintTap,
  });

  final CheckInState state;
  final VoidCallback onPrintTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerValetCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _ConditionLogCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _VehicleCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _TimeCard(state: state),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _QrCard(state: state, compact: true),
        const SizedBox(height: CheckInCompactTokens.fieldGap),
        _PrintBluetoothCard(onTap: onPrintTap),
      ],
    );
  }
}

// --- Shared styles ---

class _ReviewTokens {
  static const hairline = Color(0x21000000);
  static const cardRadius = 10.0;

  static TextStyle sectionTitle() => CheckInCompactTokens.pageHeading();

  static TextStyle label() => CheckInCompactTokens.helperText().copyWith(
        fontWeight: FontWeight.w500,
        color: DashboardStyles.grey500,
      );

  static TextStyle value() => CheckInCompactTokens.fieldValue().copyWith(
        fontWeight: FontWeight.w500,
      );

  static TextStyle plateValue() => CheckInCompactTokens.fieldValue().copyWith(
        fontWeight: FontWeight.w700,
        color: DashboardStyles.plateBlue,
      );

  static TextStyle damageCount() => CheckInCompactTokens.bodyHint();
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.borderRadius,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final double borderRadius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label, style: _ReviewTokens.label())),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: valueStyle ?? _ReviewTokens.value(),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 6),
          Container(height: 1, color: _ReviewTokens.hairline),
        ],
      ],
    );
  }
}

// --- Cards ---

class _CustomerValetCard extends StatelessWidget {
  const _CustomerValetCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final special = state.specialInstructions.trim();
    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CUSTOMER & VALET', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Name',
            value: state.customerFullName.trim().isEmpty
                ? '—'
                : state.customerFullName.trim(),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Contact',
            value: state.contactNumber.trim().isEmpty
                ? '—'
                : state.contactNumber.trim(),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Valet Type',
            value: _valetTypeLabel(state.valetServiceType),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Valet Driver',
            value: state.assignedValetDriver.trim().isEmpty
                ? '—'
                : state.assignedValetDriver.trim(),
            showDivider: special.isNotEmpty,
          ),
          if (special.isNotEmpty) ...[
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            _ReviewRow(
              label: 'Special Request',
              value: special,
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _DamageChip extends StatelessWidget {
  const _DamageChip({required this.entry});

  final VehicleDamageEntry entry;

  static const _dentFg = Color(0xFFEC2231);
  static const _dentBg = Color(0xFFFFECEC);
  static const _scratchFg = Color(0xFFF68D00);
  static const _scratchBg = Color(0xFFFFF7EC);
  static const _crackFg = Color(0xFF0068D3);
  static const _crackBg = Color(0xFFECEFFF);

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (entry.type) {
      DamageType.dent => (_dentFg, _dentBg),
      DamageType.scratch => (_scratchFg, _scratchBg),
      DamageType.crack => (_crackFg, _crackBg),
    };
    final zone = entry.zoneLabel?.trim();
    final text = (zone != null && zone.isNotEmpty)
        ? '${entry.type.label} - $zone'
        : entry.type.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: fg),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _ConditionLogCard extends StatelessWidget {
  const _ConditionLogCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final n = state.vehicleDamageEntries.length;
    final countLabel = n == 1 ? '1 item marked' : '$n items marked';

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONDITION LOG', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          Text(countLabel, style: _ReviewTokens.damageCount()),
          if (state.vehicleDamageEntries.isNotEmpty) ...[
            const SizedBox(height: CheckInCompactTokens.sectionGap),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in state.vehicleDamageEntries)
                  _DamageChip(entry: e),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text('No damage logged.', style: _ReviewTokens.label()),
          ],
          const SizedBox(height: CheckInCompactTokens.blockGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Customer signature',
                  style: _ReviewTokens.label(),
                ),
              ),
              Text(
                state.hasCustomerSignature ? 'Signed ✓' : 'Not signed',
                style: _ReviewTokens.value().copyWith(
                  color: state.hasCustomerSignature
                      ? DashboardStyles.green
                      : DashboardStyles.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.state, this.compact = false});

  final CheckInState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ticket = state.ticketNumber.trim().isEmpty
        ? '—'
        : state.ticketNumber.trim();
    final qrSize = compact ? 160.0 : 200.0;

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        children: [
          SizedBox(
            width: qrSize,
            height: qrSize,
            child: state.ticketNumber.trim().isEmpty
                ? Center(
                    child: Text(
                      'QR appears after you confirm',
                      textAlign: TextAlign.center,
                      style: _ReviewTokens.label(),
                    ),
                  )
                : QrImageView(
                    data: state.ticketNumber.trim(),
                    version: QrVersions.auto,
                    gapless: false,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          Text(
            ticket,
            style: CheckInCompactTokens.fieldValue().copyWith(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: DashboardStyles.orange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Customer scans this QR at check-out',
            textAlign: TextAlign.center,
            style: _ReviewTokens.label().copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final plate = state.plateNumber.trim().isEmpty
        ? '—'
        : state.plateNumber.trim();

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEHICLE', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Plate No.',
            value: plate,
            valueStyle: plate == '—'
                ? _ReviewTokens.value()
                : _ReviewTokens.plateValue(),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Vehicle', value: _vehicleLine(state)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Type',
            value: state.vehicleBodyType.label,
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Slot', value: _slotLine(state)),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Belongings',
            value: _belongingsLine(state),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final ticket = state.ticketNumber.trim().isEmpty
        ? '—'
        : state.ticketNumber.trim();

    return _ReviewCard(
      borderRadius: _ReviewTokens.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIME', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(
            label: 'Time In',
            value: _timeInFormatted(state.dateTimeIn),
          ),
          const SizedBox(height: CheckInCompactTokens.sectionGap),
          _ReviewRow(label: 'Ticket No.', value: ticket, showDivider: false),
        ],
      ),
    );
  }
}

class _PrintBluetoothCard extends StatelessWidget {
  const _PrintBluetoothCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterConnectionNotifier>();
    final subtitle = printer.isConnected
        ? printer.statusSubtitle
        : 'Tap to pair Bluetooth printer';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardStyles.orange,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.27),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.printer,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Print Via Bluetooth',
                        style: CheckInCompactTokens.fieldValue().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CheckInCompactTokens.helperText().copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
