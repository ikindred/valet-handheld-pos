import 'dart:convert';

import '../../../core/api/transaction_payment_summary.dart';
import '../../../data/local/db/app_database.dart';

/// Where the vehicle is parked (from `GET /transactions/:id` or local check-in).
class TicketParkingInfo {
  const TicketParkingInfo({
    this.area,
    this.level,
    this.slot,
  });

  final String? area;
  final String? level;
  final String? slot;

  bool get hasAny =>
      _nonEmpty(area) || _nonEmpty(level) || _nonEmpty(slot);

  String get areaLabel => _nonEmpty(area) ? area!.trim() : '—';
  String get levelLabel => _nonEmpty(level) ? level!.trim() : '—';
  String get slotLabel => _nonEmpty(slot) ? slot!.trim() : '—';

  static bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;

  factory TicketParkingInfo.fromParkingMap(Map<String, dynamic> parking) {
    final area = _readField(parking, 'area', 'zone');
    final level = _readField(parking, 'level');
    final slot = _readField(parking, 'slot');
    final info = TicketParkingInfo(area: area, level: level, slot: slot);
    return info.hasAny ? info : const TicketParkingInfo();
  }

  factory TicketParkingInfo.fromJsonString(String raw) {
    try {
      final body = jsonDecode(raw);
      if (body is Map) {
        return TicketParkingInfo.fromParkingMap(Map<String, dynamic>.from(body));
      }
    } catch (_) {}
    return const TicketParkingInfo();
  }

  /// Check-in meta stored in [Tickets.driverOut] before checkout.
  factory TicketParkingInfo.fromDriverOutMeta(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || !t.startsWith('{')) return const TicketParkingInfo();
    try {
      final body = jsonDecode(t);
      if (body is! Map) return const TicketParkingInfo();
      final map = Map<String, dynamic>.from(body);
      return TicketParkingInfo(
        area: _readField(map, 'parking_area', 'area'),
        level: _readField(map, 'parking_level', 'level'),
        slot: _readField(map, 'parking_slot', 'slot'),
      );
    } catch (_) {
      return const TicketParkingInfo();
    }
  }

  static String? _readField(
    Map<String, dynamic> map,
    String key, [
    String? altKey,
  ]) {
    for (final k in [key, if (altKey != null) altKey]) {
      final v = map[k];
      if (v == null || v is Map && v.isEmpty) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        if (_nonEmpty(area)) 'area': area!.trim(),
        if (_nonEmpty(level)) 'level': level!.trim(),
        if (_nonEmpty(slot)) 'slot': slot!.trim(),
      };

  String? toJsonString() {
    if (!hasAny) return null;
    return jsonEncode(toJson());
  }
}

/// Ticket row plus optional parking for the detail screen.
class TicketDetailSnapshot {
  const TicketDetailSnapshot({
    required this.ticket,
    this.parking,
    this.payment,
  });

  final Ticket ticket;
  final TicketParkingInfo? parking;

  /// Parsed from transaction JSON — fee breakdown + cash tendered / change.
  final TransactionPaymentSummary? payment;

  double? get cashTendered => payment?.cashTendered;
  double? get changePesos => payment?.change;
}
