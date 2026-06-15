import 'dart:convert';

import '../../core/branch/overnight_window.dart';
import '../../core/session/standard_parking_rates.dart';
import '../../features/check_in/domain/vehicle_body_type.dart';
import '../../features/check_out/domain/checkout_pricing.dart';

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

  /// Top-level fee fields, else nested `rate` / `rates` (branch detail API).
  static Map<String, dynamic>? ratePayloadFrom(Map<String, dynamic> body) {
    if (fromJson(body).hasAny) return body;
    final nested = body['rate'] ?? body['rates'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return null;
  }

  static ParkingRateFees resolveFromBody(Map<String, dynamic> body) {
    final payload = ratePayloadFrom(body);
    if (payload != null) return fromJson(payload);
    return const ParkingRateFees(
      flatRate: 0,
      succeedingRate: 0,
      overnightFee: 0,
      lostTicketFee: 0,
    );
  }
}

/// One row in `vehicleTypeRates`.
class VehicleTypeRateRow {
  const VehicleTypeRateRow({
    required this.id,
    required this.name,
    required this.fees,
    this.vehicleType,
    this.flatRateHours = 0,
  });

  final String id;
  final String name;
  final ParkingRateFees fees;

  /// API slug (`sedan`, `ev_phev`, …) when present.
  final String? vehicleType;

  /// Per-vehicle flat block hours; `0` means inherit branch/area default.
  final int flatRateHours;

  /// Normalized Drift / [VehicleBodyType.rateKey] slug for this row.
  String? get rateKey {
    final fromSlug = normalizeVehicleTypeRateKey(vehicleType);
    if (fromSlug != null) return fromSlug;
    return BranchRatesSnapshot.mapServerVehicleTypeName(name);
  }

  static VehicleTypeRateRow? fromJson(Map<String, dynamic> json) {
    final vtRaw =
        (json['vehicle_type'] ?? json['vehicleType'] ?? '').toString().trim();
    var name = (json['name'] ?? '').toString().trim();
    if (name.isEmpty && vtRaw.isNotEmpty) {
      name = vehicleTypeDisplayLabel(vtRaw);
    }
    if (name.isEmpty) return null;
    return VehicleTypeRateRow(
      id: (json['id'] ?? (vtRaw.isEmpty ? name : vtRaw)).toString(),
      name: name,
      vehicleType: vtRaw.isEmpty ? null : vtRaw,
      fees: ParkingRateFees.fromJson(json),
      flatRateHours: BranchRatesSnapshot.flatHoursFromMap(json),
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

  bool get isOccupied => !isAvailable;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'status': status,
      };

  /// Available slots first, then occupied; within each group by label.
  static List<AreaParkingSlot> sortAvailableFirst(
    Iterable<AreaParkingSlot> slots,
  ) {
    final list = slots.toList();
    list.sort((a, b) {
      if (a.isAvailable != b.isAvailable) {
        return a.isAvailable ? -1 : 1;
      }
      return a.label.compareTo(b.label);
    });
    return list;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slotPrefix': slotPrefix,
        'slots': [for (final s in slots) s.toJson()],
      };

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

  /// Parses cached layout JSON from Drift (`parking_area_layouts.levels_json`).
  static List<AreaParkingLevel> listFromJsonString(String raw) {
    if (raw.trim().isEmpty) return const [];
    try {
      final body = jsonDecode(raw);
      if (body is! List) return const [];
      final levels = <AreaParkingLevel>[];
      for (final item in body) {
        final row = _asMap(item);
        if (row == null) continue;
        final parsed = AreaParkingLevel.fromJson(row);
        if (parsed != null && parsed.slots.isNotEmpty) levels.add(parsed);
      }
      return levels;
    } catch (_) {
      return const [];
    }
  }

  static String listToJsonString(List<AreaParkingLevel> levels) =>
      jsonEncode([for (final l in levels) l.toJson()]);

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

/// Body from `GET /api/v1/rates/branches/:branchId` (`vehicleTypeRates`, `areaOverrides`, …).
class BranchRatesApiPayload {
  const BranchRatesApiPayload({
    required this.areaOverrides,
    required this.vehicleTypeRates,
    required this.overnightTimes,
  });

  final List<Map<String, dynamic>> areaOverrides;
  final List<Map<String, dynamic>> vehicleTypeRates;
  final ({String? start, String? end}) overnightTimes;

  static BranchRatesApiPayload? fromResponseData(dynamic data) {
    final root = AreaDetail._asMap(data);
    if (root == null) return null;
    final body = AreaDetail._unwrap(body: root);

    return BranchRatesApiPayload(
      areaOverrides: _parseOverrideList(
        body['areaOverrides'] ?? body['area_overrides'],
      ),
      vehicleTypeRates: _parseOverrideList(
        body['vehicleTypeRates'] ?? body['vehicle_type_rates'],
      ),
      overnightTimes: AreaDetail._parseOvernightTimes(body),
    );
  }

  static List<Map<String, dynamic>> _parseOverrideList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      final row = AreaDetail._asMap(item);
      if (row != null) out.add(row);
    }
    return out;
  }

