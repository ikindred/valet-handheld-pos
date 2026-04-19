import 'dart:convert';

import '../local/db/app_database.dart';

/// PATCH `/api/v1/transactions/{id}` body from a [ticketSyncPayload] map in `sync_queue`.
Map<String, dynamic> transactionCheckInPatchFromSyncPayload(
  Map<String, dynamic> p,
) {
  Object decField(String key, Object fallback) {
    final raw = p[key];
    if (raw == null) return fallback;
    if (raw is String) {
      if (raw.trim().isEmpty) return fallback;
      try {
        return jsonDecode(raw);
      } catch (_) {
        return fallback;
      }
    }
    return raw;
  }

  return <String, dynamic>{
    'driver_in': p['driver_in'],
    'vehicle': <String, dynamic>{
      'plate_number': p['plate_number'] ?? '',
      'brand': p['vehicle_brand'] ?? '',
      'color': p['vehicle_color'] ?? '',
      'type': p['vehicle_type'] ?? '',
      'model': '',
      'year': null,
    },
    'parking': <String, dynamic>{
      'level': null,
      'slot': null,
    },
    'belongings': decField('personal_belongings', const <dynamic>[]),
    'condition': <String, dynamic>{
      'damages': decField('damage_markers', const <dynamic>[]),
      'signature': p['signature_png'],
    },
  };
}

/// Outbound JSON for `sync_queue` rows and best-effort ticket REST calls.
Map<String, dynamic> ticketSyncPayload(Ticket t) {
  return <String, dynamic>{
    'id': t.id,
    if (t.serverTicketId != null && t.serverTicketId!.trim().isNotEmpty)
      'server_ticket_id': t.serverTicketId,
    'shift_id': t.shiftId,
    'user_id': t.userId,
    'branch_id': t.branchId,
    'plate_number': t.plateNumber,
    'vehicle_brand': t.vehicleBrand,
    'vehicle_color': t.vehicleColor,
    'vehicle_type': t.vehicleType,
    'cellphone_number': t.cellphoneNumber,
    'damage_markers': t.damageMarkers,
    'personal_belongings': t.personalBelongings,
    if (t.signaturePng != null) 'signature_png': t.signaturePng,
    'check_in_at': t.checkInAt,
    'check_out_at': t.checkOutAt,
    'fee': t.fee,
    'status': t.status,
    'sync_status': t.syncStatus,
    'created_at': t.createdAt,
    'driver_in': t.driverIn,
    'driver_out': t.driverOut,
  };
}

List<dynamic> _conditionCheckoutFromMarkersJson(String raw) {
  try {
    final v = jsonDecode(raw);
    return v is List ? v : const <dynamic>[];
  } catch (_) {
    return const <dynamic>[];
  }
}

/// PATCH `/api/v1/transactions/{id}` body after checkout (matches live + queued sync).
Map<String, dynamic> checkoutPatchBodyFromTicket(Ticket t) {
  return <String, dynamic>{
    'driver_out': t.driverOut,
    'condition_checkout': _conditionCheckoutFromMarkersJson(t.damageMarkers),
    'status': 'active',
  };
}

double? _optionalDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

String? _optionalTrimmedStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Reconstructs a [Ticket] from [ticketSyncPayload] JSON in `sync_queue` (checkout PATCH only needs subset).
Ticket ticketFromSyncQueuePayload(Map<String, dynamic> p) {
  final dmg = p['damage_markers'];
  final dmgStr =
      dmg is String ? dmg : jsonEncode(dmg is List ? dmg : const <dynamic>[]);
  final bel = p['personal_belongings'];
  final belStr =
      bel is String ? bel : jsonEncode(bel is List ? bel : const <dynamic>[]);

  return Ticket(
    id: p['id']?.toString() ?? '',
    shiftId: p['shift_id']?.toString() ?? '',
    userId: p['user_id']?.toString() ?? '',
    branchId: p['branch_id']?.toString() ?? '',
    plateNumber: p['plate_number']?.toString() ?? '',
    vehicleBrand: p['vehicle_brand']?.toString() ?? '',
    vehicleColor: p['vehicle_color']?.toString() ?? '',
    vehicleType: p['vehicle_type']?.toString() ?? '',
    cellphoneNumber: p['cellphone_number']?.toString() ?? '',
    damageMarkers: dmgStr,
    personalBelongings: belStr,
    signaturePng: p['signature_png'] as String?,
    checkInAt: p['check_in_at']?.toString() ?? '',
    checkOutAt: p['check_out_at']?.toString(),
    fee: _optionalDouble(p['fee']),
    status: p['status']?.toString() ?? '',
    syncStatus: p['sync_status']?.toString() ?? '',
    createdAt: p['created_at']?.toString() ?? '',
    serverTicketId: _optionalTrimmedStr(p['server_ticket_id']),
    driverIn: _optionalTrimmedStr(p['driver_in']),
    driverOut: _optionalTrimmedStr(p['driver_out']),
  );
}
