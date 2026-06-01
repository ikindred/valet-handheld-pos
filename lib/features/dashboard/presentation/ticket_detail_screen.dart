import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/api/transaction_payment_summary.dart';
import '../../../core/connectivity/internet_reachability.dart';
import '../../../core/formatting/peso_currency.dart';
import '../../../data/remote/transactions_api.dart';
import '../../../core/printing/checkout_receipt_data.dart';
import '../../../core/printing/print_flow.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/philippine_time.dart';
import '../../../core/printing/receipt_print_format.dart';
import '../../check_out/domain/checkout_pricing.dart';
import '../../check_out/models/checkout_preview_rates.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/ticket_service.dart';
import '../../check_in/domain/vehicle_damage.dart';
import '../../check_in/domain/vehicle_damage_zones.dart';
import '../../check_out/domain/ticket_damage_markers.dart';
import '../domain/ticket_parking_info.dart';
import 'widgets/dashboard_widgets.dart';

const _pesoFallback = ['Noto Sans', 'Roboto'];

TextStyle _detailLabelStyle(BuildContext context) {
  final tc = AppThemeColors.of(context);
  return GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: tc.textSecondary,
    height: 1.35,
  );
}

TextStyle _detailValueStyle(BuildContext context) {
  final tc = AppThemeColors.of(context);
  return GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: tc.textPrimary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: _pesoFallback);
}

TextStyle _detailHintStyle(BuildContext context) {
  final tc = AppThemeColors.of(context);
  return GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: tc.textSecondary,
    height: 1.4,
  );
}

