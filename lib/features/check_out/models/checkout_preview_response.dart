import 'package:equatable/equatable.dart';

import '../../check_in/domain/vehicle_body_type.dart';
import 'checkout_preview_rates.dart';

/// GET `/transactions/{id}/checkout-preview` payload.
class CheckoutPreviewResponse extends Equatable {
  const CheckoutPreviewResponse({
    required this.transactionId,
    this.customerContact,
    this.belongings = const [],
    this.rates,
    this.valetType,
    required this.releaseSummary,
    required this.ticket,
    this.checkInConditions = const [],
    required this.conditionComparison,
    this.transactionJson,
  });

  final String transactionId;
  final String? customerContact;
  final List<String> belongings;

  /// `standard_valet` | `self_park` from transaction payload.
  final String? valetType;

  /// Server-resolved fees for this transaction; null when absent (offline).
  final CheckoutPreviewRates? rates;

  final ReleaseSummary releaseSummary;
  final CheckoutPreviewTicket ticket;

  /// Damages from `transaction.condition_checkin` (check-in baseline).
  final List<ConditionComparison> checkInConditions;

  /// Rows from `preview.condition_comparison` (check-in vs checkout diff).
  final List<ConditionComparison> conditionComparison;

  /// Raw `transaction` object for check-in date fields (`start_date`, etc.).
  final Map<String, dynamic>? transactionJson;

  /// Parses API body: `{ "transaction": { ... }, "preview": { ... } }`.
  factory CheckoutPreviewResponse.fromJson(Map<String, dynamic> json) {
    final txMap = _mapOrEmpty(json['transaction']);
    final previewMap = json['preview'] is Map
        ? Map<String, dynamic>.from(json['preview'] as Map)
        : <String, dynamic>{};

    final txMeta = _parseTransactionMeta(txMap.isEmpty ? null : txMap);

    final summaryJson = _mergeMaps(
      _releaseSummaryFromTransaction(txMap),
      _mapOrEmpty(
        previewMap['release_summary'] ?? previewMap['releaseSummary'],
      ),
    );
    final ticketJson = _mergeMaps(
      _ticketJsonFromTransaction(txMap),
      _mapOrEmpty(previewMap['ticket']),
    );
    final condRaw =
        previewMap['condition_comparison'] ?? previewMap['conditionComparison'];

    return CheckoutPreviewResponse(
      transactionId: txMeta.id,
      customerContact: txMeta.contact,
      belongings: txMeta.belongings,
      rates: CheckoutPreviewRates.fromJson(json['rates']),
      valetType: txMeta.valetType,
      releaseSummary: ReleaseSummary.fromJson(summaryJson),
      ticket: CheckoutPreviewTicket.fromJson(ticketJson),
      checkInConditions: _parseConditionCheckin(txMap['condition_checkin']),
      conditionComparison: _parseConditionList(condRaw),
      transactionJson: txMap.isEmpty ? null : Map<String, dynamic>.from(txMap),
    );
  }

  factory CheckoutPreviewResponse.fromResponseBody(Map<String, dynamic> root) {
    return CheckoutPreviewResponse.fromJson(root);
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  /// Preview fields win when non-empty; transaction fills gaps.
  static Map<String, dynamic> _mergeMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final out = Map<String, dynamic>.from(base);
    for (final e in override.entries) {
      final v = e.value;
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      if (v is num && v == 0 && !out.containsKey(e.key)) continue;
      out[e.key] = v;
    }
    return out;
  }

  static Map<String, dynamic> _releaseSummaryFromTransaction(
    Map<String, dynamic> tx,
  ) {
    if (tx.isEmpty) return const {};
    final vehicle = _mapOrEmpty(tx['vehicle']);
    final customer = _mapOrEmpty(tx['customer']);
    return {
      'plate': vehicle['plate_number'] ?? vehicle['plate'],
      'customer': customer['name'],
      'duration': _formatDurationMinutes(tx['duration_minutes']),
    };
  }

