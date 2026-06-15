import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/remote/area_detail.dart';
import 'package:valet_handheld_pos/features/check_in/domain/vehicle_body_type.dart';

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

  test('AreaDetail parses overnightStartTime and overnightEndTime', () {
    final detail = AreaDetail.fromResponseData({
      'flatRate': 100,
      'overnightStartTime': '01:30',
      'overnightEndTime': '06:00',
    });
    expect(detail, isNotNull);
    expect(detail!.overnightTimes.start, '01:30');
    expect(detail.overnightTimes.end, '06:00');
  });

  test('AreaDetail parses flat_rate_hours from area payload', () {
    final detail = AreaDetail.fromResponseData({
      'flatRate': 120,
      'flat_rate_hours': 8,
      'succeedingRate': 30,
    });
    expect(detail, isNotNull);
    expect(detail!.flatBlockHours, 8);
  });

  test('AreaParkingSlot sortAvailableFirst puts available slots on top', () {
    const slots = [
      AreaParkingSlot(id: '1', label: 'VAL01', status: 'OCCUPIED'),
      AreaParkingSlot(id: '3', label: 'VAL03', status: 'AVAILABLE'),
      AreaParkingSlot(id: '2', label: 'VAL02', status: 'OCCUPIED'),
      AreaParkingSlot(id: '4', label: 'VAL04', status: 'AVAILABLE'),
    ];
    final sorted = AreaParkingSlot.sortAvailableFirst(slots);
    expect(sorted.map((s) => s.label).toList(), [
      'VAL03',
      'VAL04',
      'VAL01',
      'VAL02',
    ]);
  });

  test('resolveFlatBlockHours inherits standard when vehicle hours null', () {
    expect(
      BranchRatesSnapshot.resolveFlatBlockHours(
        standardHours: 3,
        vehicleTypeHours: 0,
      ),
      3,
    );
    expect(
      BranchRatesSnapshot.resolveFlatBlockHours(
        standardHours: 3,
        vehicleTypeHours: 4,
      ),
      4,
    );
  });

  test('BranchRatesApiPayload uses areaOverrides when area matches', () {
    const areaId = 'c3d4e5f6-a7b8-9012-cdef-123456789012';
    final payload = BranchRatesApiPayload.fromResponseData({
      'overnight_start_time': '01:30',
      'overnight_end_time': '06:00',
      'areaOverrides': [
        {
          'id': areaId,
          'name': 'VIP Parking',
          'code': 'AREA-VIP',
          'flatRate': 200,
          'flatRateHours': 2,
          'succeedingRate': 40,
          'overnightFee': 250,
          'lostTicketFee': 250,
          'vehicleTypeRates': [
            {
              'id': 'd4',
              'vehicle_type': 'luxury',
              'name': 'Luxury',
              'flatRate': 300,
              'flatRateHours': 4,
              'succeedingRate': 50,
              'overnightFee': 350,
              'lostTicketFee': 250,
            },
          ],
        },
      ],
      'vehicleTypeRates': [
        {
          'id': 'e5',
          'vehicle_type': 'sedan',
          'name': 'Sedan / Hatchback',
          'flatRate': 150,
          'flatRateHours': 3,
          'succeedingRate': 30,
          'status': 'ACTIVE',
        },
      ],
    });
    expect(payload, isNotNull);

    final vip = payload!.resolveForArea(areaId: areaId);
    expect(vip.usesAreaOverride, isTrue);
    expect(vip.standard.flatRate, 0);
    expect(vip.flatBlockHours, 2);
    expect(vip.vehicleTypeRates, hasLength(1));
    expect(vip.vehicleTypeRates.first.rateKey, 'luxury');
    expect(
      BranchRatesSnapshot.bodyTypeHasRates(
        type: VehicleBodyType.luxury,
        vehicleTypeRates: vip.vehicleTypeRates,
      ),
      isTrue,
    );
    expect(
      BranchRatesSnapshot.bodyTypeHasRates(
        type: VehicleBodyType.sedan,
        vehicleTypeRates: vip.vehicleTypeRates,
      ),
      isFalse,
    );

    final defaultArea = payload.resolveForArea(areaId: 'other-area');
    expect(defaultArea.usesAreaOverride, isFalse);
    expect(defaultArea.standard.flatRate, 0);
    expect(defaultArea.vehicleTypeRates, hasLength(1));
    expect(defaultArea.vehicleTypeRates.first.rateKey, 'sedan');
    expect(
      BranchRatesSnapshot.bodyTypeHasRates(
        type: VehicleBodyType.sedan,
        vehicleTypeRates: defaultArea.vehicleTypeRates,
      ),
      isTrue,
    );
    expect(
      BranchRatesSnapshot.bodyTypeHasRates(
        type: VehicleBodyType.evPhev,
        vehicleTypeRates: defaultArea.vehicleTypeRates,
      ),
      isFalse,
    );
  });

  test('BranchRatesApiPayload resolves VT-only payload without standardRates', () {
    final payload = BranchRatesApiPayload.fromResponseData({
      'overnight_start_time': '01:30',
      'overnight_end_time': '06:00',
      'vehicleTypeRates': [
        {
          'id': 'vt-sedan',
          'vehicle_type': 'sedan',
          'name': 'Sedan / Hatchback',
          'flatRate': 150,
          'flatRateHours': 3,
          'succeedingRate': 30,
          'overnightFee': 100,
          'lostTicketFee': 200,
          'status': 'ACTIVE',
        },
        {
          'id': 'vt-suv',
          'vehicle_type': 'suv',
          'name': 'SUV',
          'flatRate': 180,
          'flatRateHours': 3,
          'succeedingRate': 35,
          'status': 'ACTIVE',
        },
      ],
    });
    expect(payload, isNotNull);

    final snapshot = payload!.resolveForArea(areaId: '');
    expect(snapshot.vehicleTypeRates, hasLength(2));
    expect(snapshot.flatBlockHours, 3);
    expect(
      BranchRatesSnapshot.rowForBodyType(
        VehicleBodyType.suv,
        snapshot.vehicleTypeRates,
      )?.fees.flatRate,
      180,
    );
  });

  test('VehicleTypeRateRow parses vehicle_type slug when name is omitted', () {
    final row = VehicleTypeRateRow.fromJson({
      'id': 'vt-ev',
      'vehicle_type': 'ev_phev',
      'flatRate': 160,
      'succeedingRate': 35,
    });
    expect(row, isNotNull);
    expect(row!.rateKey, 'ev_phev');
    expect(row.name, isNotEmpty);
  });

  test('VehicleTypeRateRow parses per-type flatRateHours', () {
    final row = VehicleTypeRateRow.fromJson({
      'id': 'vt-1',
      'name': 'Sedan',
      'flatRate': 120,
      'flatRateHours': 8,
    });
    expect(row, isNotNull);
    expect(row!.flatRateHours, 8);
  });

  test('BranchRatesSnapshot parses nested rate from branch detail', () {
    final snapshot = BranchRatesSnapshot.fromResponseData({
      'id': 'branch-uuid',
      'name': 'Jazz Mall',
      'rate': {
        'flatRate': 150,
        'flatRateHours': 3,
        'succeedingRate': 30,
        'overnightFee': 200,
        'lostTicketFee': 200,
        'overnightStartTime': '01:30',
        'overnightEndTime': '06:00',
      },
    });
    expect(snapshot, isNotNull);
    expect(snapshot!.standard.flatRate, 150);
    expect(snapshot.standard.overnightFee, 200);
    expect(snapshot.flatBlockHours, 3);
    expect(snapshot.overnightTimes.start, '01:30');
    expect(snapshot.overnightTimes.end, '06:00');
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
