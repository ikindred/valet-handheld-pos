import '../../core/api/transaction_payment_fields.dart';
import '../../core/api/void_audit_info.dart';
import '../../core/formatting/valet_type_format.dart';
import '../../features/check_in/domain/vehicle_body_type.dart';
import '../../features/dashboard/domain/dashboard_recent_format.dart';

/// Default area capacity when API omits `total_slots`.
const int kDefaultDashboardTotalSlots = 30;

/// UI row for dashboard recent list (mapped from API or local tickets).
class DashboardRecentRow {
  const DashboardRecentRow({
    required this.ticketId,
    required this.plate,
    required this.plateNumber,
    required this.ticketNumber,
    required this.line1,
    required this.line2,
    required this.isCheckedOut,
  });

  final String ticketId;
  /// Badge label — plate number if available, else ticket number.
  final String plate;
  /// Actual plate number (empty string if unknown); shown in blue badge.
  final String plateNumber;
  /// Formatted ticket number (e.g. TKT-0123); shown in orange badge.
  final String ticketNumber;
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

  /// Checked-out rows in `recent_transactions` grouped by vehicle type rate key.
  Map<String, int> checkoutCountsByVehicleRateKey() {
    final counts = <String, int>{};
    for (final row in recent) {
      if (!row.isCheckedOutStatus) continue;
      final key = row.vehicleTypeRateKey;
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

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
    this.cashierId,
    this.amount,
    this.cashTendered,
    this.timeIn,
    this.timeOut,
    this.vehicleBrand,
    this.vehicleColor,
    this.parkingSlot,
    this.vrNo,
    this.valetType,
    this.voidAudit,
    this.rawJson,
  });

  final String id;
  final String ticketNumber;
  final String plateNumber;
  final String status;

  /// Server user UUID (`user.id` from login) who owns this transaction.
  final String? cashierId;
  final num? amount;
  final double? cashTendered;
  final String? timeIn;
  final String? timeOut;
  final String? vehicleBrand;
  final String? vehicleColor;
  final String? parkingSlot;
  final String? vrNo;

  /// `standard_valet` | `self_park` from API.
  final String? valetType;

  /// Flat void audit from API (`void_reason`, `voided_by`, `voided_at`).
  final VoidAuditInfo? voidAudit;

  bool get hasPendingVoid => false;

  bool get isVoided =>
      VoidAuditInfo.isVoidStatus(status) || voidAudit?.isPopulated == true;

  bool get isCheckedOutStatus {
    final upper = status.toUpperCase();
    return upper == 'COMPLETED' || upper == 'LOST';
  }

  /// Normalized key for close-cash vehicle type cards (`sedan`, `suv`, …).
  String? get vehicleTypeRateKey {
    final raw = _rawVehicleType();
    if (raw == null) return null;
    return normalizeVehicleTypeRateKey(raw);
  }

  String? _rawVehicleType() {
    final json = rawJson;
    if (json == null) return null;
    final vehicle = _asMap(json['vehicle']);
    if (vehicle != null) {
      for (final key in const [
        'type',
        'vehicle_type',
        'vehicleType',
        'body_type',
        'bodyType',
      ]) {
        final raw = _str(vehicle[key]);
        if (raw != null) return raw;
      }
    }
    for (final key in const ['vehicle_type', 'vehicleType', 'body_type']) {
      final raw = _str(json[key]);
      if (raw != null) return raw;
    }
    return null;
  }

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
    String? color;
    if (vehicle != null) {
      brand = _str(vehicle['brand']);
      color = _str(vehicle['color']);
    }
    brand ??= _str(json['vehicle_brand'] ?? json['vehicleBrand']);
    color ??= _str(json['vehicle_color'] ?? json['vehicleColor']);

    // plate_number lives inside the vehicle object; fall back to top-level keys
    final rawPlate = _str(vehicle?['plate_number']) ??
        _str(json['plate_number'] ?? json['plateNumber']);

    final parking = _asMap(json['parking']);
    var slot = _str(json['parking_slot'] ?? json['parkingSlot'] ?? json['slot']);
    if ((slot == null || slot.isEmpty) && parking != null) {
      slot = _str(parking['slot']);
    }

    final vrNo = _str(json['vr_no'] ?? json['vrNo']) ??
        (vehicle != null ? _str(vehicle['vr_no'] ?? vehicle['vrNo']) : null);

    final valetType = ValetTypeFormat.rawFromTransaction(json);

    final cashierIdRaw = _str(json['cashier_id'] ?? json['user_id']);
    return DashboardSummaryRecent(
      id: id,
      ticketNumber: (json['ticket_number'] ?? json['ticketNumber'] ?? id)
          .toString()
          .trim(),
      plateNumber: rawPlate ?? '—',
      status: (json['status'] ?? '').toString().trim(),
      cashierId: cashierIdRaw,
      amount: json['amount'] is num
          ? json['amount'] as num
          : num.tryParse('${json['amount']}'),
      cashTendered: TransactionPaymentFields.cashTenderedFrom(json),
      timeIn: _strOrNull(json['time_in'] ?? json['timeIn']),
      timeOut: _strOrNull(json['time_out'] ?? json['timeOut']),
      vehicleBrand: brand,
      vehicleColor: color,
      parkingSlot: slot,
      vrNo: vrNo,
      valetType: valetType,
      voidAudit: VoidAuditInfo.tryFromJson(json),
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

  /// Returns a trimmed string only if [value] is a non-empty [String];
  /// rejects objects/maps that the API sends as `{}` placeholders.
  static String? _strOrNull(dynamic value) {
    if (value is! String) return null;
    final s = value.trim();
    return s.isEmpty ? null : s;
  }

  DashboardRecentRow toRecentRow() {
    final actualPlate =
        plateNumber.isNotEmpty && plateNumber != '—' ? plateNumber : '';
    final badgePlate = actualPlate.isNotEmpty ? actualPlate : ticketNumber;
    final upper = status.toUpperCase();
    final completed = upper == 'COMPLETED' || upper == 'LOST';
    final line1 = DashboardRecentFormat.vehicleLine(
      brand: vehicleBrand,
      color: vehicleColor,
    );

    if (completed) {
      final inn = DateTime.tryParse(timeIn ?? '') ?? DateTime.now();
      final out = DateTime.tryParse(timeOut ?? '') ?? DateTime.now();
      return DashboardRecentRow(
        ticketId: id,
        plate: badgePlate,
        plateNumber: actualPlate,
        ticketNumber: ticketNumber,
        line1: line1,
        line2: DashboardRecentFormat.checkedOutSubline(
          inn.toLocal(),
          out.toLocal(),
        ),
        isCheckedOut: true,
      );
    }

    final inn = DateTime.tryParse(timeIn ?? timeOut ?? '') ?? DateTime.now();
    return DashboardRecentRow(
      ticketId: id,
      plate: badgePlate,
      plateNumber: actualPlate,
      ticketNumber: ticketNumber,
      line1: line1,
      line2: DashboardRecentFormat.parkedSubline(
        inn.toLocal(),
        slot: parkingSlot,
      ),
      isCheckedOut: false,
    );
  }
}