  static Map<String, dynamic> _ticketJsonFromTransaction(
    Map<String, dynamic> tx,
  ) {
    if (tx.isEmpty) return const {};
    final vehicle = _mapOrEmpty(tx['vehicle']);
    final parking = _mapOrEmpty(tx['parking']);
    final cashier = _mapOrEmpty(tx['cashier']);
    final driverIn = tx['driver_in'];
    final valetIn = driverIn is Map
        ? (driverIn['name'] ?? driverIn['id'])
        : driverIn;
    final driverOut = tx['driver_out'];
    final valetOut = driverOut is Map
        ? (driverOut['name'] ?? driverOut['id'])
        : driverOut;

    return {
      'ticket_number': tx['ticket_number'] ?? tx['ticketNumber'],
      'plate': vehicle['plate_number'] ?? vehicle['plate'],
      'vehicle_make': vehicle['brand'],
      'vehicle_model': vehicle['model'],
      'vehicle_color': vehicle['color'],
      'vehicle_type': vehicle['type'],
      'time_in': tx['time_in'] ?? tx['timeIn'] ?? tx['created_at'],
      'time_out': tx['time_out'] ?? tx['timeOut'],
      'duration': _formatDurationMinutes(tx['duration_minutes']),
      'parking_level': parking['level'],
      'parking_slot': parking['slot'],
      'valet_in': valetIn ?? cashier['name'],
      'valet_out': valetOut,
      'total_amount': tx['amount'],
    };
  }

  static String _formatDurationMinutes(dynamic raw) {
    if (raw is! num) return '';
    final mins = raw.toInt();
    if (mins <= 0) return '';
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static List<ConditionComparison> _parseConditionCheckin(dynamic raw) {
    if (raw is! Map) return const [];
    final m = Map<String, dynamic>.from(raw);
    return _parseDamagesList(m['damages'], isNew: false);
  }

  static List<ConditionComparison> _parseDamagesList(
    dynamic raw, {
    required bool isNew,
  }) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map)
          ConditionComparison(
            zone: e['zone']?.toString().trim() ?? '',
            type: e['type']?.toString().trim() ?? 'dent',
            x: ConditionComparison._dbl(e['x']),
            y: ConditionComparison._dbl(e['y']),
            isNew: isNew,
          ),
    ];
  }

  static _TransactionMeta _parseTransactionMeta(dynamic raw) {
    if (raw is! Map) {
      return const _TransactionMeta('', null, [], null);
    }
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString().trim() ?? '';
    final customer = m['customer'];
    String? contact;
    if (customer is Map) {
      final c = customer['contact_number'] ?? customer['contactNumber'];
      final s = c?.toString().trim() ?? '';
      contact = s.isEmpty ? null : s;
    }
    final bel = m['belongings'];
    final belongings = <String>[];
    if (bel is List) {
      for (final e in bel) {
        final s = e.toString().trim();
        if (s.isNotEmpty) belongings.add(s);
      }
    }
    final valetType = _optionalStr(m['valet_type'] ?? m['valetType']);
    return _TransactionMeta(id, contact, belongings, valetType);
  }

  static String? _optionalStr(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static List<ConditionComparison> _parseConditionList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map)
          ConditionComparison.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  String get vehicleReceiptLine => ticket.vehicleReceiptLine;

  @override
  List<Object?> get props => [
        transactionId,
        customerContact,
        belongings,
        rates,
        valetType,
        releaseSummary,
        ticket,
        checkInConditions,
        conditionComparison,
        transactionJson,
      ];
}

class _TransactionMeta {
  const _TransactionMeta(this.id, this.contact, this.belongings, this.valetType);
  final String id;
  final String? contact;
  final List<String> belongings;
  final String? valetType;
}

class ReleaseSummary extends Equatable {
  const ReleaseSummary({
    required this.plate,
    required this.customer,
    required this.duration,
  });

  final String plate;
  final String customer;
  final String duration;

  factory ReleaseSummary.fromJson(Map<String, dynamic> json) {
    return ReleaseSummary(
      plate: _str(json['plate']),
      customer: _str(json['customer']),
      duration: _str(json['duration']),
    );
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  @override
  List<Object?> get props => [plate, customer, duration];
}

class CheckoutPreviewTicket extends Equatable {
  const CheckoutPreviewTicket({
    required this.ticketNumber,
    required this.plate,
    required this.vehicleMake,
    required this.vehicleColor,
    required this.vehicleType,
    required this.timeIn,
    this.timeOut,
    required this.duration,
    this.parkingLevel,
    this.parkingSlot,
    this.valetIn,
    this.valetOut,
    this.flatRateLabel,
    required this.flatRateAmount,
    this.succeedingTimeLabel,
    required this.succeedingRateAmount,
    required this.totalAmount,
  });

