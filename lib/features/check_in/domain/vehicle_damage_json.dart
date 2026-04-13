import 'dart:convert';

import 'vehicle_damage.dart';

/// Parses damage saved as JSON list of maps (`normalizedX` / `zoneLabel` / `type`).
List<VehicleDamageEntry> parseVehicleDamageJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const [];
    return [
      for (final e in decoded)
        if (e is Map<String, dynamic>)
          _parseDamageEntry(e)
        else if (e is Map)
          _parseDamageEntry(Map<String, dynamic>.from(e)),
    ];
  } catch (_) {
    return const [];
  }
}

VehicleDamageEntry _parseDamageEntry(Map<String, dynamic> m) {
  final id = (m['id'] ?? '').toString();
  final nx = _readDouble(m['normalizedX']);
  final ny = _readDouble(m['normalizedY']);
  final zone = m['zoneLabel']?.toString();
  final typeStr = (m['type'] ?? 'dent').toString();
  final type = switch (typeStr) {
    'crack' => DamageType.crack,
    'scratch' => DamageType.scratch,
    _ => DamageType.dent,
  };
  return VehicleDamageEntry(
    id: id.isEmpty ? 'legacy' : id,
    normalizedX: nx,
    normalizedY: ny,
    type: type,
    zoneLabel: zone,
  );
}

double _readDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

/// Encodes diagram entries for JSON storage (legacy-compatible shape).
String? encodeVehicleDamageJson(List<VehicleDamageEntry> entries) {
  if (entries.isEmpty) return null;
  return jsonEncode([
    for (final e in entries)
      {
        'id': e.id,
        'normalizedX': e.normalizedX,
        'normalizedY': e.normalizedY,
        'type': e.type.name,
        'zoneLabel': e.zoneLabel,
      },
  ]);
}