  Map<String, dynamic>? _matchAreaOverride({
    required String areaId,
    required String areaCode,
  }) {
    final id = areaId.trim();
    final code = areaCode.trim().toLowerCase();
    for (final row in areaOverrides) {
      final oid = (row['id'] ?? '').toString().trim();
      if (id.isNotEmpty && oid.isNotEmpty && oid == id) return row;
      final ocode = (row['code'] ?? '').toString().trim().toLowerCase();
      if (code.isNotEmpty && ocode.isNotEmpty && ocode == code) return row;
    }
    return null;
  }

  /// Area VT rows when matched; else branch-level `vehicleTypeRates` (no legacy standard row).
  BranchRatesSnapshot resolveForArea({
    required String areaId,
    String areaCode = '',
    int defaultFlatBlockHours = CheckoutPricing.defaultFlatBlockHours,
  }) {
    final override = _matchAreaOverride(areaId: areaId, areaCode: areaCode);
    if (override != null) {
      final flatHours = BranchRatesSnapshot.flatHoursFromMap(override);
      final vehicleRows = AreaDetail._parseVehicleTypeRates(override);
      return BranchRatesSnapshot(
        standard: const ParkingRateFees(
          flatRate: 0,
          succeedingRate: 0,
          overnightFee: 0,
          lostTicketFee: 0,
        ),
        vehicleTypeRates: vehicleRows,
        overnightTimes: overnightTimes,
        flatBlockHours:
            flatHours > 0 ? flatHours : defaultFlatBlockHours,
        usesAreaOverride: true,
      );
    }

    final vehicleRows = _parseActiveVehicleTypeRateRows(vehicleTypeRates);
    final flatHours = BranchRatesSnapshot.defaultFlatHoursFromVehicleRows(
      vehicleRows,
      fallbackHours: defaultFlatBlockHours,
    );

    return BranchRatesSnapshot(
      standard: const ParkingRateFees(
        flatRate: 0,
        succeedingRate: 0,
        overnightFee: 0,
        lostTicketFee: 0,
      ),
      vehicleTypeRates: vehicleRows,
      overnightTimes: overnightTimes,
      flatBlockHours: flatHours,
      usesAreaOverride: false,
    );
  }

  static List<VehicleTypeRateRow> _parseActiveVehicleTypeRateRows(
    List<Map<String, dynamic>> rows,
  ) {
    final out = <VehicleTypeRateRow>[];
    for (final row in rows) {
      final status = row['status']?.toString().toUpperCase();
      if (status != null && status.isNotEmpty && status != 'ACTIVE') continue;
      final parsed = VehicleTypeRateRow.fromJson(row);
      if (parsed != null && parsed.fees.hasAny) out.add(parsed);
    }
    return out;
  }
}

/// Branch standard rates from `GET /api/v1/branches/{id}` (`rate` object).
class BranchRatesSnapshot {
  const BranchRatesSnapshot({
    required this.standard,
    required this.vehicleTypeRates,
    required this.overnightTimes,
    required this.flatBlockHours,
    this.usesAreaOverride = false,
  });

  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final ({String? start, String? end}) overnightTimes;
  final int flatBlockHours;

  /// True when fees came from `areaOverrides` for the signed-in area.
  final bool usesAreaOverride;

