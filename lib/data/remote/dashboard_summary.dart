import '../../core/api/transaction_payment_fields.dart';
import '../../features/dashboard/domain/dashboard_recent_format.dart';

/// Default area capacity when API omits `total_slots`.
const int kDefaultDashboardTotalSlots = 30;

/// UI row for dashboard recent list (mapped from API or local tickets).
class DashboardRecentRow {
  const DashboardRecentRow({
    required this.ticketId,
    required this.plate,
    required this.line1,
    required this.line2,
    required this.isCheckedOut,
  });

  final String ticketId;
  final String plate;
  final String line1;
  final String line2;
  final bool isCheckedOut;
}

/// Parsed `GET /api/v1/dashboard/summary` (shift-scoped cashier dashboard).
class DashboardSummary {
  const DashboardSummary({
    required this.shiftId,
    required this.totalVehiclesIn,
    required this.checkedOutTotal,
    required this.activeSlots,
    required this.remainingCount,
    required this.totalSlots,
    required this.recent,
  });

  final String shiftId;
  final int totalVehiclesIn;
  final int checkedOutTotal;
  final int activeSlots;
  final int remainingCount;
  final int totalSlots;
  final List<DashboardSummaryRecent> recent;

  static DashboardSummary? fromResponseData(dynamic data) {
    final root = _asMap(data);
    if (root == null) return null;
    final body = _unwrapData(root);
    final recentRaw = body['recent_transactions'] ?? body['recentTransactions'];
    final recent = <DashboardSummaryRecent>[];
    if (recentRaw is List) {
      for (final item in recentRaw) {
        final row = _asMap(item);
        if (row == null) continue;
        final parsed = DashboardSummaryRecent.fromJson(row);
        if (parsed != null) recent.add(parsed);
      }
    }
    return DashboardSummary(
      shiftId: (body['shift_id'] ?? body['shiftId'] ?? '').toString(),
      totalVehiclesIn: _intField(
        body,
        const ['total_vehicles_in', 'totalVehiclesIn'],
        fallback: _intField(
          body,
          const ['parked_count', 'parkedCount'],
        ),
      ),
      checkedOutTotal: _intField(
        body,
        const ['checked_out_total', 'checkedOutTotal'],
      ),
      activeSlots: _intField(
        body,
        const ['active_slots', 'activeSlots'],
        fallback: _intField(body, const ['parked_count', 'parkedCount']),
      ),
      remainingCount: _remainingCount(body),
      totalSlots: _intField(
        body,
        const ['total_slots', 'totalSlots'],
        fallback: kDefaultDashboardTotalSlots,
      ),
      recent: recent,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Map<String, dynamic> _unwrapData(Map<String, dynamic> root) {
    for (final key in const ['data', 'result', 'summary']) {
      final v = root[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return root;
  }

  static int _remainingCount(Map<String, dynamic> body) {
    final fromApi = _intField(
      body,
      const ['remaining_count', 'remainingCount'],
      fallback: -1,
    );
    if (fromApi >= 0) return fromApi;
    final total = _intField(
      body,
      const ['total_slots', 'totalSlots'],
      fallback: kDefaultDashboardTotalSlots,
    );
    final occupied = _intField(
      body,
      const ['active_slots', 'activeSlots'],
      fallback: _intField(body, const ['parked_count', 'parkedCount']),
    );
    return (total - occupied).clamp(0, total);
  }

  static int _intField(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final raw = map[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw != null) {
        final parsed = int.tryParse(raw.toString());
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }
}

class DashboardSummaryRecent {
  const DashboardSummaryRecent({
    required this.id,
    required this.ticketNumber,
    required this.plateNumber,
    required this.status,
    this.amount,
    this.cashTendered,
    this.timeIn,
    this.timeOut,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.parkingSlot,
    this.rawJson,
  });

  final String id;
  final String ticketNumber;
  final String plateNumber;
  final String status;
  final num? amount;
  final double? cashTendered;
  final String? timeIn;
  final String? timeOut;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? parkingSlot;

  /// Original API row from `recent_transactions` (full transaction shape).
  final Map<String, dynamic>? rawJson;

  Map<String, dynamic> toTransactionJson() {
    if (rawJson != null && rawJson!.isNotEmpty) {
      return Map<String, dynamic>.from(rawJson!);
    }
    return <String, dynamic>{
      'id': id,
      'ticket_number': ticketNumber,
      'status': status,
      if (amount != null) 'amount': amount,
      if (cashTendered != null) 'cash_tendered': cashTendered,
      if (timeIn != null) 'time_in': timeIn,
      if (timeOut != null) 'time_out': timeOut,
    };
  }

  bool matchesKey(String key) {
    final k = key.trim();
    if (k.isEmpty) return false;
    return id == k || ticketNumber == k;
  }

  static DashboardSummaryRecent? fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['ticket_id'] ?? json['ticketId'] ?? '')
        .toString()
        .trim();
    if (id.isEmpty) return null;

    final vehicle = _asMap(json['vehicle']);
    String? brand;
    String? model;
    String? color;
    if (vehicle != null) {
      brand = _str(vehicle['brand']);
      model = _str(vehicle['model']);
      color = _str(vehicle['color']);
    }
    brand ??= _str(json['vehicle_brand'] ?? json['vehicleBrand']);
    model ??= _str(json['vehicle_model'] ?? json['vehicleModel']);
    color ??= _str(json['vehicle_color'] ?? json['vehicleColor']);

    final parking = _asMap(json['parking']);
    var slot = _str(json['parking_slot'] ?? json['parkingSlot'] ?? json['slot']);
    if ((slot == null || slot.isEmpty) && parking != null) {
      slot = _str(parking['slot']);
    }

    return DashboardSummaryRecent(
      id: id,
      ticketNumber: (json['ticket_number'] ?? json['ticketNumber'] ?? id)
          .toString()
          .trim(),
      plateNumber:
          (json['plate_number'] ?? json['plateNumber'] ?? '—').toString().trim(),
      status: (json['status'] ?? '').toString().trim(),
      amount: json['amount'] is num
          ? json['amount'] as num
          : num.tryParse('${json['amount']}'),
      cashTendered: TransactionPaymentFields.cashTenderedFrom(json),
      timeIn: (json['time_in'] ?? json['timeIn'])?.toString(),
      timeOut: (json['time_out'] ?? json['timeOut'])?.toString(),
      vehicleBrand: brand,
      vehicleModel: model,
      vehicleColor: color,
      parkingSlot: slot,
      rawJson: json,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _str(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  DashboardRecentRow toRecentRow() {
    final plate =
        plateNumber.isNotEmpty && plateNumber != '—' ? plateNumber : ticketNumber;
    final upper = status.toUpperCase();
    final completed = upper == 'COMPLETED' || upper == 'LOST';
    final line1 = DashboardRecentFormat.vehicleLine(
      brand: vehicleBrand,
      model: vehicleModel,
      color: vehicleColor,
    );

    if (completed) {
      final out = DateTime.tryParse(timeOut ?? '') ?? DateTime.now();
      final amt = amount?.toDouble();
      final payment = TransactionPaymentFields.resolve(
        amount: amt,
        cashTendered: cashTendered,
      );
      return DashboardRecentRow(
        ticketId: id,
        plate: plate,
        line1: line1,
        line2: DashboardRecentFormat.checkedOutSubline(
          out.toLocal(),
          amount,
          cashTendered: payment.cashTendered,
          change: payment.change,
        ),
        isCheckedOut: true,
      );
    }

    final inn = DateTime.tryParse(timeIn ?? timeOut ?? '') ?? DateTime.now();
    return DashboardRecentRow(
      ticketId: id,
      plate: plate,
      line1: line1,
      line2: DashboardRecentFormat.parkedSubline(
        inn.toLocal(),
        slot: parkingSlot,
      ),
      isCheckedOut: false,
    );
  }
}
