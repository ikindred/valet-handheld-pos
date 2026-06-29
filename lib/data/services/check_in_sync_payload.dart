import 'dart:convert';

import '../../core/formatting/plate_number.dart';
import '../../core/formatting/valet_type_format.dart';
import '../local/db/app_database.dart';

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
    'ticket_number': localTicketId.trim(),
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

/// Rebuilds a standard check-in queue payload from a persisted local ticket.
Map<String, dynamic>? standardCheckInSyncQueuePayloadFromTicket(Ticket ticket) {
  final tid = ticket.id.trim();
  final signaturePath = ticket.signaturePng?.trim() ?? '';
  final slotId = ticket.slotId?.trim() ?? '';
  final vrNo = ticket.vrNo?.trim() ?? '';
  if (tid.isEmpty || signaturePath.isEmpty || slotId.isEmpty || vrNo.isEmpty) {
    return null;
  }

  return checkInSyncQueuePayload(
    localTicketId: tid,
    signaturePath: signaturePath,
    slotId: slotId,
    contactNumber: ticket.cellphoneNumber,
    valetType:
        ValetTypeFormat.fromDriverOutMeta(ticket.driverOut) ??
        ValetTypeFormat.standardValet,
    vehicle: <String, dynamic>{
      'plate_number': normalizePlateNumber(ticket.plateNumber),
      'brand': ticket.vehicleBrand.trim(),
      'color': ticket.vehicleColor.trim(),
      'type': ticket.vehicleType.trim().isEmpty
          ? 'sedan'
          : ticket.vehicleType.trim(),
    },
    belongings: _stringListFromJsonColumn(ticket.personalBelongings),
    damages: _damageMapsFromJsonColumn(ticket.damageMarkers),
    vrNo: vrNo,
    customerName: _customerNameFromDriverOutMeta(ticket.driverOut),
    driverIn: ticket.driverIn?.trim().isNotEmpty == true
        ? ticket.driverIn!.trim()
        : null,
  );
}

List<String> _stringListFromJsonColumn(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! List) return const [];
    return decoded.map((e) => e.toString()).toList();
  } catch (_) {
    return const [];
  }
}

List<Map<String, dynamic>> _damageMapsFromJsonColumn(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map)
          Map<String, dynamic>.from(item)
        else if (item is Map<dynamic, dynamic>)
          Map<String, dynamic>.from(item),
    ];
  } catch (_) {
    return const [];
  }
}

String? _customerNameFromDriverOutMeta(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty || !t.startsWith('{')) return null;
  try {
    final body = jsonDecode(t);
    if (body is! Map) return null;
    final name = body['customer_name']?.toString().trim();
    return name != null && name.isNotEmpty ? name : null;
  } catch (_) {
    return null;
  }
}
