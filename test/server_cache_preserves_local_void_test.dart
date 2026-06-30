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
            payload: '{"local_ticket_id":"$ticketId","server_ticket_id":"$serverId"}',
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
}