Widget _detailKv(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: _detailLabelStyle(context)),
        ),
        Expanded(child: Text(value, style: _detailValueStyle(context))),
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
  bool _printing = false;
  bool _voidLoading = false;
  bool _editPlateLoading = false;
  bool? _isOnline;

  static final _dateFmt = DateFormat('MMM dd, yyyy, hh:mm a');
  static const _defaultMallHours = 'MONDAY – SUNDAY · 10:00AM – 9:00PM';

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    final online = await InternetReachability.hasInternet();
    if (mounted) setState(() => _isOnline = online);
  }

  void _reloadDetail() {
    setState(() {
      _future = context.read<TicketService>().loadTicketForDetail(
        widget.ticketId.trim(),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<TicketService>().loadTicketForDetail(
      widget.ticketId.trim(),
    );
  }

  Future<void> _requestVoid(TicketDetailSnapshot detail, String? reason) async {
    if (_voidLoading) return;
    final t = detail.ticket;
    final isOnline = _isOnline ?? false;

    setState(() => _voidLoading = true);
    try {
      final tickets = context.read<TicketService>();
      if (isOnline) {
        final serverId = t.serverTicketId?.trim();
        if (serverId == null || serverId.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ticket is not synced to the server yet. Try again when online.',
              ),
            ),
          );
          return;
        }
        await tickets.requestTicketVoid(
          serverTicketId: serverId,
          reason: reason,
        );
      } else if (t.syncStatus == 'pending') {
        await tickets.storeOfflineVoidRequest(t.id, reason);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to the internet to request a void.'),
          ),
        );
        return;
      }
      if (!mounted) return;
      _reloadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Void request submitted.')),
      );
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not request void: $e')),
      );
    } finally {
      if (mounted) setState(() => _voidLoading = false);
    }
  }

  Future<void> _showVoidConfirmDialog(TicketDetailSnapshot detail) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _VoidConfirmDialog(),
    );
    if (reason != null && mounted) {
      await _requestVoid(detail, reason.isEmpty ? null : reason);
    }
  }

  Future<void> _showEditPlateDialog(TicketDetailSnapshot detail) async {
    final current = detail.ticket.plateNumber.trim();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditPlateDialog(currentPlate: current),
    );
    if (result == null || !mounted) return;
    await _updatePlate(detail.ticket.id, result);
  }

  Future<void> _updatePlate(String localTicketId, String newPlate) async {
    if (_editPlateLoading) return;
    setState(() => _editPlateLoading = true);
    try {
      await context.read<TicketService>().updatePlateNumber(
        localTicketId: localTicketId,
        newPlate: newPlate,
      );
      if (!mounted) return;
      _reloadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plate number updated.')),
      );
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update plate number: $e')),
      );
    } finally {
      if (mounted) setState(() => _editPlateLoading = false);
    }
  }

  bool _canShowVoidButton(TicketDetailSnapshot detail) {
    final t = detail.ticket;
    if (t.status != 'active') return false;
    if (detail.hasPendingVoid) return false;
    final isOnline = _isOnline ?? false;
    if (isOnline) return true;
    return t.syncStatus == 'pending';
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
        : (lookupVehicleZoneLabel(e.normalizedX, e.normalizedY) ??
              'Unknown area');
    return '$z — ${e.type.label}';
  }

  static String? _plainDriverName(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t.startsWith('{')) return null;
    return t;
  }

  static bool _showPaymentSummary(
    TicketDetailSnapshot detail,
    Ticket t,
    bool isCompleted,
    bool isLost,
    DateTime? checkOut,
  ) {
    if (detail.payment != null) return true;
    final fee = t.fee;
    if (fee == null || fee < 0.009) return false;
    return isCompleted || isLost || checkOut != null;
  }

  Future<void> _reprintReceipt(TicketDetailSnapshot detail) async {
    if (_printing) return;
    final total = detail.payment?.totalDue ?? detail.ticket.fee;
    if (total == null || total < 0.009) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment amount on file for this ticket.'),
        ),
      );
      return;
    }

    setState(() => _printing = true);
    try {
      final auth = context.read<AuthRepository>();
      final site = await auth.branchAndAreaFromDb();
      final branch = site.branch.trim();
      final area = site.area.trim();
      final branchLabel = branch.isEmpty && area.isEmpty
          ? null
          : (area.isEmpty ? branch : '$branch · $area');

      final data = CheckoutReceiptData.fromTicketDetail(
        ticket: detail.ticket,
        parking: detail.parking,
        branchDisplayName: branchLabel,
        mallHours: _defaultMallHours,
        payment: detail.payment,
      );
      if (!mounted) return;
      await printCheckOutFromContext(context, data: data);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Widget _buildBody(
    AsyncSnapshot<TicketDetailSnapshot?> snap,
    TicketDetailSnapshot? detail,
  ) {
    if (_future == null || snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ticket not found. Connect to load from server, or open this ticket on this device.',
            style: DashboardStyles.statHintOf(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final t = detail.ticket;
    final parking = detail.parking;

    final checkIn = PhilippineTime.fromApiIso(t.checkInAt);
    final checkOut = t.checkOutAt != null && t.checkOutAt!.trim().isNotEmpty
        ? PhilippineTime.fromApiIso(t.checkOutAt!)
        : null;
    final isCompleted = t.status == 'completed';
    final isLost = t.status == 'lost';

    final checkInLabel = _dateFmt.format(checkIn);
    final checkOutLabel = checkOut != null ? _dateFmt.format(checkOut) : '—';

    String durationLabel;
    if (isCompleted && checkOut != null) {
      final minutes = CheckoutPricing.durationMinutesCeil(checkIn, checkOut);
      durationLabel = ReceiptPrintFormat.durationLabel(minutes);
    } else {
      final minutes = CheckoutPricing.durationMinutesCeil(
        checkIn,
        PhilippineTime.now(),
      );
      durationLabel = ReceiptPrintFormat.durationLabel(minutes);
    }

    final damageLines = parseTicketDamageMarkersForCheckout(
      t.damageMarkers,
    ).map(_damageLine).toList();

    final belongings = _belongingsList(t.personalBelongings);
    final belongingsText = belongings.isEmpty ? 'None' : belongings.join(', ');

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
          onEditPlate: t.status == 'active' && !_editPlateLoading
              ? () => _showEditPlateDialog(detail)
              : null,
          editPlateLoading: _editPlateLoading,
        ),
        if (detail.hasPendingVoid) ...[
          const SizedBox(height: 12),
          _VoidPendingBanner(),
        ],
        if (_canShowVoidButton(detail)) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _voidLoading
                ? null
                : () => _showVoidConfirmDialog(detail),
            icon: _voidLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.ban, size: 18),
            label: Text(_voidLoading ? 'Submitting…' : 'Request void'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFB45309)),
            ),
          ),
        ],
        if (detail.isOvernight == true || detail.isTicketLost == true) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.isOvernight == true)
                const _StatusChip(
                  label: 'Overnight applied',
                  color: Color(0xFF1D4ED8),
                ),
              if (detail.isTicketLost == true)
                const _StatusChip(
                  label: 'Lost ticket fee',
                  color: Color(0xFFB45309),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (parking != null && parking.hasAny)
          _ParkingLocationCard(parking: parking)
        else
          _DetailCard(
            icon: LucideIcons.mapPin,
            title: 'Parking location',
            child: Text(
              'No parking details on file.',
              style: _detailHintStyle(context),
            ),
          ),
        const SizedBox(height: 12),
        _DetailCard(
          icon: LucideIcons.car,
          title: 'Vehicle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailKv(context, 'Plate', plate),
              _detailKv(context, 
                'Make / model',
                t.vehicleBrand.trim().isEmpty ? '—' : t.vehicleBrand.trim(),
              ),
              _detailKv(context, 
                'Color',
                t.vehicleColor.trim().isEmpty ? '—' : t.vehicleColor.trim(),
              ),
              _detailKv(context, 
                'Type',
                t.vehicleType.trim().isEmpty ? '—' : t.vehicleType.trim(),
              ),
              if (t.vrNo != null && t.vrNo!.trim().isNotEmpty)
                _detailKv(context, 'VR No.', t.vrNo!.trim()),
            ],
          ),
        ),
        if (detail.appliedRate != null) ...[
          const SizedBox(height: 12),
          _AppliedRateCard(rates: detail.appliedRate!),
        ],
        const SizedBox(height: 12),
        _DetailCard(
          icon: LucideIcons.phone,
          title: 'Contact',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailKv(context, 
                'Cellphone',
                t.cellphoneNumber.trim().isEmpty
                    ? '—'
                    : t.cellphoneNumber.trim(),
              ),
              if (driverIn != null) _detailKv(context, 'Driver in', driverIn),
              if (driverOut != null) _detailKv(context, 'Returning Valet Attendant', driverOut),
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
              _detailKv(context, 'Check-in', checkInLabel),
              _detailKv(context, 'Check-out', checkOutLabel),
              _detailKv(context, 
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
              ? Text('None', style: _detailValueStyle(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final line in damageLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(line, style: _detailValueStyle(context)),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          icon: LucideIcons.briefcase,
          title: 'Personal belongings',
          child: Text(belongingsText, style: _detailValueStyle(context)),
        ),
        if (_showPaymentSummary(detail, t, isCompleted, isLost, checkOut)) ...[
          const SizedBox(height: 12),
          _PaymentSummaryCard(payment: detail.payment, ticket: t),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TicketDetailSnapshot?>(
      future: _future,
      builder: (context, snap) {
        final detail = snap.connectionState == ConnectionState.done
            ? snap.data
            : null;
        final canReprint =
            detail != null &&
            (detail.ticket.status == 'completed' ||
                detail.ticket.status == 'lost');

        final tc = AppThemeColors.of(context);
        return Scaffold(
          backgroundColor: tc.scaffoldBg,
          appBar: AppBar(
            backgroundColor: tc.cardBg,
            foregroundColor: tc.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: tc.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Ticket details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tc.textPrimary,
              ),
            ),
            centerTitle: false,
            actions: [
              if (canReprint)
                _ReprintAppBarAction(
                  printing: _printing,
                  onPressed: _printing ? null : () => _reprintReceipt(detail),
                ),
            ],
          ),
          body: _buildBody(snap, detail),
        );
      },
    );
  }
}

