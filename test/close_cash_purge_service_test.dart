import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/services/close_cash_purge_service.dart';

void main() {
  late AppDatabase db;
  late CloseCashPurgeService service;

  const shiftA = 'shift-a';
  const shiftB = 'shift-b';
  const now = '2026-06-05T08:00:00.000Z';

  Future<void> insertShift({
    required String id,
    required String status,
    required String syncStatus,
  }) {
    return db.into(db.shifts).insert(
          ShiftsCompanion.insert(
            id: id,
            userId: 'user-1',
            branchId: 'branch-1',
            openedAt: now,
            openingFloat: 100,
            status: status,
            syncStatus: syncStatus,
            createdAt: now,
            closedAt: status == 'closed' ? Value(now) : const Value.absent(),
            closingCash:
                status == 'closed' ? const Value(500.0) : const Value.absent(),
          ),
        );
  }

  Future<void> insertTicket({
    required String id,
    required String shiftId,
    required String status,
    required String syncStatus,
  }) {
    return db.into(db.tickets).insert(
          TicketsCompanion.insert(
            id: id,
            shiftId: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            plateNumber: 'ABC123',
            vehicleBrand: 'Toyota',
            vehicleColor: 'Black',
            vehicleType: 'sedan',
            cellphoneNumber: '09171234567',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: status,
            syncStatus: syncStatus,
            createdAt: now,
            checkOutAt: status == 'active'
                ? const Value.absent()
                : Value(now),
            fee: status == 'active' ? const Value.absent() : const Value(50.0),
          ),
        );
  }

  setUp(() {
    db = AppDatabase.memory();
    service = CloseCashPurgeService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('deletes synced completed tickets and keeps active check-ins', () async {
    await insertShift(id: shiftA, status: 'closed', syncStatus: 'synced');
    await insertShift(id: shiftB, status: 'open', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-1',
      shiftId: shiftA,
      status: 'completed',
      syncStatus: 'synced',
    );
    await insertTicket(
      id: 'TKT-2',
      shiftId: shiftB,
      status: 'active',
      syncStatus: 'synced',
    );
    await insertTicket(
      id: 'TKT-3',
      shiftId: shiftA,
      status: 'completed',
      syncStatus: 'pending',
    );

    final result = await service.purgeAfterCloseCash(closedShiftId: shiftA);

    expect(result.deletedTickets, 1);
    final tickets = await db.select(db.tickets).get();
    expect(tickets, hasLength(2));
    expect(tickets.map((t) => t.id), containsAll(['TKT-2', 'TKT-3']));
  });

  test('deletes drafts and void/lost synced tickets', () async {
    await insertShift(id: shiftA, status: 'closed', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-draft',
      shiftId: shiftA,
      status: 'draft',
      syncStatus: 'pending',
    );
    await insertTicket(
      id: 'TKT-void',
      shiftId: shiftA,
      status: 'void',
      syncStatus: 'synced',
    );
    await insertTicket(
      id: 'TKT-lost',
      shiftId: shiftA,
      status: 'lost',
      syncStatus: 'synced',
    );

    await service.purgeAfterCloseCash();

    expect(await db.select(db.tickets).get(), isEmpty);
  });

  test('keeps shift referenced by active ticket', () async {
    await insertShift(id: shiftA, status: 'closed', syncStatus: 'synced');
    await insertShift(id: shiftB, status: 'closed', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-active',
      shiftId: shiftA,
      status: 'active',
      syncStatus: 'synced',
    );

    final result = await service.purgeAfterCloseCash();

    expect(result.deletedShifts, 1);
    final shifts = await db.select(db.shifts).get();
    expect(shifts, hasLength(1));
    expect(shifts.single.id, shiftA);
  });

  test('preserves device identity, users, rates, branch config, layouts', () async {
    await insertShift(id: shiftA, status: 'closed', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-1',
      shiftId: shiftA,
      status: 'completed',
      syncStatus: 'synced',
    );

    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.into(db.deviceIdentity).insert(
          DeviceIdentityCompanion.insert(
            deviceLabel: 'POS-1',
            serverDeviceId: 'dev-server-1',
            androidIdHash: 'hash',
            branch: 'Branch',
            area: 'Area',
          ),
        );
    await db.into(db.offlineAccounts).insert(
          OfflineAccountsCompanion.insert(
            serverUserId: 'srv-user-1',
            email: 'cashier@test.com',
            passwordHash: 'hash',
            fullName: 'Cashier',
            role: 'cashier',
            lastOnlineLogin: ts,
            createdAt: ts,
            updatedAt: ts,
          ),
        );
    await db.into(db.rates).insert(
          RatesCompanion.insert(
            id: 'rate-1',
            branchId: 'branch-1',
            vehicleType: 'sedan',
            flatRateHours: 3,
            flatRateFee: 50,
            succeedingHourFee: 20,
            overnightFee: 100,
            lostTicketFee: 200,
            syncStatus: 'synced',
            updatedAt: now,
          ),
        );
    await db.into(db.branchConfigs).insert(
          BranchConfigsCompanion.insert(
            id: 'cfg-1',
            branchId: 'branch-1',
            configKey: 'mall_open',
            configValue: '10:00',
            syncStatus: 'synced',
            updatedAt: now,
          ),
        );
    await db.into(db.parkingAreaLayouts).insert(
          ParkingAreaLayoutsCompanion.insert(
            branchId: 'branch-1',
            areaId: 'area-1',
            levelsJson: '[]',
            updatedAt: now,
          ),
        );

    await service.purgeAfterCloseCash();

    expect(await db.select(db.deviceIdentity).get(), isNotEmpty);
    expect(await db.select(db.offlineAccounts).get(), isNotEmpty);
    expect(await db.select(db.rates).get(), isNotEmpty);
    expect(await db.select(db.branchConfigs).get(), isNotEmpty);
    expect(await db.select(db.parkingAreaLayouts).get(), isNotEmpty);
  });

  test('cleans synced and orphan sync_queue rows', () async {
    await insertShift(id: shiftA, status: 'closed', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-1',
      shiftId: shiftA,
      status: 'completed',
      syncStatus: 'synced',
    );
    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-synced',
            operation: 'update',
            queueTableName: 'tickets',
            recordId: 'TKT-1',
            payload: '{}',
            syncStatus: 'synced',
            createdAt: now,
          ),
        );
    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-orphan',
            operation: 'update',
            queueTableName: 'tickets',
            recordId: 'TKT-missing',
            payload: '{}',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );

    final result = await service.purgeAfterCloseCash();

    expect(result.deletedQueueRows, greaterThanOrEqualTo(2));
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });

  test('purgeEndedSessions removes inactive sessions only', () async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final acctId = await db.into(db.offlineAccounts).insert(
          OfflineAccountsCompanion.insert(
            serverUserId: 'srv-user-1',
            email: 'cashier@test.com',
            passwordHash: 'hash',
            fullName: 'Cashier',
            role: 'cashier',
            lastOnlineLogin: ts,
            createdAt: ts,
            updatedAt: ts,
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            userId: acctId,
            loginAt: ts,
            isActive: const Value(false),
            logoutAt: Value(ts),
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            userId: acctId,
            loginAt: ts,
            authToken: const Value('token'),
            isActive: const Value(true),
          ),
        );

    final deleted = await service.purgeEndedSessions();

    expect(deleted, 1);
    final sessions = await db.select(db.sessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.isActive, isTrue);
  });

  test('countPendingSyncTicketsForUser excludes drafts', () async {
    await insertShift(id: shiftA, status: 'open', syncStatus: 'synced');
    await insertTicket(
      id: 'TKT-draft',
      shiftId: shiftA,
      status: 'draft',
      syncStatus: 'pending',
    );
    await insertTicket(
      id: 'TKT-active',
      shiftId: shiftA,
      status: 'active',
      syncStatus: 'pending',
    );

    final count = await service.countPendingSyncTicketsForUser('user-1');

    expect(count, 1);
  });
}
