import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/area_detail.dart';
import 'package:valet_handheld_pos/data/services/parking_layout_service.dart';

void main() {
  late AppDatabase db;
  late ParkingLayoutService service;

  setUp(() {
    db = AppDatabase.memory();
    service = ParkingLayoutService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saveLevels and loadLevels round-trip', () async {
    const levels = [
      AreaParkingLevel(
        id: 'lvl-1',
        name: 'VAL-1',
        slotPrefix: 'VAL',
        slots: [
          AreaParkingSlot(id: 's1', label: 'VAL01', status: 'AVAILABLE'),
          AreaParkingSlot(id: 's2', label: 'VAL02', status: 'OCCUPIED'),
        ],
      ),
    ];

    await service.saveLevels(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
      levels: levels,
    );

    final loaded = await service.loadLevels(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
    );

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'VAL-1');
    expect(loaded.first.slots, hasLength(2));
    expect(loaded.first.slots.first.isAvailable, isTrue);
    expect(loaded.first.slots.last.isOccupied, isTrue);
  });

  test('updateSlotStatus marks occupied then available', () async {
    await service.saveLevels(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
      levels: const [
        AreaParkingLevel(
          id: 'lvl-1',
          name: 'VAL-1',
          slotPrefix: 'VAL',
          slots: [
            AreaParkingSlot(id: 's1', label: 'VAL01', status: 'AVAILABLE'),
          ],
        ),
      ],
    );

    await service.markSlotOccupied(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
      slotId: 's1',
    );

    var loaded = await service.loadLevels(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
    );
    expect(loaded.first.slots.first.status, 'OCCUPIED');
    expect(loaded.first.slots.first.isAvailable, isFalse);

    await service.markSlotAvailable(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
      slotId: 's1',
    );

    loaded = await service.loadLevels(
      branchId: 'branch-uuid',
      areaId: 'area-uuid',
    );
    expect(loaded.first.slots.first.status, 'AVAILABLE');
    expect(loaded.first.slots.first.isAvailable, isTrue);
  });
}
