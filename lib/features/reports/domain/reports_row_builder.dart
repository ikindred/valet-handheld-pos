import '../../../core/time/philippine_time.dart';
import '../../../data/local/db/app_database.dart';
import '../../check_out/domain/checkout_pricing.dart';
import '../../dashboard/domain/dashboard_recent_format.dart';
import '../../dashboard/domain/ticket_parking_info.dart';
import 'reports_format.dart';
import 'reports_models.dart';

/// Builds [ReportsTicketRow] from local [Ticket] rows (no I/O).
abstract final class ReportsRowBuilder {
  static ReportsTicketRow fromTicket(
    Ticket t, {
    DateTime? now,
    int flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
  }) {
    final clock = now ?? PhilippineTime.now();
    final timeIn = PhilippineTime.parseWallIso(t.checkInAt);
    DateTime? timeOut;
    if (t.checkOutAt != null && t.checkOutAt!.trim().isNotEmpty) {
      timeOut = PhilippineTime.parseWallIso(t.checkOutAt!);
    }
    final end = timeOut ?? clock;
    final duration = end.difference(timeIn);
    final flatMinutes = flatBlockHours * 60;
    final isLongStay =
        t.status == 'active' && duration.inMinutes > flatMinutes;

    final parking = t.parkingInfo != null
        ? TicketParkingInfo.fromJsonString(t.parkingInfo!)
        : TicketParkingInfo.fromDriverOutMeta(t.driverOut);

    final status = t.status == 'completed'
        ? ReportsTicketRowStatus.checkedOut
        : isLongStay
            ? ReportsTicketRowStatus.longStay
            : ReportsTicketRowStatus.parked;

    final serverId = t.serverTicketId?.trim();
    return ReportsTicketRow(
      ticketId: t.id,
      serverTransactionId:
          serverId != null && serverId.isNotEmpty ? serverId : null,
      plate: t.plateNumber.trim().isEmpty ? '—' : t.plateNumber.trim(),
      vehicle: DashboardRecentFormat.vehicleLineFromTicket(t),
      timeIn: timeIn,
      timeOut: timeOut,
      duration: duration.isNegative ? Duration.zero : duration,
      slot: ReportsFormat.slotCode(
        slot: parking.slot,
        parkingJson: t.parkingInfo,
      ),
      status: status,
      fee: t.fee,
    );
  }
}
