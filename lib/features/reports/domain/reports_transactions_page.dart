import '../../../core/api/transaction_payment_fields.dart';
import '../../../core/api/void_audit_info.dart';
import '../../../core/time/philippine_time.dart';
import 'reports_format.dart';
import 'reports_models.dart';

/// Paginated `GET /api/v1/reports/transactions` response.
class ReportsTransactionsPage {
  const ReportsTransactionsPage({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.rows,
  });

  static const empty = ReportsTransactionsPage(
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 0,
    rows: [],
  );

  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final List<ReportsTicketRow> rows;

  bool get hasMore => page < totalPages;

  factory ReportsTransactionsPage.fromJson(dynamic data) {
    if (data is! Map) return empty;
    final m = Map<String, dynamic>.from(data);
    final rawRows = m['data'];
    final list = rawRows is List ? rawRows : const [];
    return ReportsTransactionsPage(
      total: _int(m['total']),
      page: _int(m['page'], fallback: 1),
      limit: _int(m['limit'], fallback: 20),
      totalPages: _int(m['totalPages'] ?? m['total_pages']),
      rows: [
        for (final e in list)
          if (e is Map) ReportsTicketRowMapper.fromApi(Map<String, dynamic>.from(e)),
      ],
    );
  }

  static int _int(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}

abstract final class ReportsTicketRowMapper {
  static ReportsTicketRow fromApi(Map<String, dynamic> json) {
    final serverId = _str(json['id']);
    final ticketNumber = _str(json['ticket_number'] ?? json['ticketNumber']);
    final plate = _str(json['plate_number'] ?? json['plateNumber']);
    final vrNo = _vrNo(json);
    final vehicleRaw = _str(json['vehicle']);
    final color = _str(json['color']);
    final vehicle = _vehicleLine(vehicleRaw, color);
    final timeInRaw = _str(json['time_in'] ?? json['timeIn']);
    final timeOutRaw = _str(json['time_out'] ?? json['timeOut']);
    final durationDisplay =
        _str(json['duration_display'] ?? json['durationDisplay']);
    final durationMinutes =
        _int(json['duration_minutes'] ?? json['durationMinutes']);
    final slot = _str(json['slot']);
    final statusRaw = _str(json['status']).toLowerCase();
    final amount = _double(json['amount']);
    final cashTendered = TransactionPaymentFields.cashTenderedFrom(json);
    final voidAudit = VoidAuditInfo.tryFromJson(json);

    return ReportsTicketRow(
      ticketId: ticketNumber.isEmpty ? '—' : ticketNumber,
      serverTransactionId: serverId.isEmpty ? null : serverId,
      plate: plate.isEmpty ? '—' : plate,
      vrNo: vrNo.isEmpty ? '—' : vrNo,
      vehicle: vehicle.isEmpty ? '—' : vehicle,
      timeIn: _timeInAsToday(timeInRaw),
      timeInDisplay: timeInRaw.isEmpty ? null : timeInRaw,
      timeOut: timeOutRaw.isEmpty ? null : _timeInAsToday(timeOutRaw),
      duration: Duration(minutes: durationMinutes.clamp(0, 1 << 20)),
      durationDisplay: durationDisplay.isEmpty ? null : durationDisplay,
      slot: slot.isEmpty ? '—' : slot,
      status: _statusFromApi(statusRaw),
      fee: amount,
      cashTendered: cashTendered,
      hasPendingVoid: false,
      isVoided:
          VoidAuditInfo.isVoidStatus(statusRaw) || voidAudit?.isPopulated == true,
    );
  }

  static String _vehicleLine(String vehicle, String color) {
    if (vehicle.isEmpty && color.isEmpty) return '';
    if (vehicle.isEmpty) return color;
    if (color.isEmpty) return vehicle;
    return '$vehicle · $color';
  }

  static DateTime _timeInAsToday(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return DateTime.now();
    final parts = t.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final min = int.tryParse(parts[1]) ?? 0;
      final ph = PhilippineTime.now();
      return DateTime(ph.year, ph.month, ph.day, h, min);
    }
    final parsed = DateTime.tryParse(t);
    return parsed ?? DateTime.now();
  }

  static ReportsTicketRowStatus _statusFromApi(String raw) {
    return switch (raw) {
      'long_stay' || 'longstay' => ReportsTicketRowStatus.longStay,
      'completed' || 'complete' || 'checked_out' =>
        ReportsTicketRowStatus.checkedOut,
      'lost' => ReportsTicketRowStatus.checkedOut,
      'void' || 'voided' => ReportsTicketRowStatus.checkedOut,
      'parked' => ReportsTicketRowStatus.parked,
      'active' => ReportsTicketRowStatus.parked,
      _ => ReportsTicketRowStatus.parked,
    };
  }

  static String _vrNo(Map<String, dynamic> json) {
    final top = _str(json['vr_no'] ?? json['vrNo']);
    if (top.isNotEmpty) return top;
    final vehicle = json['vehicle'];
    if (vehicle is Map) {
      final m = Map<String, dynamic>.from(vehicle);
      return _str(m['vr_no'] ?? m['vrNo']);
    }
    return '';
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    if (v is Map && v.isEmpty) return '';
    return v.toString().trim();
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double? _double(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