  static BranchRatesSnapshot? fromResponseData(
    dynamic data, {
    int defaultFlatBlockHours = 3,
  }) {
    final root = AreaDetail._asMapPublic(data);
    if (root == null) return null;
    final body = AreaDetail._unwrapPublic(body: root);

    final standard = ParkingRateFees.resolveFromBody(body);
    final vehicleRows = AreaDetail._parseVehicleTypeRatesPublic(body);
    final overnight = AreaDetail._parseOvernightTimesPublic(body);
    final ratePayload = ParkingRateFees.ratePayloadFrom(body);
    var flatHours = defaultFlatBlockHours;
    if (ratePayload != null) {
      final fromApi = flatHoursFromMap(ratePayload);
      if (fromApi > 0) flatHours = fromApi;
    } else {
      final fromApi = flatHoursFromMap(body);
      if (fromApi > 0) flatHours = fromApi;
    }

    if (!standard.hasAny && vehicleRows.isEmpty) return null;

    return BranchRatesSnapshot(
      standard: standard,
      vehicleTypeRates: vehicleRows,
      overnightTimes: overnight,
      flatBlockHours: flatHours,
    );
  }

  /// Per-vehicle hours when set; otherwise area/branch [standardHours].
  static int resolveFlatBlockHours({
    required int standardHours,
    int vehicleTypeHours = 0,
    int fallbackHours = CheckoutPricing.defaultFlatBlockHours,
  }) {
    if (vehicleTypeHours > 0) return vehicleTypeHours;
    if (standardHours > 0) return standardHours;
    return fallbackHours;
  }

  /// Whether [type] has billable rates (ACTIVE vehicle-type row only).
  static bool bodyTypeHasRates({
    required VehicleBodyType type,
    required List<VehicleTypeRateRow> vehicleTypeRates,
  }) {
    final row = rowForBodyType(type, vehicleTypeRates);
    return row != null && row.fees.hasAny;
  }

  /// Fees for [type] from matching vehicle-type row, else null.
  static ParkingRateFees? feesForBodyType({
    required VehicleBodyType type,
    required List<VehicleTypeRateRow> vehicleTypeRates,
  }) {
    final row = rowForBodyType(type, vehicleTypeRates);
    if (row != null && row.fees.hasAny) return row.fees;
    return null;
  }

  static int defaultFlatHoursFromVehicleRows(
    List<VehicleTypeRateRow> rows, {
    int fallbackHours = CheckoutPricing.defaultFlatBlockHours,
  }) {
    final sedan = rowForBodyType(VehicleBodyType.sedan, rows);
    if (sedan != null && sedan.flatRateHours > 0) return sedan.flatRateHours;
    for (final row in rows) {
      if (row.flatRateHours > 0) return row.flatRateHours;
    }
    return fallbackHours;
  }

  static int flatHoursForBodyType({
    required VehicleBodyType type,
    required int standardHours,
    required List<VehicleTypeRateRow> vehicleTypeRates,
  }) {
    final row = rowForBodyType(type, vehicleTypeRates);
    return resolveFlatBlockHours(
      standardHours: standardHours,
      vehicleTypeHours: row?.flatRateHours ?? 0,
    );
  }

  static Set<VehicleBodyType> ratedBodyTypes({
    required List<VehicleTypeRateRow> vehicleTypeRates,
  }) =>
      {
        for (final type in VehicleBodyType.values)
          if (bodyTypeHasRates(type: type, vehicleTypeRates: vehicleTypeRates))
            type,
      };

  /// Offline: enabled types from Drift `rates.vehicle_type` keys.
  static Set<VehicleBodyType> ratedBodyTypesFromDriftKeys(Iterable<String> keys) {
    final keySet = keys.map((k) => k.trim().toLowerCase()).toSet();
    if (keySet.isEmpty) return {};
    if (keySet.length == 1 && keySet.contains('standard')) {
      return VehicleBodyType.values.toSet();
    }
    final enabled = <VehicleBodyType>{};
    for (final type in VehicleBodyType.values) {
      if (keySet.contains(type.rateKey)) {
        enabled.add(type);
      } else if (type == VehicleBodyType.van && keySet.contains('suv')) {
        enabled.add(type);
      }
    }
    return enabled;
  }

