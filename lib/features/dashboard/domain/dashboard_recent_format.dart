import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../data/local/db/app_database.dart';
import 'ticket_parking_info.dart';

/// Copy for dashboard recent-transaction rows (Figma dashboard card).
abstract final class DashboardRecentFormat {
  static const _amountFmt = '#,##0.00';

  /// e.g. `Toyota Vios · White`
  static String vehicleLine({
    String? brand,
    String? model,
    String? color,
    String? combinedBrand,
  }) {
    final make = _vehicleMake(brand: brand, model: model, combined: combinedBrand);
    final c = color?.trim() ?? '';
    if (make.isEmpty && c.isEmpty) return '—';
    if (make.isEmpty) return c;
    if (c.isEmpty) return make;
    return '$make · $c';
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
    final slotLabel = slotSuffix(slot: slot, parkingJson: parkingJson);
    return 'In at ${DateFormat.jm().format(timeLocal)} — $slotLabel';
  }

  static String checkedOutSubline(
    DateTime timeLocal,
    num? amount, {
    double? cashTendered,
    double? change,
  }) {
    final feeStr = amount != null
        ? '${PesoCurrency.symbol}${NumberFormat(_amountFmt).format(amount)}'
        : '—';
    final timePart = 'Out at ${DateFormat.jm().format(timeLocal)}';
    final tendered = cashTendered;
    if (tendered != null && tendered > 0.009) {
      final tenderedStr =
          '${PesoCurrency.symbol}${NumberFormat(_amountFmt).format(tendered)}';
      final ch = change ??
          (amount != null && tendered > (amount as num).toDouble() + 1e-6
              ? tendered - (amount as num).toDouble()
              : 0.0);
      if (ch > 0.009) {
        final changeStr =
            '${PesoCurrency.symbol}${NumberFormat(_amountFmt).format(ch)}';
        return '$timePart — $feeStr · Cash $tenderedStr · Chg $changeStr';
      }
      return '$timePart — $feeStr · Cash $tenderedStr';
    }
    return '$timePart — $feeStr';
  }

  static String _vehicleMake({
    String? brand,
    String? model,
    String? combined,
  }) {
    final b = brand?.trim() ?? '';
    final m = model?.trim() ?? '';
    if (b.isNotEmpty && m.isNotEmpty) return '$b $m';
    if (b.isNotEmpty) return b;
    if (m.isNotEmpty) return m;
    return combined?.trim() ?? '';
  }
}
