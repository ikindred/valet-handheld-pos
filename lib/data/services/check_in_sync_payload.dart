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
    if (customerName != null && customerName.trim().isNotEmpty)
      'customer_name': customerName.trim(),
    if (driverIn != null && driverIn.trim().isNotEmpty) 'driver_in': driverIn.trim(),
    if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
  };
}
