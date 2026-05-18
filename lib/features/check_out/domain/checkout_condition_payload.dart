import 'dart:convert';

import '../../check_in/domain/vehicle_damage.dart';
import 'ticket_damage_markers.dart';

/// Builds `condition_checkout` array for POST checkout-preview from damage entries.
List<Map<String, dynamic>> conditionCheckoutPayload(
  List<VehicleDamageEntry> entries,
) {
  final raw = encodeTicketDamageMarkersForCheckout(entries);
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return [
    for (final e in decoded)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}
