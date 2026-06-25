import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/routing/router_refresh_notifier.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/auth_api.dart';
import 'package:valet_handheld_pos/data/remote/dashboard_api.dart';
import 'package:valet_handheld_pos/data/remote/transactions_api.dart';
import 'package:valet_handheld_pos/data/repositories/auth_repository.dart';
import 'package:valet_handheld_pos/data/services/parking_layout_service.dart';
import 'package:valet_handheld_pos/data/services/rate_fetch_service.dart';
import 'package:valet_handheld_pos/data/services/rate_service.dart';
import 'package:valet_handheld_pos/data/services/shift_service.dart';
import 'package:valet_handheld_pos/data/services/ticket_service.dart';
import 'package:valet_handheld_pos/features/sync/state/sync_cubit.dart';
import 'package:valet_handheld_pos/features/sync/state/sync_state.dart';

void main() {
  late AppDatabase db;
  late SyncCubit syncCubit;
  late TicketService ticketService;

  const shiftId = 'shift-1';
  const ticketId = 'TKT-1';
  const now = '2026-06-08T08:00:00.000Z';

  setUp(() {
    db = AppDatabase.memory();
    final dio = Dio();
    final parkingLayout = ParkingLayoutService(db);
    final rateFetch = RateFetchService(db, dio, parkingLayout);
    final rateService = RateService(db);
    final tickets = TicketService(
      db,
      dio,
      TransactionsApi(dio),
      DashboardApi(dio),
      rateService,
      rateFetch,
      parkingLayout,
    );
    ticketService = tickets;
    final shifts = ShiftService(db, dio, ticketService: tickets);
    final auth = AuthRepository(
      db,
      AuthApi(dio),
      RouterRefreshNotifier(),
      shifts,
      rateService,
      rateFetch,
      DashboardApi(dio),
    );
    syncCubit = SyncCubit(
      database: db,
      dio: dio,
      authRepository: auth,
      ticketService: tickets,
    );
  });

  tearDown(() async {
    await syncCubit.close();
    await db.close();
  });

  Future<void> seedSyncedTicketWithPendingQueue() async {
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
            plateNumber: 'ABC123',
            vehicleBrand: 'Toyota',
            vehicleColor: 'Black',
            vehicleType: 'sedan',
            cellphoneNumber: '09171234567',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: 'completed',
            syncStatus: 'synced',
            createdAt: now,
            checkOutAt: Value(now),
            fee: const Value(50.0),
          ),
        );
    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-orphan-checkout',
            operation: 'checkout/finalize',
            queueTableName: 'tickets',
            recordId: ticketId,
            payload: '{}',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
  }

  test('flush reconciles orphan pending queue when ticket is already synced', () async {
    await seedSyncedTicketWithPendingQueue();

    expect(await syncCubit.pendingCount(), 1);

    await syncCubit.flush();

    expect(await syncCubit.pendingCount(), 0);
    expect(syncCubit.state, isA<SyncComplete>());
    final complete = syncCubit.state as SyncComplete;
    expect(complete.pending, 0);
  });

  test('flush reconciles pending ticket that already has server_ticket_id', () async {
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
            plateNumber: 'ABC12345',
            vehicleBrand: 'Toyota',
            vehicleColor: 'Black',
            vehicleType: 'sedan',
            cellphoneNumber: '09171234567',
            damageMarkers: '[]',
            personalBelongings: '[]',
            checkInAt: now,
            status: 'completed',
            syncStatus: 'pending',
            createdAt: now,
            checkOutAt: Value(now),
            fee: const Value(120.0),
            serverTicketId: const Value('server-uuid-1'),
          ),
        );

    await syncCubit.flush();

    final ticket = await (db.select(db.tickets)
          ..where((t) => t.id.equals(ticketId)))
        .getSingle();
    expect(ticket.syncStatus, 'synced');
  });

  test('flush reconciles failed shift create after login resume', () async {
    await db.into(db.shifts).insert(
          ShiftsCompanion.insert(
            id: shiftId,
            userId: 'user-1',
            branchId: 'branch-1',
            openedAt: now,
            openingFloat: 0,
            status: 'open',
            syncStatus: 'pending',
            createdAt: now,
          ),
        );
    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q-shift-create',
            operation: 'create',
            queueTableName: 'shifts',
            recordId: shiftId,
            payload: '{}',
            syncStatus: 'failed',
            createdAt: now,
          ),
        );

    expect(await syncCubit.failedCount(), 1);

    await syncCubit.flush();

    expect(await syncCubit.failedCount(), 0);
    expect(await syncCubit.pendingCount(), 0);
    final shift = await (db.select(db.shifts)
          ..where((s) => s.id.equals(shiftId)))
        .getSingle();
    expect(shift.syncStatus, 'synced');
  });

  test('reconcileOrphanPendingTickets enqueues express check-in', () async {
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
            status: 'completed',
            syncStatus: 'pending',
            createdAt: now,
            isExpressCashier: const Value(true),
            vrNo: const Value('EP432624'),
          ),
        );

    expect(await ticketService.countOrphanPendingTickets(), 1);
    expect(await syncCubit.pendingCount(), 1);

    final enqueued = await ticketService.reconcileOrphanPendingTickets();
    expect(enqueued, 1);
    expect(await ticketService.countOrphanPendingTickets(), 0);

    final queueRows = await (db.select(db.syncQueue)
          ..where((q) => q.recordId.equals(ticketId)))
        .get();
    expect(queueRows, hasLength(1));
    expect(queueRows.first.operation, 'checkin');
    expect(queueRows.first.syncStatus, 'pending');
  });
}
