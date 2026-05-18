import 'package:intl/intl.dart';

import '../../../core/time/philippine_time.dart';
import '../models/checkout_preview_response.dart';
import '../../check_in/domain/vehicle_damage.dart';

/// Formats preview ISO timestamps for checkout UI.
String formatPreviewDateTime(String? iso) {
  final s = iso?.trim() ?? '';
  if (s.isEmpty) return '—';
  final dt = PhilippineTime.fromApiIso(s);
  return '${DateFormat('MMM d, y').format(dt)} · ${DateFormat('h:mm a').format(dt)}';
}

String formatPreviewTime(String? iso) {
  final s = iso?.trim() ?? '';
  if (s.isEmpty) return '—';
  return DateFormat('h:mm a').format(PhilippineTime.fromApiIso(s));
}

/// e.g. `Level 1 · Slot A-12` from API `parking.level` + `parking.slot`.
String formatParkingLocation({String? level, String? slot}) {
  final l = level?.trim() ?? '';
  final s = slot?.trim() ?? '';
  final slotLabel = s.isEmpty
      ? ''
      : (s.toLowerCase().startsWith('slot ') ? s : 'Slot $s');
  if (l.isNotEmpty && slotLabel.isNotEmpty) return '$l · $slotLabel';
  if (l.isNotEmpty) return l;
  if (slotLabel.isNotEmpty) return slotLabel;
  return '';
}

String formatPreviewDate(String? iso) {
  final s = iso?.trim() ?? '';
  if (s.isEmpty) return '—';
  return DateFormat('MMMM d, y').format(PhilippineTime.fromApiIso(s));
}

/// Maps API condition comparison rows to diagram entries.
List<VehicleDamageEntry> damageEntriesFromComparison(
  List<ConditionComparison> rows,
) {
  return [
    for (var i = 0; i < rows.length; i++)
      _entryFromComparison(rows[i], i),
  ];
}

VehicleDamageEntry _entryFromComparison(ConditionComparison c, int index) {
  final type = switch (c.type.toLowerCase()) {
    'crack' => DamageType.crack,
    'scratch' => DamageType.scratch,
    _ => DamageType.dent,
  };
  return VehicleDamageEntry(
    id: 'cmp-$index-${c.zone}-${c.x}-${c.y}',
    normalizedX: c.x,
    normalizedY: c.y,
    type: type,
    zoneLabel: c.zone,
  );
}

Set<String> newComparisonEntryIds(List<ConditionComparison> rows) {
  final entries = damageEntriesFromComparison(rows);
  return {
    for (var i = 0; i < rows.length; i++)
      if (rows[i].isNew) entries[i].id,
  };
}