  final String ticketNumber;
  final String plate;
  final String vehicleMake;
  final String vehicleColor;
  final String vehicleType;
  final String timeIn;
  final String? timeOut;
  final String duration;
  final String? parkingLevel;
  final String? parkingSlot;
  final String? valetIn;
  final String? valetOut;
  final String? flatRateLabel;
  final double flatRateAmount;
  final String? succeedingTimeLabel;
  final double succeedingRateAmount;
  final double totalAmount;

  factory CheckoutPreviewTicket.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'];
    final vMap = vehicle is Map ? Map<String, dynamic>.from(vehicle) : null;

    return CheckoutPreviewTicket(
      ticketNumber: _str(json['ticket_number'] ?? json['ticketNumber']),
      plate: _str(json['plate'] ?? json['plate_number'] ?? vMap?['plate_number']),
      vehicleMake: _str(
        json['vehicle_make'] ??
            json['vehicleMake'] ??
            json['brand'] ??
            vMap?['brand'],
      ),
      vehicleColor: _str(
        json['vehicle_color'] ??
            json['vehicleColor'] ??
            json['color'] ??
            vMap?['color'],
      ),
      vehicleType: _str(
        json['vehicle_type'] ??
            json['vehicleType'] ??
            json['type'] ??
            vMap?['type'],
      ),
      timeIn: _str(json['time_in'] ?? json['timeIn'] ?? json['check_in_time']),
      timeOut: _optionalStr(json['time_out'] ?? json['timeOut'] ?? json['check_out_time']),
      duration: _str(json['duration']),
      parkingLevel: _optionalStr(json['parking_level'] ?? json['parkingLevel']),
      parkingSlot: _optionalStr(json['parking_slot'] ?? json['parkingSlot']),
      valetIn: _optionalStr(json['valet_in'] ?? json['valetIn'] ?? json['driver_in']),
      valetOut: _optionalStr(json['valet_out'] ?? json['valetOut'] ?? json['driver_out']),
      flatRateLabel: _optionalStr(json['flat_rate_label'] ?? json['flatRateLabel']),
      flatRateAmount: _dbl(json['flat_rate_amount'] ?? json['flatRateAmount']),
      succeedingTimeLabel: _optionalStr(
        json['succeeding_time_label'] ?? json['succeedingTimeLabel'],
      ),
      succeedingRateAmount: _dbl(
        json['succeeding_rate_amount'] ?? json['succeedingRateAmount'],
      ),
      totalAmount: _dbl(json['total_amount'] ?? json['totalAmount'] ?? json['total']),
    );
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static String? _optionalStr(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Display line for parking chip: `Level 1 · Slot A-12`.
  String get parkingLocationLine {
    final l = parkingLevel?.trim() ?? '';
    final s = parkingSlot?.trim() ?? '';
    final slotLabel = s.isEmpty
        ? ''
        : (s.toLowerCase().startsWith('slot ') ? s : 'Slot $s');
    if (l.isNotEmpty && slotLabel.isNotEmpty) return '$l · $slotLabel';
    if (l.isNotEmpty) return l;
    if (slotLabel.isNotEmpty) return slotLabel;
    return '';
  }

  String get vehicleReceiptLine {
    final typeLabel = vehicleTypeDisplayLabel(vehicleType);
    final parts = <String>[
      vehicleMake.trim(),
      vehicleColor.trim(),
      typeLabel,
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.join(' · ').toUpperCase();
  }

  @override
  List<Object?> get props => [
        ticketNumber,
        plate,
        vehicleMake,
        vehicleColor,
        vehicleType,
        timeIn,
        timeOut,
        duration,
        parkingLevel,
        parkingSlot,
        valetIn,
        valetOut,
        flatRateLabel,
        flatRateAmount,
        succeedingTimeLabel,
        succeedingRateAmount,
        totalAmount,
      ];
}

class ConditionComparison extends Equatable {
  const ConditionComparison({
    required this.zone,
    required this.type,
    required this.x,
    required this.y,
    required this.isNew,
  });

  final String zone;
  final String type;
  final double x;
  final double y;
  final bool isNew;

  factory ConditionComparison.fromJson(Map<String, dynamic> json) {
    return ConditionComparison(
      zone: json['zone']?.toString().trim() ?? '',
      type: json['type']?.toString().trim() ?? 'dent',
      x: _dbl(json['x']),
      y: _dbl(json['y']),
      isNew: json['is_new'] == true || json['isNew'] == true,
    );
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  List<Object?> get props => [zone, type, x, y, isNew];
}