class _VoidPendingBanner extends StatelessWidget {
  const _VoidPendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.clock, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Void requested — awaiting admin approval',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AppliedRateCard extends StatelessWidget {
  const _AppliedRateCard({required this.rates});

  final CheckoutPreviewRates rates;

  @override
  Widget build(BuildContext context) {
    final peso = PesoCurrency.currency(decimalDigits: 2);
    return _DetailCard(
      icon: LucideIcons.receipt,
      title: 'Applied rate (at checkout)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _detailKv(context, 'Flat rate', peso.format(rates.flatRate)),
          if (rates.flatRateHours > 0)
            _detailKv(context, 'Flat hours', '${rates.flatRateHours}'),
          _detailKv(context, 'Succeeding rate', peso.format(rates.succeedingRate)),
          _detailKv(context, 'Overnight fee', peso.format(rates.overnightFee)),
          if (rates.overnightStart.isNotEmpty && rates.overnightEnd.isNotEmpty)
            _detailKv(context, 
              'Overnight window',
              '${rates.overnightStart} – ${rates.overnightEnd}',
            ),
          _detailKv(context, 'Lost ticket fee', peso.format(rates.lostTicketFee)),
        ],
      ),
    );
  }
}

class _ReprintAppBarAction extends StatelessWidget {
  const _ReprintAppBarAction({required this.printing, required this.onPressed});

