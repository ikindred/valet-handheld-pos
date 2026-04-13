import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../../check_out/domain/ticket_damage_markers.dart';
import 'widgets/dashboard_widgets.dart';

/// Read-only ticket summary from local Drift (opened from dashboard recent list).
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Future<Ticket?>? _future;

  static final _dateFmt = DateFormat('MMM dd, yyyy, hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        context.read<TicketService>().ticketById(widget.ticketId.trim());
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
      body: FutureBuilder<Ticket?>(
        future: _future,
        builder: (context, snap) {
          if (_future == null ||
              snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final t = snap.data;
          if (t == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ticket not found.',
                  style: DashboardStyles.statHint(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

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

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                t.id,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Vehicle'),
              _kv('Plate number', t.plateNumber.trim().isEmpty ? '—' : t.plateNumber.trim()),
              _kv('Brand', t.vehicleBrand.trim().isEmpty ? '—' : t.vehicleBrand.trim()),
              _kv('Color', t.vehicleColor.trim().isEmpty ? '—' : t.vehicleColor.trim()),
              _kv('Type', t.vehicleType.trim().isEmpty ? '—' : t.vehicleType.trim()),
              const SizedBox(height: 20),
              _sectionTitle('Contact'),
              _kv(
                'Cellphone',
                t.cellphoneNumber.trim().isEmpty ? '—' : t.cellphoneNumber.trim(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Times'),
              _kv('Check-in', checkInLabel),
              _kv('Check-out', checkOutLabel),
              _kv(
                isCompleted ? 'Total duration' : 'Elapsed duration',
                durationLabel,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Damage markers'),
              if (damageLines.isEmpty)
                Text('None', style: _valueStyle())
              else
                ...damageLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line, style: _valueStyle()),
                  ),
                ),
              const SizedBox(height: 20),
              _sectionTitle('Personal belongings'),
              Text(belongingsText, style: _valueStyle()),
              if (isCompleted && t.fee != null) ...[
                const SizedBox(height: 20),
                _sectionTitle('Payment'),
                _kv(
                  'Fee paid',
                  PesoCurrency.currency(decimalDigits: 2).format(t.fee),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _sectionTitle(String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        s.toUpperCase(),
        style: DashboardStyles.sectionTitle(),
      ),
    );
  }

  static Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: DashboardStyles.grey500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: _valueStyle())),
        ],
      ),
    );
  }

  static const List<String> _pesoFallback = ['Noto Sans', 'Roboto'];

  static TextStyle _valueStyle() => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textPrimary,
      ).copyWith(fontFamilyFallback: _pesoFallback);
}
