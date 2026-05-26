import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/remote/area_detail.dart';

void main() {
  test('AreaDetail parses standard and vehicleTypeRates', () {
    final detail = AreaDetail.fromResponseData({
      'id': 'area-uuid',
      'name': 'Area A',
      'code': 'AREA-A',
      'flatRate': 150,
      'succeedingRate': 50,
      'overnightFee': 100,
      'lostTicketFee': 500,
      'vehicleTypeRates': [
        {
          'id': 'vt-1',
          'name': 'Sedan / Hatchback',
          'flatRate': 150,
          'succeedingRate': 50,
          'overnightFee': 100,
          'lostTicketFee': 500,
        },
      ],
    });

    expect(detail, isNotNull);
    expect(detail!.standard.flatRate, 150);
    expect(detail.standard.lostTicketFee, 500);
    expect(detail.vehicleTypeRates, hasLength(1));
    expect(detail.vehicleTypeRates.first.name, 'Sedan / Hatchback');
    expect(detail.vehicleTypeRates.first.fees.succeedingRate, 50);
  });

  test('AreaDetail parses overnight_start and overnight_end', () {
    final detail = AreaDetail.fromResponseData({
      'flatRate': 100,
      'overnight_start': '01:30',
      'overnight_end': '05:30',
    });
    expect(detail, isNotNull);
    expect(detail!.overnightTimes.start, '01:30');
    expect(detail.overnightTimes.end, '05:30');
  });

  test('AreaDetail parses levels and slot availability', () {
    final detail = AreaDetail.fromResponseData({
      'flatRate': 100,
      'levels': [
        {
          'id': 'lvl-1',
          'name': 'Level 1',
          'slotPrefix': 'A',
          'slots': [
            {'id': 's1', 'label': 'A-01', 'status': 'AVAILABLE'},
            {'id': 's2', 'label': 'A-02', 'status': 'OCCUPIED'},
          ],
        },
        {
          'id': 'lvl-2',
          'name': 'Level 2',
          'slotPrefix': 'B',
          'slots': [
            {'id': 's3', 'label': 'B-01', 'status': 'AVAILABLE'},
          ],
        },
      ],
    });

    expect(detail, isNotNull);
    expect(detail!.levels, hasLength(2));
    expect(detail.levels.first.availableCount, 1);
    expect(detail.levels.first.occupiedCount, 1);
    expect(detail.slotCounts.total, 3);
    expect(detail.slotCounts.available, 2);
    expect(detail.slotCounts.occupied, 1);
    expect(detail.levels.first.availableSlots.first.label, 'A-01');
  });
}
