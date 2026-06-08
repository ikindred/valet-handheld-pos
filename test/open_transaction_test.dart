import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/features/cash/models/open_transaction.dart';

void main() {
  group('OpenTransaction.formatParkedDuration', () {
    test('clamps negative elapsed time to zero', () {
      expect(
        OpenTransaction.formatParkedDuration(
          '2026-06-08T23:35:00.000',
          DateTime(2026, 6, 8, 22, 37),
        ),
        '<1m',
      );
    });

    test('formats hours and minutes since check-in', () {
      expect(
        OpenTransaction.formatParkedDuration(
          '2026-06-08T20:00:00.000',
          DateTime(2026, 6, 8, 22, 15),
        ),
        '2h 15m',
      );
    });

    test('uses local wall check-in consistent with device clock', () {
      expect(
        OpenTransaction.formatParkedDuration(
          '2026-06-08T21:00:00.000',
          DateTime(2026, 6, 8, 23, 30),
        ),
        '2h 30m',
      );
    });
  });

  group('OpenTransaction.fromTicket', () {
    test('parses API UTC check-in as Philippine wall time', () {
      final tx = OpenTransaction.fromTicket(
        _ticket(checkInAt: '2026-06-08T14:35:00.000Z'),
      );
      expect(tx.timeIn.hour, 22);
      expect(tx.timeIn.minute, 35);
    });

    test('uses stored wall check-in without timezone shift', () {
      final tx = OpenTransaction.fromTicket(
        _ticket(checkInAt: '2026-06-08T22:15:00.000'),
      );
      expect(tx.timeIn.hour, 22);
      expect(tx.timeIn.minute, 15);
    });

    test('extracts parking slot from check-in json', () {
      final tx = OpenTransaction.fromTicket(
        _ticket(
          checkInAt: '2026-06-08T22:15:00.000',
          parkingInfo: '{"slot":"VAL02"}',
        ),
      );
      expect(tx.slot, 'VAL02');
    });

    test('maps vehicle type to display label', () {
      final tx = OpenTransaction.fromTicket(
        _ticket(
          checkInAt: '2026-06-08T22:15:00.000',
          vehicleType: 'sedan',
        ),
      );
      expect(tx.vehicleTypeLabel, 'Sedan/Crossover');
    });
  });
}

Ticket _ticket({
  required String checkInAt,
  String? parkingInfo,
  String vehicleType = 'sedan',
}) {
  return Ticket(
    id: 'T-TEST-001',
    shiftId: 'shift-1',
    userId: 'user-1',
    branchId: 'branch-1',
    plateNumber: 'ABC123',
    vehicleBrand: 'Toyota Vios',
    vehicleColor: 'White',
    vehicleType: vehicleType,
    cellphoneNumber: '',
    damageMarkers: '[]',
    personalBelongings: '[]',
    checkInAt: checkInAt,
    status: 'active',
    syncStatus: 'synced',
    createdAt: checkInAt,
    parkingInfo: parkingInfo,
    pendingVoidRequest: false,
  );
}
