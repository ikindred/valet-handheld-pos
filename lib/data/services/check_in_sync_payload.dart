/// JSON payload for `sync_queue` rows (`tickets` / `checkin`).
Map<String, dynamic> checkInSyncQueuePayload({
  required String localTicketId,
  required String signaturePath,
  required String slotId,
  required String contactNumber,
  required String valetType,
  required Map<String, dynamic> vehicle,
  required List<String> belongings,
  required List<Map<String, dynamic>> damages,
  required String vrNo,
  String? customerName,
  String? driverIn,
  String? notes,
}) {
  return <String, dynamic>{
    'local_ticket_id': localTicketId,
    'signature_path': signaturePath,
    'slot_id': slotId.trim(),
    'contact_number': contactNumber,
    'valet_type': valetType,
    'vehicle': vehicle,
    'belongings': belongings,
    'damages': damages,
    'vr_no': vrNo.trim(),
    if (customerName != null && customerName.trim().isNotEmpty)
      'customer_name': customerName.trim(),
    if (driverIn != null && driverIn.trim().isNotEmpty) 'driver_in': driverIn.trim(),
    if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
  };
}

/// Minimal payload for express cashier manual ticketing check-in.
Map<String, dynamic> expressCheckInSyncQueuePayload({
  required String localTicketId,
  required String ticketNumber,
  required String plateNumber,
  required double amount,
  required String vrNo,
  String? driverIn,
  String? driverOut,
}) {
  return <String, dynamic>{
    'local_ticket_id': localTicketId,
    'ticket_number': ticketNumber.trim(),
    'is_express_cashier': true,
    'plate_number': plateNumber,
    'amount': amount,
    'vr_no': vrNo.trim(),
    if (driverIn != null && driverIn.trim().isNotEmpty) 'driver_in': driverIn.trim(),
    if (driverOut != null && driverOut.trim().isNotEmpty)
      'driver_out': driverOut.trim(),
  };
}
