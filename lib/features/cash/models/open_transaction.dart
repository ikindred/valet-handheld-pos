import '../../../core/time/philippine_time.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/remote/dashboard_summary.dart';
import '../../dashboard/domain/dashboard_recent_format.dart';
import '../../dashboard/domain/ticket_parking_info.dart';
import '../../reports/domain/reports_format.dart';
import '../../reports/domain/reports_models.dart';
import 'close_cash_shift_stats.dart';

/// Lightweight row for cash modals — active check-ins from local Drift only.
class OpenTransaction {
  const OpenTransaction({
    required this.ticketId,
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleColor,
    required this.vehicleType,
    required this.checkInAtRaw,
    required this.timeIn,
    this.slot = '—',
  });

  final String ticketId;
  final String ticketNumber;
  final String plateNumber;
  final String? vehicleBrand;
  final String? vehicleColor;

  /// Raw `vehicle_type` from local ticket (e.g. `sedan`, `suv`).
  final String vehicleType;

  /// Drift `check_in_at` string (PH wall or API ISO).
  final String checkInAtRaw;

  /// Check-in wall time (Philippines), never checkout time.
  final DateTime timeIn;
  final String slot;

  factory OpenTransaction.fromTicket(Ticket t) {
    final parking = t.parkingInfo != null && t.parkingInfo!.trim().isNotEmpty
        ? TicketParkingInfo.fromJsonString(t.parkingInfo!)
        : TicketParkingInfo.fromDriverOutMeta(t.driverOut);
    final plate = t.plateNumber.trim();
    return OpenTransaction(
      ticketId: t.id,
      ticketNumber: t.id,
      plateNumber: plate.isEmpty ? '—' : plate,
      vehicleBrand: t.vehicleBrand,
      vehicleColor: t.vehicleColor,
      vehicleType: t.vehicleType.trim(),
      checkInAtRaw: t.checkInAt,
      timeIn: PhilippineTime.fromApiIso(t.checkInAt),
      slot: ReportsFormat.slotCode(
        slot: parking.slot,
        parkingJson: t.parkingInfo,
      ),
    );
  }

  /// Builds an [OpenTransaction] from a server-side [ReportsTicketRow].
  ///
  /// Used during the pre-open-cash check so the cashier can see remote-only
  /// parked vehicles (checked in on another device) before acknowledging.
  factory OpenTransaction.fromReportsRow(ReportsTicketRow row) {
    final vehicle = row.vehicle.trim();
    return OpenTransaction(
      ticketId: row.serverTransactionId ?? row.ticketId,
      ticketNumber: row.ticketId,
      plateNumber: row.plate,
      vehicleBrand: vehicle.isEmpty ? null : vehicle,
      vehicleColor: null,
      vehicleType: '',
      checkInAtRaw: row.timeIn.toIso8601String(),
      timeIn: row.timeIn,
      slot: row.slot,
    );
  }

  /// Builds an [OpenTransaction] from a dashboard summary recent row.
  factory OpenTransaction.fromDashboardSummaryRecent(
    DashboardSummaryRecent r,
  ) {
    return OpenTransaction(
      ticketId: r.id,
      ticketNumber: r.ticketNumber,
      plateNumber: r.plateNumber == '—' ? '' : r.plateNumber,
      vehicleBrand: r.vehicleBrand,
      vehicleColor: r.vehicleColor,
      vehicleType: '',
      checkInAtRaw: r.timeIn ?? '',
      timeIn: r.timeIn != null
          ? (DateTime.tryParse(r.timeIn!)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      slot: r.parkingSlot ?? '—',
    );
  }

  String get vehicleTypeLabel {
    final raw = vehicleType.trim();
    if (raw.isEmpty) return '—';
    return CloseCashShiftStats.vehicleTypeLabel(raw);
  }

  String get vehicleLabel => DashboardRecentFormat.vehicleLine(
        combinedBrand: vehicleBrand,
        color: vehicleColor,
      );

  /// Elapsed time since check-in (clamped at zero).
  static String formatParkedDuration(
    String checkInRaw, [
    DateTime? clock,
  ]) {
    return ReportsFormat.durationLabel(
      PhilippineTime.elapsedSinceCheckIn(checkInRaw, clock),
    );
  }
}
