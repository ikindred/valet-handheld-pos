import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/repositories/transactions_repository.dart';
import 'package:valet_handheld_pos/features/check_in/domain/vehicle_body_type.dart';
import 'package:valet_handheld_pos/features/check_in/domain/vehicle_damage.dart';
import 'package:valet_handheld_pos/features/check_in/state/check_in_cubit.dart';

void main() {
  group('TransactionsRepository', () {
    late AppDatabase db;
    late TransactionsRepository repo;
    late int shiftId;
    late int userId;

    setUp(() async {
      db = AppDatabase.memory();
      const now = 1700000000;
      userId = await db.into(db.offlineAccounts).insert(
            OfflineAccountsCompanion.insert(
              serverUserId: 9001,
              email: 't@test.com',
              passwordHash: 'x',
              fullName: 'Test',
              role: 'staff',
              lastOnlineLogin: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final sessionId = await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              userId: userId,
              loginAt: now,
            ),
          );
      shiftId = await db.into(db.shifts).insert(
            ShiftsCompanion.insert(
              sessionId: sessionId,
              userId: userId,
              branch: 'B',
              area: 'A',
              shiftDate: '2026-04-07',
              openedAt: now,
            ),
          );
      repo = TransactionsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insertOfflineCheckIn round-trip and sync_queue payload', () async {
      final sig = Uint8List.fromList([137, 80, 78, 71]);
      final state = CheckInState(
        ticketNumber: 'T-1001',
        customerFullName: 'Jane',
        contactNumber: '555',
        assignedValetDriver: 'Bob',
        specialInstructions: 'Careful',
        dateTimeIn: DateTime.utc(2026, 4, 7, 12),
        valetServiceType: ValetServiceType.selfPark,
        plateNumber: 'ABC-123',
        vehicleModel: 'Model X',
        vehicleBrandMake: 'Tesla',
        vehicleColor: 'Black',
        vehicleYear: '2024',
        vehicleBodyType: VehicleBodyType.suv,
        parkingLevel: 'L1',
        parkingSlot: 'A-02',
        selectedBelongings: const ['laptop'],
        otherBelongings: 'bike rack',
        vehicleDamageEntries: [
          VehicleDamageEntry(
            id: 'd1',
            normalizedX: 0.1,
            normalizedY: 0.2,
            type: DamageType.scratch,
            zoneLabel: 'hood',
          ),
        ],
        hasCustomerSignature: true,
        signaturePng: sig,
        signatureCapturedAt: 1700000100,
      );

      final id = await repo.insertOfflineCheckIn(
        state: state,
        checkinShiftId: shiftId,
        userId: userId,
        branchSnapshot: 'Snap Branch',
        areaSnapshot: 'Snap Area',
        deviceIdSnapshot: 'device-hash',
      );

      final row = await repo.transactionById(id);
      expect(row, isNotNull);
      expect(row!.ticketNumber, 'T-1001');
      expect(row.localUuid, isNotEmpty);
      expect(row.plateNumber, 'ABC-123');
      expect(row.vehicleModel, 'Model X');
      expect(row.belongingsJson, isNotNull);
      expect(jsonDecode(row.belongingsJson!), ['laptop']);
      expect(row.vehicleDamageJson, isNotNull);
      expect(row.signaturePng, base64Encode(sig));
      expect(row.parkingLevel, 'L1');
      expect(row.parkingSlot, 'A-02');
      expect(row.slot, 'L1 · A-02');

      final q = await db.select(db.syncQueue).get();
      expect(q.length, 1);
      expect(q.single.type, 'transaction');
      expect(q.single.entityId, id);
      final payload = jsonDecode(q.single.payload) as Map<String, dynamic>;
      expect(payload['local_uuid'], row.localUuid);
      expect(payload['ticket_number'], 'T-1001');
      expect(payload['signature_png_base64'], isNotNull);
    });

    test('insertOfflineCheckIn without signature leaves payload base64 null',
        () async {
      final state = const CheckInState(
        ticketNumber: 'T-1002',
        plateNumber: 'XYZ',
      );
      final id = await repo.insertOfflineCheckIn(
        state: state,
        checkinShiftId: shiftId,
        userId: userId,
        branchSnapshot: '',
        areaSnapshot: '',
        deviceIdSnapshot: '',
      );
      final row = await repo.transactionById(id);
      expect(row!.signaturePng, isNull);

      final q = await (db.select(db.syncQueue)..limit(1)).getSingle();
      final payload = jsonDecode(q.payload) as Map<String, dynamic>;
      expect(payload['signature_png_base64'], isNull);
    });
  });
}
