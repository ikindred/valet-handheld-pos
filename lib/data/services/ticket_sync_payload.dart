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
  };
}