  final bool printing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (printing) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DashboardStyles.orange,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          LucideIcons.printer,
          size: 18,
          color: DashboardStyles.orange,
        ),
        label: Text(
          'Reprint',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DashboardStyles.orange,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 40),
        ),
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
    this.onEditPlate,
    this.editPlateLoading = false,
  });

  final String ticketId;
  final String plate;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onEditPlate;
  final bool editPlateLoading;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final isDark = AppThemeColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.cardBorder),
        boxShadow: isDark
            ? const []
            : const [
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
                    Text('Plate', style: _detailLabelStyle(context)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: tc.plateBadgeBg,
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
                        if (onEditPlate != null || editPlateLoading) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: editPlateLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DashboardStyles.plateBlue,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: onEditPlate,
                                    icon: const Icon(
                                      LucideIcons.pencil,
                                      size: 16,
                                    ),
                                    color: DashboardStyles.plateBlue,
                                    tooltip: 'Edit plate number',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
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
          Text('Ticket ID', style: _detailLabelStyle(context)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SelectableText(
                  ticketId,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tc.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                onPressed: ticketId.trim().isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: ticketId));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ticket ID copied'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: const Icon(LucideIcons.copy, size: 20),
                tooltip: 'Copy ticket ID',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                color: tc.textSecondary,
              ),
            ],
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
                child: _ParkingChip(label: 'Area', value: parking.areaLabel),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ParkingChip(label: 'Level', value: parking.levelLabel),
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

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.payment, required this.ticket});

  final TransactionPaymentSummary? payment;
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final peso = PesoCurrency.currency(decimalDigits: 2);
    final p = payment;
    final total = p?.totalDue ?? ticket.fee ?? 0;

    final hasSucceeding =
        p != null && (p.hasSucceedingTotal || p.succeedingTotal > 0.009);
    final hasOvernight = p != null && (p.hasOvernightFee || p.isOvernight);
    final hasLost = p != null && (p.hasLostTicketFee || p.isLostTicket);
    final hasDuration = p != null && p.durationMinutes > 0;

    return _DetailCard(
      icon: LucideIcons.creditCard,
      title: 'Payment summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDuration)
            _detailKv(context, 
              'Duration',
              ReceiptPrintFormat.durationLabel(p.durationMinutes),
            ),
          if (p != null && p.hasFlatRate)
            _detailKv(context, p.flatRateLabel, peso.format(p.flatRate)),
          if (hasSucceeding) ...[
            _detailKv(context, 'Succeeding hours', p.succeedingHoursLabel),
            _detailKv(context, 'Succeeding total', peso.format(p.succeedingTotal)),
          ],
          if (hasOvernight)
            _OvernightFeeRow(
              label: ReceiptPrintFormat.overnightFeeRowLabel(
                startHhMm24: p.overnightStart,
                endHhMm24: p.overnightEnd,
              ),
              amount: peso.format(p.overnightFee),
            ),
          if (hasLost)
            _detailKv(context, 'Lost ticket fee', peso.format(p.lostTicketFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Color(0x14000000)),
          ),
          _TotalDueRow(amount: peso.format(total)),
          const SizedBox(height: 8),
          _detailKv(context, 
            'Cash tendered',
            p != null && p.hasCashTendered ? peso.format(p.cashTendered) : '—',
          ),
          _detailKv(context, 
            'Change',
            p != null && p.hasChange ? peso.format(p.change) : '—',
          ),
        ],
      ),
    );
  }
}

