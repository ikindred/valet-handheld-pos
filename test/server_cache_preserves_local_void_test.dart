import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/time/philippine_time.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/dashboard_api.dart';
import 'package:valet_handheld_pos/data/remote/transactions_api.dart';
import 'package:valet_handheld_pos/data/services/parking_layout_service.dart';
import 'package:valet_handheld_pos/data/services/rate_fetch_service.dart';
import 'package:valet_handheld_pos/data/services/rate_service.dart';
import 'package:valet_handheld_pos/data/services/ticket_service.dart';

void main() {
  late AppDatabase db;
  late TicketService tickets;

  const shiftId = 'shift-void-1';
  const ticketId = 'TKT-VOID-1';
  const serverId = 'server-uuid-void-1';

  setUp(() {
    db = AppDatabase.memory();
    final dio = Dio();
    final parkingLayout = ParkingLayoutService(db);
    final rateFetch = RateFetchService(db, dio, parkingLayout);
    final rateService = RateService(db);
    tickets = TicketService(
      db,
      dio,
      TransactionsApi(dio),
      DashboardApi(dio),
      rateService,
      rateFetch,
      parkingLayout,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSyncedCheckIn() async {
    final now = PhilippineTime.now().toIso8601String();
    await db.into(db.shifts).insert(
          ShiftsCompanion.insert(
            id: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            openedAt: now,
            openingFloat: 100,
            status: 'open',
            syncStatus: 'synced',
            createdAt: now,
          ),
        );
    await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            id: ticketId,
            shiftId: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            plateNumber: 'ABC1234',
            vehicleBrand: 'Toyota',
            vehicleColor: 'White',
            vehicleType: 'sedan',
            cellphoneNumber: '09171234567',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: 'active',
            syncStatus: 'synced',
            createdAt: now,
            serverTicketId: const Value(serverId),
            parkingInfo: const Value('{"slot":"L01"}'),
          ),
        );
  }

  test(
    'online check-in then offline void: stale checked-in server row is link-only',
    () async {
      await seedSyncedCheckIn();
      final now = PhilippineTime.now().toIso8601String();

      await (db.update(db.tickets)..where((t) => t.id.equals(ticketId))).write(
        const TicketsCompanion(
          status: Value('void'),
          syncStatus: Value('pending'),
          voidReason: Value('Wrong car'),
        ),
      );
      await db.into(db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'q-offline-void',
              operation: 'void',
              queueTableName: 'tickets',
              recordId: ticketId,
              payload:
                  '{"local_ticket_id":"$ticketId","server_ticket_id":"$serverId","reason":"Wrong car"}',
              syncStatus: 'pending',
              createdAt: now,
            ),
          );

      await tickets.cacheTransactionsFromServerJsonList(
        shiftId: shiftId,
        rows: [
          {
            'id': serverId,
            'ticket_number': ticketId,
            'status': 'active',
            'time_in': now,
            'plate_number': 'ZZZ9999',
            'vehicle': {'plate_number': 'ZZZ9999', 'brand': 'Honda'},
            'parking': {'slot': 'L99'},
          },
        ],
      );

      final row = await tickets.ticketById(ticketId);
      expect(row, isNotNull);
      expect(row!.status, 'void');
      expect(row.plateNumber, 'ABC1234');
      expect(row.voidReason, 'Wrong car');
      expect(row.syncStatus, 'pending');
      expect(row.parkingInfo, contains('L01'));

      final voidQueue = await (db.select(db.syncQueue)
            ..where((q) => q.recordId.equals(ticketId)))
          .get();
      expect(voidQueue.any((q) => q.operation == 'void'), isTrue);
    },
  );

  test('cacheTransactionsFromServerJsonList preserves offline void', () async {
    final now = PhilippineTime.now().toIso8601String();

    await db.into(db.shifts).insert(
          ShiftsCompanion.insert(
            id: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            openedAt: now,
            openingFloat: 100,
            status: 'open',
            syncStatus: 'synced',
            createdAt: now,
          ),
        );

    await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            id: ticketId,
            shiftId: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            plateNumber: 'ABC1234',
            vehicleBrand: 'Toyota',
            vehicleColor: 'White',
            vehicleType: 'sedan',
            cellphoneNumber: '09171234567',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: 'void',
            syncStatus: 'pending',
            createdAt: now,
            serverTicketId: const Value(serverId),
            voidReason: const Value('Wrong plate'),
          ),
        );

    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-void-1',
            operation: 'void',
            queueTableName: 'tickets',
            recordId: ticketId,
            payload:
                '{"local_ticket_id":"$ticketId","server_ticket_id":"$serverId"}',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );

    await tickets.cacheTransactionsFromServerJsonList(
      shiftId: shiftId,
      rows: [
        {
          'id': serverId,
          'ticket_number': ticketId,
          'status': 'active',
          'time_in': now,
          'vehicle': {'plate_number': 'ABC1234', 'brand': 'Toyota'},
        },
      ],
    );

    final row = await tickets.ticketById(ticketId);
    expect(row, isNotNull);
    expect(row!.status, 'void');
    expect(row.voidReason, 'Wrong plate');
    expect(row.syncStatus, 'pending');
  });

  test('express offline void survives server completed row', () async {
    final now = PhilippineTime.now().toIso8601String();

    await db.into(db.shifts).insert(
          ShiftsCompanion.insert(
            id: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            openedAt: now,
            openingFloat: 100,
            status: 'open',
            syncStatus: 'synced',
            createdAt: now,
          ),
        );

    await db.into(db.tickets).insert(
          TicketsCompanion.insert(
            id: ticketId,
            shiftId: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            plateNumber: 'DNV3170',
            vehicleBrand: '',
            vehicleColor: '',
            vehicleType: '',
            cellphoneNumber: '',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            checkOutAt: Value(now),
            fee: const Value(120.0),
            status: 'void',
            syncStatus: 'pending',
            createdAt: now,
            serverTicketId: const Value(serverId),
            isExpressCashier: const Value(true),
            vrNo: const Value('EP432624'),
            voidReason: const Value('Duplicate sale'),
          ),
        );

    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-express-void',
            operation: 'void',
            queueTableName: 'tickets',
            recordId: ticketId,
            payload:
                '{"local_ticket_id":"$ticketId","server_ticket_id":"$serverId"}',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );

    await tickets.cacheTransactionsFromServerJsonList(
      shiftId: shiftId,
      expressOnly: true,
      rows: [
        {
          'id': serverId,
          'ticket_number': ticketId,
          'status': 'completed',
          'time_in': now,
          'time_out': now,
          'is_express_cashier': true,
          'vehicle': {'plate_number': 'DNV3170'},
        },
      ],
    );

    final row = await tickets.ticketById(ticketId);
    expect(row, isNotNull);
    expect(row!.status, 'void');
    expect(row.isExpressCashier, isTrue);
    expect(row.voidReason, 'Duplicate sale');
    expect(row.syncStatus, 'pending');
  });
}
