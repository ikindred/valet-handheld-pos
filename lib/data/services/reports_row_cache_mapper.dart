import '../../features/reports/domain/reports_format.dart';
import '../../features/reports/domain/reports_models.dart';
import 'reports_today_row_mapper.dart';

/// Maps `GET /reports/transactions` rows into Drift upsert JSON.
abstract final class ReportsRowCacheMapper {
  static Map<String, dynamic> fromReportsRow(
    ReportsTicketRow row, {
    bool markExpress = false,
  }) {
    final serverId = row.serverTransactionId?.trim() ?? '';
    final status = row.isVoided
        ? 'void'
        : switch (row.status) {
            ReportsTicketRowStatus.checkedOut => 'completed',
            ReportsTicketRowStatus.longStay => 'long_stay',
            ReportsTicketRowStatus.parked => 'active',
          };

    final plate = row.plate.trim();
    final vehicle = row.vehicle.trim();
    final vr = row.vrNo.trim();

    final raw = <String, dynamic>{
      if (serverId.isNotEmpty) 'id': serverId,
      'ticket_number': row.ticketId,
      'status': status,
      if (row.fee != null) 'amount': row.fee,
      if (row.cashTendered != null) 'cash_tendered': row.cashTendered,
      'time_in': row.timeInDisplay?.trim().isNotEmpty == true
          ? row.timeInDisplay!.trim()
          : row.timeIn.toIso8601String(),
      if (row.timeOut != null) 'time_out': row.timeOut!.toIso8601String(),
      if (plate.isNotEmpty && plate != '—') 'plate_number': plate,
      'vehicle': <String, dynamic>{
        if (plate.isNotEmpty && plate != '—') 'plate_number': plate,
        if (vehicle.isNotEmpty && vehicle != '—') 'brand': vehicle,
      },
      if (vr.isNotEmpty && vr != '—') 'vr_no': vr,
      if (row.slot.trim().isNotEmpty && row.slot != '—')
        'slot': row.slot.trim(),
    };

    return ReportsTodayRowMapper.toServerCacheJson(
      raw,
      markExpress: markExpress,
    );
  }
}
