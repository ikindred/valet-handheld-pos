import '../models/checkout_preview_response.dart';

/// Builds the `preview` object for `POST /transactions/{id}/check-out`.
Map<String, dynamic> buildCheckOutPreviewPayload(
  CheckoutPreviewResponse preview, {
  String? timeOut,
}) {
  final rs = preview.releaseSummary;
  final t = preview.ticket;
  final ticketTimeOut = (timeOut ?? t.timeOut ?? '').trim();

  return <String, dynamic>{
    'release_summary': <String, dynamic>{
      'plate': rs.plate,
      'customer': rs.customer,
      'duration': rs.duration,
    },
    'ticket': <String, dynamic>{
      'ticket_number': t.ticketNumber,
      'plate': t.plate,
      'vehicle_make': t.vehicleMake,
      'vehicle_model': t.vehicleModel,
      'vehicle_color': t.vehicleColor,
      'vehicle_type': t.vehicleType,
      'time_in': t.timeIn,
      'time_out': ticketTimeOut,
      'duration': t.duration,
      if (t.parkingSlot != null && t.parkingSlot!.trim().isNotEmpty)
        'parking_slot': t.parkingSlot!.trim(),
      if (t.valetIn != null && t.valetIn!.trim().isNotEmpty)
        'valet_in': t.valetIn!.trim(),
      if (t.valetOut != null && t.valetOut!.trim().isNotEmpty)
        'valet_out': t.valetOut!.trim(),
    },
    'condition_comparison': [
      for (final c in preview.conditionComparison)
        <String, dynamic>{
          'zone': c.zone,
          'type': c.type,
          'x': c.x,
          'y': c.y,
          'is_new': c.isNew,
        },
    ],
  };
}
