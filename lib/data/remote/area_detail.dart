import '../../core/session/standard_parking_rates.dart';

/// Fee row from area detail (`flatRate`, `succeedingRate`, etc.).
class ParkingRateFees {
  const ParkingRateFees({
    required this.flatRate,
    required this.succeedingRate,
    required this.overnightFee,
    required this.lostTicketFee,
  });

  final int flatRate;
  final int succeedingRate;
  final int overnightFee;
  final int lostTicketFee;

  bool get hasAny =>
      flatRate > 0 ||
      succeedingRate > 0 ||
      overnightFee > 0 ||
      lostTicketFee > 0;

  StandardParkingRates toStandardParkingRates() => StandardParkingRates(
        flatRatePesos: flatRate,
        succeedingHourPesos: succeedingRate,
        overnightFeePesos: overnightFee,
        lostTicketFeePesos: lostTicketFee,
      );

  static ParkingRateFees fromJson(Map<String, dynamic> json) {
    return ParkingRateFees(
      flatRate: _intField(json, const ['flatRate', 'flat_rate']),
      succeedingRate: _intField(json, const ['succeedingRate', 'succeeding_rate']),
      overnightFee: _intField(json, const ['overnightFee', 'overnight_fee']),
      lostTicketFee: _intField(json, const ['lostTicketFee', 'lost_ticket_fee']),
    );
  }

  static int _intField(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final raw = map[key];
      if (raw is int) return raw;
      if (raw is num) return raw.round();
      if (raw != null) {
        final parsed = int.tryParse(raw.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }
}

/// One row in `vehicleTypeRates`.
class VehicleTypeRateRow {
  const VehicleTypeRateRow({
    required this.id,
    required this.name,
    required this.fees,
  });

  final String id;
  final String name;
  final ParkingRateFees fees;

  static VehicleTypeRateRow? fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    return VehicleTypeRateRow(
      id: (json['id'] ?? name).toString(),
      name: name,
      fees: ParkingRateFees.fromJson(json),
    );
  }
}

/// One slot in `levels[].slots`.
class AreaParkingSlot {
  const AreaParkingSlot({
    required this.id,
    required this.label,
    required this.status,
  });

  final String id;
  final String label;
  final String status;

  bool get isAvailable {
    final s = status.trim().toUpperCase();
    return s == 'AVAILABLE' || s == 'FREE' || s == 'VACANT';
  }

  static AreaParkingSlot? fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? '').toString().trim();
    if (label.isEmpty) return null;
    return AreaParkingSlot(
      id: (json['id'] ?? label).toString(),
      label: label,
      status: (json['status'] ?? '').toString().trim(),
    );
  }
}

/// Parking level with nested slots (`levels[]` from area detail).
class AreaParkingLevel {
  const AreaParkingLevel({
    required this.id,
    required this.name,
    required this.slotPrefix,
    required this.slots,
  });

  final String id;
  final String name;
  final String slotPrefix;
  final List<AreaParkingSlot> slots;

  List<AreaParkingSlot> get availableSlots =>
      slots.where((s) => s.isAvailable).toList();

  int get totalCount => slots.length;

  int get availableCount => availableSlots.length;

  int get occupiedCount => totalCount - availableCount;

  static AreaParkingLevel? fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final slotsRaw = json['slots'];
    final slots = <AreaParkingSlot>[];
    if (slotsRaw is List) {
      for (final item in slotsRaw) {
        final row = _asMap(item);
        if (row == null) continue;
        final parsed = AreaParkingSlot.fromJson(row);
        if (parsed != null) slots.add(parsed);
      }
    }
    return AreaParkingLevel(
      id: (json['id'] ?? name).toString(),
      name: name,
      slotPrefix: (json['slotPrefix'] ?? json['slot_prefix'] ?? '').toString(),
      slots: slots,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}

/// Aggregated slot counts from all levels.
class AreaSlotCounts {
  const AreaSlotCounts({
    required this.total,
    required this.available,
    required this.occupied,
  });

  final int total;
  final int available;
  final int occupied;

  static const empty = AreaSlotCounts(total: 0, available: 0, occupied: 0);
}

/// `GET /api/v1/branches/{branchId}/areas/{areaId}`.
class AreaDetail {
  const AreaDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.standard,
    required this.vehicleTypeRates,
    required this.levels,
    required this.overnightTimes,
  });

  final String id;
  final String name;
  final String code;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;

  /// Area-level overnight window (`HH:mm`), applied to all cached rate rows.
  final ({String? start, String? end}) overnightTimes;

  AreaSlotCounts get slotCounts {
    if (levels.isEmpty) return AreaSlotCounts.empty;
    var total = 0;
    var available = 0;
    for (final level in levels) {
      total += level.totalCount;
      available += level.availableCount;
    }
    return AreaSlotCounts(
      total: total,
      available: available,
      occupied: total - available,
    );
  }

  static AreaDetail? fromResponseData(dynamic data) {
    final root = _asMap(data);
    if (root == null) return null;
    final body = _unwrap(body: root);

    final standard = ParkingRateFees.fromJson(body);
    final vehicleRows = _parseVehicleTypeRates(body);
    final levels = _parseLevels(body);

    if (!standard.hasAny && vehicleRows.isEmpty && levels.isEmpty) {
      return null;
    }

    return AreaDetail(
      id: (body['id'] ?? '').toString(),
      name: (body['name'] ?? '').toString().trim(),
      code: (body['code'] ?? '').toString().trim(),
      standard: standard,
      vehicleTypeRates: vehicleRows,
      levels: levels,
      overnightTimes: _parseOvernightTimes(body),
    );
  }

  static ({String? start, String? end}) _parseOvernightTimes(
    Map<String, dynamic> body,
  ) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = body[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    return (
      start: pick(const [
        'overnight_start',
        'overnightStart',
        'overnight_cutoff',
        'overnightCutoff',
      ]),
      end: pick(const ['overnight_end', 'overnightEnd']),
    );
  }

  static List<VehicleTypeRateRow> _parseVehicleTypeRates(
    Map<String, dynamic> body,
  ) {
    final listRaw = body['vehicleTypeRates'] ?? body['vehicle_type_rates'];
    final rows = <VehicleTypeRateRow>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        final row = _asMap(item);
        if (row == null) continue;
        final parsed = VehicleTypeRateRow.fromJson(row);
        if (parsed != null && parsed.fees.hasAny) rows.add(parsed);
      }
    }
    return rows;
  }

  static List<AreaParkingLevel> _parseLevels(Map<String, dynamic> body) {
    final listRaw = body['levels'];
    final levels = <AreaParkingLevel>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        final row = _asMap(item);
        if (row == null) continue;
        final parsed = AreaParkingLevel.fromJson(row);
        if (parsed != null && parsed.slots.isNotEmpty) levels.add(parsed);
      }
    }
    return levels;
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Map<String, dynamic> _unwrap({required Map<String, dynamic> body}) {
    for (final key in const ['data', 'area', 'result']) {
      final v = body[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return body;
  }
}

/// Back-compat alias.
typedef AreaRatesDetail = AreaDetail;
