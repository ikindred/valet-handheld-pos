import 'package:drift/drift.dart';

import '../local/db/app_database.dart';
import '../remote/area_detail.dart';

/// Caches branch area `levels[]` + slot status in Drift for offline use.
class ParkingLayoutService {
  ParkingLayoutService(this._db);

  final AppDatabase _db;

  Future<void> saveLevels({
    required String branchId,
    required String areaId,
    required List<AreaParkingLevel> levels,
  }) async {
    final bid = branchId.trim();
    final aid = areaId.trim();
    if (bid.isEmpty || aid.isEmpty || levels.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final json = AreaParkingLevel.listToJsonString(levels);
    final existing = await (_db.select(_db.parkingAreaLayouts)
          ..where((r) => r.branchId.equals(bid) & r.areaId.equals(aid))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.parkingAreaLayouts)
            ..where(
              (r) => r.branchId.equals(bid) & r.areaId.equals(aid),
            ))
          .write(
        ParkingAreaLayoutsCompanion(
          levelsJson: Value(json),
          updatedAt: Value(now),
        ),
      );
      return;
    }

    await _db.into(_db.parkingAreaLayouts).insert(
          ParkingAreaLayoutsCompanion.insert(
            branchId: bid,
            areaId: aid,
            levelsJson: json,
            updatedAt: now,
          ),
        );
  }

  Future<List<AreaParkingLevel>> loadLevels({
    required String branchId,
    required String areaId,
  }) async {
    final bid = branchId.trim();
    final aid = areaId.trim();
    if (bid.isEmpty || aid.isEmpty) return const [];

    final row = await (_db.select(_db.parkingAreaLayouts)
          ..where((r) => r.branchId.equals(bid) & r.areaId.equals(aid))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return const [];
    return AreaParkingLevel.listFromJsonString(row.levelsJson);
  }

  Future<void> markSlotOccupied({
    required String branchId,
    required String areaId,
    required String slotId,
  }) =>
      updateSlotStatus(
        branchId: branchId,
        areaId: areaId,
        slotId: slotId,
        status: 'OCCUPIED',
      );

  Future<void> markSlotAvailable({
    required String branchId,
    required String areaId,
    required String slotId,
  }) =>
      updateSlotStatus(
        branchId: branchId,
        areaId: areaId,
        slotId: slotId,
        status: 'AVAILABLE',
      );

  Future<void> updateSlotStatus({
    required String branchId,
    required String areaId,
    required String slotId,
    required String status,
  }) async {
    final sid = slotId.trim();
    if (sid.isEmpty) return;

    final levels = await loadLevels(branchId: branchId, areaId: areaId);
    if (levels.isEmpty) return;

    var changed = false;
    final updated = <AreaParkingLevel>[];
    for (final level in levels) {
      final newSlots = <AreaParkingSlot>[];
      for (final slot in level.slots) {
        if (slot.id == sid) {
          newSlots.add(
            AreaParkingSlot(id: slot.id, label: slot.label, status: status),
          );
          changed = true;
        } else {
          newSlots.add(slot);
        }
      }
      updated.add(
        AreaParkingLevel(
          id: level.id,
          name: level.name,
          slotPrefix: level.slotPrefix,
          slots: newSlots,
        ),
      );
    }

    if (changed) {
      await saveLevels(branchId: branchId, areaId: areaId, levels: updated);
    }
  }

  Future<String?> deviceAreaId() async {
    final row = await (_db.select(_db.deviceIdentity)..limit(1)).getSingleOrNull();
    final aid = row?.areaId.trim() ?? '';
    return aid.isEmpty ? null : aid;
  }

  Future<void> markSlotOccupiedForTicket({
    required String branchId,
    required String slotId,
    String? areaId,
  }) async {
    final aid = areaId?.trim().isNotEmpty == true
        ? areaId!.trim()
        : await deviceAreaId();
    if (aid == null) return;
    await markSlotOccupied(branchId: branchId, areaId: aid, slotId: slotId);
  }

  Future<void> markSlotAvailableForTicket({
    required String branchId,
    required String slotId,
    String? areaId,
  }) async {
    final aid = areaId?.trim().isNotEmpty == true
        ? areaId!.trim()
        : await deviceAreaId();
    if (aid == null) return;
    await markSlotAvailable(branchId: branchId, areaId: aid, slotId: slotId);
  }
}
