import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../check_in/domain/vehicle_damage.dart';

final _uuid = Uuid();

/// Parses `tickets.damage_markers` (`[{zone,type,x,y},…]`) into diagram entries.
List<VehicleDamageEntry> parseTicketDamageMarkersForCheckout(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const [];
    final out = <VehicleDamageEntry>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final typeStr = (m['type'] ?? 'dent').toString();
      final type = switch (typeStr) {
        'crack' => DamageType.crack,
        'scratch' => DamageType.scratch,
        _ => DamageType.dent,
      };
      out.add(
        VehicleDamageEntry(
          id: _uuid.v4(),
          normalizedX: _readD(m['x']),
          normalizedY: _readD(m['y']),
          type: type,
          zoneLabel: m['zone']?.toString(),
        ),
      );
    }
    return out;
  } catch (_) {
    return const [];
  }
}

double _readD(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

/// Encodes merged damage for `tickets.damage_markers`.
String encodeTicketDamageMarkersForCheckout(List<VehicleDamageEntry> entries) {
  if (entries.isEmpty) return '[]';
  return jsonEncode([
    for (final e in entries)
      {
        'zone': e.zoneLabel ?? '',
        'type': e.type.name,
        'x': e.normalizedX,
        'y': e.normalizedY,
      },
  ]);
}