class _OvernightFeeRow extends StatelessWidget {
  const _OvernightFeeRow({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    // Extract window substring "(…)" to display on a second line so the row
    // never overflows when the label is long.
    String mainLabel = label;
    String? windowSuffix;
    final parenStart = label.indexOf('(');
    if (parenStart > 0) {
      mainLabel = label.substring(0, parenStart).trim();
      windowSuffix = label.substring(parenStart).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.moon,
                      size: 13,
                      color: Color(0xFF7C5DB5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mainLabel,
                      style: _detailLabelStyle(context).copyWith(
                        color: const Color(0xFF7C5DB5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (windowSuffix != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 17, top: 2),
                    child: Text(
                      windowSuffix,
                      style: _detailLabelStyle(context).copyWith(
                        color: const Color(0xFF9E7ED4),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: _detailValueStyle(context).copyWith(
              color: const Color(0xFF7C5DB5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalDueRow extends StatelessWidget {
  const _TotalDueRow({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              'Total due',
              style: _detailLabelStyle(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              amount,
              style: _detailValueStyle(context).copyWith(
                color: DashboardStyles.orange,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoidConfirmDialog extends StatefulWidget {
  const _VoidConfirmDialog();

  @override
  State<_VoidConfirmDialog> createState() => _VoidConfirmDialogState();
}

class _VoidConfirmDialogState extends State<_VoidConfirmDialog> {
  final _reasonCtrl = TextEditingController();

  static const _maxWidth = 360.0;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: const Icon(
                    LucideIcons.ban,
                    size: 24,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Request void?',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This ticket will be flagged for admin review. Provide a reason if needed.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  hintText: 'Reason (optional) — e.g. Duplicate ticket',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9DA4B0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_reasonCtrl.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8831A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPlateDialog extends StatefulWidget {
  const _EditPlateDialog({required this.currentPlate});

  final String currentPlate;

  @override
  State<_EditPlateDialog> createState() => _EditPlateDialogState();
}

class _EditPlateDialogState extends State<_EditPlateDialog> {
  late final TextEditingController _ctrl;

  static const _maxWidth = 360.0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentPlate);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Dialog(
      backgroundColor: tc.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tc.plateBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DashboardStyles.plateBlue.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 22,
                    color: DashboardStyles.plateBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit plate number',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: tc.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the corrected plate number for this ticket.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: tc.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. ABC1234',
                  filled: true,
                  fillColor: tc.inputFill,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: tc.textSubtitleMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tc.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tc.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: DashboardStyles.orange,
                      width: 1.2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tc.textPrimary,
                  letterSpacing: 0.5,
                ),
                maxLength: 20,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tc.textSecondary,
                        side: BorderSide(color: tc.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardStyles.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final plate = _ctrl.text.trim().toUpperCase();
    if (plate.isEmpty) return;
    Navigator.of(context).pop(plate);
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
    final tc = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: DashboardStyles.plateBlue),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: DashboardStyles.sectionTitleOf(context)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
