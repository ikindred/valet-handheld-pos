import '../local/db/app_database.dart';

/// Outbound JSON for `sync_queue` rows and best-effort ticket REST calls.
Map<String, dynamic> ticketSyncPayload(Ticket t) {
  return <String, dynamic>{
    'id': t.id,
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