  static VehicleTypeRateRow? rowForBodyType(
    VehicleBodyType type,
    List<VehicleTypeRateRow> rows,
  ) {
    final key = type.rateKey;
    for (final row in rows) {
      final slug = row.rateKey;
      if (slug == key) return row;
      if (type == VehicleBodyType.van && slug == 'suv') return row;
      if (type == VehicleBodyType.suv && slug == 'van') return row;
    }
    return null;
  }

  /// Maps API `name` to local `rates.vehicle_type` / [VehicleBodyType.rateKey].
  static String? mapServerVehicleTypeName(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return null;
    if (n.contains('motor')) return 'motorcycle';
    if (n.contains('ev') || n.contains('phev')) return 'ev_phev';
    if (n.contains('luxury')) return 'luxury';
    if (n.contains('sedan') || n.contains('hatchback')) return 'sedan';
    if (n.contains('suv') && n.contains('van')) return 'suv';
    if (n == 'van' || (n.contains('van') && !n.contains('suv'))) return 'van';
    if (n.contains('suv')) return 'suv';
    return null;
  }

  /// Reads `flatRateHours` / `flat_rate_hours` from an API map; `0` if absent.
  static int flatHoursFromMap(Map<String, dynamic> map) {
    for (final key in const ['flatRateHours', 'flat_rate_hours']) {
      final raw = map[key];
      if (raw is int && raw > 0) return raw;
      if (raw is num && raw > 0) return raw.round();
      if (raw != null) {
        final parsed = int.tryParse(raw.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0;
  }
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
    required this.flatBlockHours,
  });

  final String id;
  final String name;
  final String code;
  final ParkingRateFees standard;
  final List<VehicleTypeRateRow> vehicleTypeRates;
  final List<AreaParkingLevel> levels;

  /// Area-level overnight window (`HH:mm`), applied to all cached rate rows.
  final ({String? start, String? end}) overnightTimes;

  /// Flat-rate block hours from area/branch rate payload.
  final int flatBlockHours;

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

    final standard = ParkingRateFees.resolveFromBody(body);
    final vehicleRows = _parseVehicleTypeRates(body);
    final levels = _parseLevels(body);

    if (!standard.hasAny && vehicleRows.isEmpty && levels.isEmpty) {
      return null;
    }

    final ratePayload = ParkingRateFees.ratePayloadFrom(body);
    var flatHours = 3;
    if (ratePayload != null) {
      final fromApi = BranchRatesSnapshot.flatHoursFromMap(ratePayload);
      if (fromApi > 0) flatHours = fromApi;
    } else {
      final fromApi = BranchRatesSnapshot.flatHoursFromMap(body);
      if (fromApi > 0) flatHours = fromApi;
    }

    return AreaDetail(
      id: (body['id'] ?? '').toString(),
      name: (body['name'] ?? '').toString().trim(),
      code: (body['code'] ?? '').toString().trim(),
      standard: standard,
      vehicleTypeRates: vehicleRows,
      levels: levels,
      overnightTimes: _parseOvernightTimes(body),
      flatBlockHours: flatHours,
    );
  }

  static Map<String, dynamic>? _asMapPublic(dynamic data) => _asMap(data);

  static Map<String, dynamic> _unwrapPublic({required Map<String, dynamic> body}) =>
      _unwrap(body: body);

  static List<VehicleTypeRateRow> _parseVehicleTypeRatesPublic(
    Map<String, dynamic> body,
  ) =>
      _parseVehicleTypeRates(body);

  static ({String? start, String? end}) _parseOvernightTimesPublic(
    Map<String, dynamic> body,
  ) =>
      _parseOvernightTimes(body);

  static ({String? start, String? end}) _parseOvernightTimes(
    Map<String, dynamic> body,
  ) {
    final direct = OvernightWindow.parseTimesFromJson(body);
    if (direct.start != null || direct.end != null) return direct;
    final payload = ParkingRateFees.ratePayloadFrom(body);
    if (payload != null) return OvernightWindow.parseTimesFromJson(payload);
    return direct;
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
