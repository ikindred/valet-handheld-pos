import 'dart:convert';
import 'dart:io';

import '../../core/formatting/plate_number.dart';

/// Reads a local signature file as base64 for batch JSON check-in.
Future<String> signatureFileToBase64(String path) async {
  final file = File(path.trim());
  if (!await file.exists()) {
    throw StateError('Signature file missing: $path');
  }
  return base64Encode(await file.readAsBytes());
}

/// Normal cashier item for `check_ins[]`.
Map<String, dynamic> normalCheckInApiItem({
  required String ticketNumber,
  required String slotId,
  required String contactNumber,
  required String valetType,
  required Map<String, dynamic> vehicle,
  required List<String> belongings,
  required List<Map<String, dynamic>> damages,
  required String vrNo,
  required String signatureBase64,
  String signatureContentType = 'image/png',
  String? customerName,
  String? driverIn,
  String? driverOut,
  String? notes,
  bool voidRequested = false,
  String? voidReason,
}) {
  final item = <String, dynamic>{
    'ticket_number': ticketNumber.trim(),
    'slot_id': slotId.trim(),
    'contact_number': contactNumber,
    'valet_type': valetType,
    'vehicle': vehicle,
    'belongings': belongings,
    'damages': damages,
    'vr_no': vrNo.trim(),
    'signature_base64': signatureBase64,
    'signature_content_type': signatureContentType,
  };
  final name = customerName?.trim();
  if (name != null && name.isNotEmpty) item['customer_name'] = name;
  final driver = driverIn?.trim();
  if (driver != null && driver.isNotEmpty) item['driver_in'] = driver;
  final driverOutName = driverOut?.trim();
  if (driverOutName != null && driverOutName.isNotEmpty) {
    item['driver_out'] = driverOutName;
  }
  final note = notes?.trim();
  if (note != null && note.isNotEmpty) item['notes'] = note;
  if (voidRequested) {
    item['void_requested'] = true;
    final reason = voidReason?.trim();
    if (reason != null && reason.isNotEmpty) item['void_reason'] = reason;
  }
  return item;
}

/// Express cashier item for `check_ins[]`.
Map<String, dynamic> expressCheckInApiItem({
  required String ticketNumber,
  required String plateNumber,
  required double amount,
  required String vrNo,
  String? driverIn,
  String? driverOut,
}) {
  final plate = normalizePlateNumber(plateNumber).toUpperCase();
  final item = <String, dynamic>{
    'ticket_number': ticketNumber.trim(),
    'vehicle': <String, dynamic>{'plate_number': plate},
    'amount': amount,
    'vr_no': vrNo.trim(),
  };
  final driver = driverIn?.trim();
  if (driver != null && driver.isNotEmpty) item['driver_in'] = driver;
  final driverOutName = driverOut?.trim();
  if (driverOutName != null && driverOutName.isNotEmpty) {
    item['driver_out'] = driverOutName;
  }
  return item;
}

List<String> batchStringListField(dynamic raw) {
  if (raw is List) {
    return [for (final e in raw) e.toString()];
  }
  return const [];
}

List<Map<String, dynamic>> batchDamageListField(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

Map<String, dynamic> batchMapField(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

/// Builds a batch API item from a queued `sync_queue` check-in payload.
Future<Map<String, dynamic>> checkInQueuePayloadToApiItem(
  Map<String, dynamic> body, {
  required bool voidRequested,
  String? voidReason,
}) async {
  if (body['is_express_cashier'] == true) {
    final localId =
        body['local_ticket_id']?.toString().trim() ??
        body['ticket_number']?.toString().trim() ??
        '';
    final plate = body['plate_number']?.toString().trim() ?? '';
    final amountRaw = body['amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse('$amountRaw') ?? 0;
    final vrNo = body['vr_no']?.toString().trim() ?? '';
    if (localId.isEmpty) throw StateError('Queued express check-in missing id');
    if (plate.isEmpty) {
      throw StateError('Queued express check-in missing plate_number');
    }
    if (amount <= 0) throw StateError('Queued express check-in missing amount');
    if (vrNo.isEmpty) throw StateError('Queued express check-in missing vr_no');
    return expressCheckInApiItem(
      ticketNumber:
          body['ticket_number']?.toString().trim().isNotEmpty == true
              ? body['ticket_number'].toString().trim()
              : localId,
      plateNumber: plate,
      amount: amount,
      vrNo: vrNo,
      driverIn: body['driver_in']?.toString(),
      driverOut: body['driver_out']?.toString(),
    );
  }

  final localId =
      body['local_ticket_id']?.toString().trim() ??
      body['ticket_number']?.toString().trim() ??
      '';
  final path = body['signature_path']?.toString().trim() ?? '';
  if (path.isEmpty) throw StateError('Queued check-in missing signature_path');
  final signatureBase64 = await signatureFileToBase64(path);

  final vehicleRaw = batchMapField(body['vehicle']);
  vehicleRaw.remove('vr_no');
  vehicleRaw.remove('vrNo');
  if (vehicleRaw['plate_number'] != null) {
    vehicleRaw['plate_number'] =
        normalizePlateNumber(vehicleRaw['plate_number'].toString())
            .toUpperCase();
  }

  final slotId = body['slot_id']?.toString().trim() ?? '';
  if (slotId.isEmpty) throw StateError('Queued check-in missing slot_id');

  final vrNo = body['vr_no']?.toString().trim() ?? '';
  if (vrNo.isEmpty) throw StateError('Queued check-in missing vr_no');

  return normalCheckInApiItem(
    ticketNumber: localId,
    slotId: slotId,
    contactNumber: body['contact_number']?.toString() ?? '',
    valetType: body['valet_type']?.toString() ?? 'standard_valet',
    vehicle: vehicleRaw,
    belongings: batchStringListField(body['belongings']),
    damages: batchDamageListField(body['damages']),
    vrNo: vrNo,
    signatureBase64: signatureBase64,
    customerName: body['customer_name']?.toString(),
    driverIn: body['driver_in']?.toString(),
    driverOut: body['driver_out']?.toString(),
    notes: body['notes']?.toString(),
    voidRequested: voidRequested,
    voidReason: voidReason,
  );
}
