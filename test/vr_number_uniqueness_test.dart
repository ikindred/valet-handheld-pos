import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/formatting/vr_number.dart';
import 'package:valet_handheld_pos/data/local/db/app_database.dart';
import 'package:valet_handheld_pos/data/remote/check_in_exceptions.dart';
import 'package:valet_handheld_pos/data/remote/dashboard_api.dart';
import 'package:valet_handheld_pos/data/remote/transactions_api.dart';
import 'package:valet_handheld_pos/data/services/parking_layout_service.dart';
import 'package:valet_handheld_pos/data/services/rate_fetch_service.dart';
import 'package:valet_handheld_pos/data/services/rate_service.dart';
import 'package:valet_handheld_pos/data/services/ticket_service.dart';

void main() {
  late AppDatabase db;
  late TicketService tickets;

  const shiftId = 'shift-1';
  const now = '2026-06-08T08:00:00.000Z';

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

  Future<void> seedShift() async {
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
  }

  Future<void> insertTicket({
    required String id,
    required String vrNo,
    String status = 'completed',
  }) async {
    await db.into(db.tickets).insert(
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
            syncStatus: 'synced',
            createdAt: now,
            checkOutAt: status == 'completed' ? Value(now) : const Value.absent(),
            vrNo: Value(vrNo),
          ),
        );
  }

  group('normalizeVrNumber', () {
    test('trims and uppercases', () {
      expect(normalizeVrNumber(' vr-001 '), 'VR-001');
    });
  });

  group('TicketService VR uniqueness', () {
    test('ticketByVrNo finds existing ticket case-insensitively', () async {
      await seedShift();
      await insertTicket(id: 'TKT-1', vrNo: 'VR-100');

      final found = await tickets.ticketByVrNo('vr-100');
      expect(found?.id, 'TKT-1');
    });

    test('ticketByVrNo ignores draft tickets', () async {
      await seedShift();
      await insertTicket(id: 'TKT-DRAFT', vrNo: 'VR-200', status: 'draft');

      expect(await tickets.ticketByVrNo('VR-200'), isNull);
    });

    test('ticketByVrNo excludes provided ticket id', () async {
      await seedShift();
      await insertTicket(id: 'TKT-1', vrNo: 'VR-300');

      expect(
        await tickets.ticketByVrNo('VR-300', excludeTicketId: 'TKT-1'),
        isNull,
      );
    });

    test('ensureVrNoAvailable throws when VR is already used', () async {
      await seedShift();
      await insertTicket(id: 'TKT-1', vrNo: 'VR-400');

      expect(
        () => tickets.ensureVrNoAvailable('VR-400'),
        throwsA(isA<VrNumberAlreadyUsedException>()),
      );
    });

    test('persistExpressCheckInLocally rejects duplicate VR', () async {
      await seedShift();
      await insertTicket(id: 'TKT-1', vrNo: 'VR-500');

      expect(
        () => tickets.persistExpressCheckInLocally(
          ticketId: 'TKT-2',
          shiftId: shiftId,
          userId: 'user-1',
          branchId: 'branch-1',
          plateNumber: 'XYZ999',
          amount: 100,
          vrNo: 'vr-500',
        ),
        throwsA(isA<VrNumberAlreadyUsedException>()),
      );
    });
  });
}
