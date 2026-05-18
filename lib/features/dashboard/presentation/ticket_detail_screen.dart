import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../../check_out/domain/ticket_damage_markers.dart';
import '../domain/ticket_parking_info.dart';
import 'widgets/dashboard_widgets.dart';

const _pesoFallback = ['Noto Sans', 'Roboto'];

TextStyle _detailLabelStyle() => GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: DashboardStyles.grey500,
      height: 1.35,
    );

TextStyle _detailValueStyle() => GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      height: 1.4,
    ).copyWith(fontFamilyFallback: _pesoFallback);

TextStyle _detailHintStyle() => GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: DashboardStyles.grey500,
      height: 1.4,
    );

Widget _detailKv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: _detailLabelStyle()),
        ),
        Expanded(child: Text(value, style: _detailValueStyle())),
      ],
    ),
  );
}

/// Read-only ticket summary (dashboard recent list: API when online, else Drift).
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Future<TicketDetailSnapshot?>? _future;

  static final _dateFmt = DateFormat('MMM dd, yyyy, hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        context.read<TicketService>().loadTicketForDetail(widget.ticketId.trim());
  }

  static List<String> _belongingsList(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        return d
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static String _damageLine(VehicleDamageEntry e) {
    final z = (e.zoneLabel?.trim().isNotEmpty ?? false)
        ? e.zoneLabel!.trim()
        : (lookupVehicleZoneLabel(e.normalizedX, e.normalizedY) ?? 'Unknown area');
    return '$z — ${e.type.label}';
  }

  static String _formatDurationHm(Duration d) {
    final totalM = d.inMinutes;
    final h = totalM ~/ 60;
    final m = totalM % 60;
    if (h < 1) return '${totalM}m';
    return '${h}h ${m}m';
  }

  static String? _plainDriverName(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t.startsWith('{')) return null;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardStyles.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ticket details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<TicketDetailSnapshot?>(
        future: _future,
        builder: (context, snap) {
          if (_future == null ||
              snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snap.data;
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ticket not found. Connect to load from server, or open this ticket on this device.',
                  style: DashboardStyles.statHint(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final t = detail.ticket;
          final parking = detail.parking;

          final checkIn = DateTime.tryParse(t.checkInAt);
          final checkOut = DateTime.tryParse(t.checkOutAt ?? '');
          final isCompleted = t.status == 'completed';
          final isLost = t.status == 'lost';

          final checkInLabel =
              checkIn != null ? _dateFmt.format(checkIn.toLocal()) : '—';
          final checkOutLabel = checkOut != null
              ? _dateFmt.format(checkOut.toLocal())
              : '—';

          String durationLabel;
          if (checkIn == null) {
            durationLabel = '—';
          } else if (isCompleted && checkOut != null) {
            durationLabel = _formatDurationHm(checkOut.difference(checkIn));
          } else {
            durationLabel =
                _formatDurationHm(DateTime.now().difference(checkIn));
          }

          final damageLines = parseTicketDamageMarkersForCheckout(t.damageMarkers)
              .map(_damageLine)
              .toList();

          final belongings = _belongingsList(t.personalBelongings);
          final belongingsText =
              belongings.isEmpty ? 'None' : belongings.join(', ');

          final statusLabel = switch (t.status) {
            'completed' => 'Completed',
            'lost' => 'Lost',
            _ => 'Active',
          };

          final statusColor = isCompleted
              ? const Color(0xFF6E7584)
              : isLost
                  ? const Color(0xFFB45309)
                  : DashboardStyles.green;

          final plate = t.plateNumber.trim().isEmpty ? '—' : t.plateNumber.trim();
          final driverIn = _plainDriverName(t.driverIn);
          final driverOut = _plainDriverName(t.driverOut);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeroHeaderCard(
                ticketId: t.id,
                plate: plate,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),
              const SizedBox(height: 16),
              if (parking != null && parking.hasAny)
                _ParkingLocationCard(parking: parking)
              else
                _DetailCard(
                  icon: LucideIcons.mapPin,
                  title: 'Parking location',
                  child: Text(
                    'No parking details on file.',
                    style: _detailHintStyle(),
                  ),
                ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: LucideIcons.car,
                title: 'Vehicle',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _detailKv('Plate', plate),
                    _detailKv(
                      'Make / model',
                      t.vehicleBrand.trim().isEmpty ? '—' : t.vehicleBrand.trim(),
                    ),
                    _detailKv(
                      'Color',
                      t.vehicleColor.trim().isEmpty ? '—' : t.vehicleColor.trim(),
                    ),
                    _detailKv(
                      'Type',
                      t.vehicleType.trim().isEmpty ? '—' : t.vehicleType.trim(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: LucideIcons.phone,
                title: 'Contact',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _detailKv(
                      'Cellphone',
                      t.cellphoneNumber.trim().isEmpty
                          ? '—'
                          : t.cellphoneNumber.trim(),
                    ),
                    if (driverIn != null) _detailKv('Driver in', driverIn),
                    if (driverOut != null) _detailKv('Driver out', driverOut),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: LucideIcons.clock,
                title: 'Times',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _detailKv('Check-in', checkInLabel),
                    _detailKv('Check-out', checkOutLabel),
                    _detailKv(
                      isCompleted ? 'Total duration' : 'Elapsed duration',
                      durationLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: LucideIcons.alertCircle,
                title: 'Damage markers',
                child: damageLines.isEmpty
                    ? Text('None', style: _detailValueStyle())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final line in damageLines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(line, style: _detailValueStyle()),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                icon: LucideIcons.briefcase,
                title: 'Personal belongings',
                child: Text(belongingsText, style: _detailValueStyle()),
              ),
              if (isCompleted && t.fee != null) ...[
                const SizedBox(height: 12),
                _DetailCard(
                  icon: LucideIcons.creditCard,
                  title: 'Payment',
                  child: _detailKv(
                    'Fee paid',
                    PesoCurrency.currency(decimalDigits: 2).format(t.fee),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

}

class _HeroHeaderCard extends StatelessWidget {
  const _HeroHeaderCard({
    required this.ticketId,
    required this.plate,
    required this.statusLabel,
    required this.statusColor,
  });

  final String ticketId;
  final String plate;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plate', style: _detailLabelStyle()),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardStyles.plateBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DashboardStyles.plateBlue),
                      ),
                      child: Text(
                        plate,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: DashboardStyles.plateBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Ticket ID', style: _detailLabelStyle()),
          const SizedBox(height: 4),
          Text(
            ticketId,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkingLocationCard extends StatelessWidget {
  const _ParkingLocationCard({required this.parking});

  final TicketParkingInfo parking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0068D3), Color(0xFF004A9C)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260068D3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PARKING LOCATION',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Where to find this vehicle',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ParkingChip(
                  label: 'Area',
                  value: parking.areaLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ParkingChip(
                  label: 'Level',
                  value: parking.levelLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ParkingChip(
                  label: 'Slot',
                  value: parking.slotLabel,
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParkingChip extends StatelessWidget {
  const _ParkingChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: emphasize ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: emphasize ? 0.45 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: DashboardStyles.plateBlue),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: DashboardStyles.sectionTitle(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
