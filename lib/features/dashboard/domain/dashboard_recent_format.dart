import 'package:intl/intl.dart';

import '../../../data/local/db/app_database.dart';
import 'ticket_parking_info.dart';

/// Copy for dashboard recent-transaction rows (Figma dashboard card).
abstract final class DashboardRecentFormat {
  /// e.g. `Toyota Vios · White`
  static String vehicleLine({
    String? brand,
    String? color,
    String? combinedBrand,
  }) {
    final b = brand?.trim().isNotEmpty == true ? brand!.trim() : (combinedBrand?.trim() ?? '');
    final c = color?.trim() ?? '';
    if (b.isEmpty && c.isEmpty) return '—';
    if (b.isEmpty) return c;
    if (c.isEmpty) return b;
    return '$b · $c';
  }

  static String vehicleLineFromTicket(Ticket t) => vehicleLine(
        combinedBrand: t.vehicleBrand,
        color: t.vehicleColor,
      );

  static String slotSuffix({String? slot, String? parkingJson}) {
    var s = slot?.trim() ?? '';
    if (s.isEmpty && parkingJson != null && parkingJson.trim().isNotEmpty) {
      final info = TicketParkingInfo.fromJsonString(parkingJson);
      if (info.slotLabel != '—') s = info.slotLabel;
    }
    if (s.isEmpty) return '—';
    return s.toLowerCase().startsWith('slot ') ? s : 'Slot $s';
  }

  static String parkedSubline(DateTime timeLocal, {String? slot, String? parkingJson}) {
    return 'In at ${DateFormat.jm().format(timeLocal)}';
  }

  static String checkedOutSubline(
    DateTime inLocal,
    DateTime outLocal,
  ) {
    final inPart = 'In at ${DateFormat.jm().format(inLocal)}';
    final outPart = 'Out at ${DateFormat.jm().format(outLocal)}';
    return '$inPart — $outPart';
  }
}
