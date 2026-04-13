import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/logging/valet_log.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../sync/state/sync_cubit.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../domain/vehicle_body_type.dart';
import '../domain/vehicle_damage.dart';
import '../state/check_in_cubit.dart';
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

  static const double _wideBreakpoint = 960.0;

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
              final wide = constraints.maxWidth >= _wideBreakpoint;
              if (wide) {
                // Stack top + bottom cards per column so row height isn't driven by
                // the tallest card (QR), which left a large gap under shorter cards.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CustomerValetCard(state: state),
                          const SizedBox(height: 16),
                          _VehicleCard(state: state),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ConditionLogCard(state: state),
                          const SizedBox(height: 16),
                          _TimeCard(state: state),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QrCard(state: state),
                          const SizedBox(height: 16),
                          _PrintBluetoothCard(
                            onTap: () => _onPrintTap(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CustomerValetCard(state: state),
                  const SizedBox(height: 16),
                  _ConditionLogCard(state: state),
                  const SizedBox(height: 16),
                  _QrCard(state: state),
                  const SizedBox(height: 16),
                  _VehicleCard(state: state),
                  const SizedBox(height: 16),
                  _TimeCard(state: state),
                  const SizedBox(height: 16),
                  _PrintBluetoothCard(onTap: () => _onPrintTap(context)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onPrintTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bluetooth print is not connected yet.')),
    );
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

// --- Shared styles ---

class _ReviewTokens {
  static const title = Color(0xFF0A1B39);
  static const hairline = Color(0x21000000);

  static TextStyle sectionTitle() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: title,
  );

  static TextStyle label() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: DashboardStyles.grey500,
  );

  static TextStyle value() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: title,
  );

  static TextStyle plateValue() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: DashboardStyles.plateBlue,
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.borderRadius,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
          const SizedBox(height: 8),
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
    return _ReviewCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CUSTOMER & VALET', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: 25),
          _ReviewRow(
            label: 'Name',
            value: state.customerFullName.trim().isEmpty
                ? '—'
                : state.customerFullName.trim(),
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            label: 'Contact',
            value: state.contactNumber.trim().isEmpty
                ? '—'
                : state.contactNumber.trim(),
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            label: 'Valet Type',
            value: _valetTypeLabel(state.valetServiceType),
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            label: 'Valet Driver',
            value: state.assignedValetDriver.trim().isEmpty
                ? '—'
                : state.assignedValetDriver.trim(),
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            label: 'Special Request',
            value: state.specialInstructions.trim().isEmpty
                ? '—'
                : state.specialInstructions.trim(),
            showDivider: false,
          ),
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
    final suffix = (zone != null && zone.isNotEmpty) ? zone : '—';
    final text = '${entry.type.label} · $suffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
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
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONDITION LOG', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: 16),
          _ReviewRow(label: 'Damage items', value: countLabel),
          const SizedBox(height: 12),
          if (state.vehicleDamageEntries.isEmpty)
            Text('No damage logged.', style: _ReviewTokens.label())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in state.vehicleDamageEntries)
                  _DamageChip(entry: e),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Customer signature', style: _ReviewTokens.label()),
              ),
              Text(
                state.hasCustomerSignature ? 'Signed ✓' : 'Not signed',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
  const _QrCard({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final ticket = state.ticketNumber.trim().isEmpty
        ? '—'
        : state.ticketNumber.trim();

    return _ReviewCard(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 254,
            height: 254,
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
          const SizedBox(height: 12),
          Text(
            ticket,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DashboardStyles.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer scans this QR at check-out',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
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
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEHICLE', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: 25),
          _ReviewRow(
            label: 'Plate No.',
            value: plate,
            valueStyle: plate == '—'
                ? _ReviewTokens.value()
                : _ReviewTokens.plateValue(),
          ),
          const SizedBox(height: 14),
          _ReviewRow(label: 'Vehicle', value: _vehicleLine(state)),
          const SizedBox(height: 14),
          _ReviewRow(
            label: 'Type',
            value: state.vehicleBodyType.label,
          ),
          const SizedBox(height: 14),
          _ReviewRow(label: 'Slot', value: _slotLine(state)),
          const SizedBox(height: 14),
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
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIME', style: _ReviewTokens.sectionTitle()),
          const SizedBox(height: 25),
          _ReviewRow(
            label: 'Time In',
            value: _timeInFormatted(state.dateTimeIn),
          ),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.27),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.printer,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Print Via Bluetooth',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Valet Master Printer · Connected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.70),
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
