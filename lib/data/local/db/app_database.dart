import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Device registration row (local). [branch] / [area] mirror successful device/register.
class DeviceInfo extends Table {
  @override
  String get tableName => 'device_info';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get deviceId => text().unique()();

  TextColumn get branch => text().withDefault(const Constant(''))();

  TextColumn get area => text().withDefault(const Constant(''))();

  /// Unix timestamp (seconds).
  IntColumn get registeredAt => integer()();
}

/// Server-managed POS terminal identity (authoritative). Legacy [DeviceInfo] unchanged.
class DeviceIdentity extends Table {
  @override
  String get tableName => 'device_identity';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get deviceLabel => text()();

  TextColumn get serverDeviceId => text().unique()();

  /// SHA-256 of raw ANDROID_ID (never store raw id).
  TextColumn get androidIdHash => text()();

  TextColumn get branch => text()();

  TextColumn get area => text()();

  /// Server branch id (UUID/slug) from claim / device list.
  TextColumn get branchId => text().withDefault(const Constant(''))();

  /// Server area id (UUID/slug) from claim / device list.
  TextColumn get areaId => text().withDefault(const Constant(''))();

  /// Hardware / portal serial when provided by API.
  TextColumn get serialNumber => text().withDefault(const Constant(''))();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get claimedAt => dateTime().nullable()();
}

/// Offline credentials (email + bcrypt hash, plus API metadata).
class OfflineAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Server user id (UUID string from API).
  TextColumn get serverUserId => text().unique()();

  TextColumn get email => text().unique()();

  TextColumn get passwordHash => text()();

  TextColumn get fullName => text()();

  TextColumn get role => text()();

  /// Unix timestamp (seconds).
  IntColumn get lastOnlineLogin => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// JSON array from login `user.shiftSchedule` (empty when unset).
  TextColumn get shiftScheduleJson =>
      text().withDefault(const Constant(''))();
}

/// Auth token and session flags (`is_active`). Device id + offline mode only in prefs.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local [OfflineAccounts.id] (not server id).
  IntColumn get userId => integer().references(OfflineAccounts, #id)();

  TextColumn get authToken => text().nullable()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(false))();

  IntColumn get loginAt => integer()();

  IntColumn get lastVerifiedAt => integer().nullable()();

  IntColumn get logoutAt => integer().nullable()();

  BoolColumn get isOfflineSession =>
      boolean().withDefault(const Constant(false))();
}

/// Cash shift (UUID id, ISO8601 timestamps, Asia/Manila as app policy).
class Shifts extends Table {
  @override
  String get tableName => 'shifts';

  TextColumn get id => text()();

  /// [OfflineAccounts.serverUserId] as string.
  TextColumn get userId => text()();

  TextColumn get branchId => text()();

  /// ISO8601, Asia/Manila.
  TextColumn get openedAt => text()();

  /// ISO8601, nullable when shift is open.
  TextColumn get closedAt => text().nullable()();

  RealColumn get openingFloat => real()();

  RealColumn get closingCash => real().nullable()();

  /// `open` | `closed`
  TextColumn get status => text()();

  /// `pending` | `synced`
  TextColumn get syncStatus => text()();

  /// ISO8601 row creation time.
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Parking tickets (`TKT-XXXX` per shift, mobile-generated).
class Tickets extends Table {
  @override
  String get tableName => 'tickets';

  TextColumn get id => text()();

  TextColumn get shiftId => text().references(Shifts, #id)();

  TextColumn get userId => text()();

  TextColumn get branchId => text()();

  TextColumn get plateNumber => text()();

  TextColumn get vehicleBrand => text()();

  TextColumn get vehicleColor => text()();

  TextColumn get vehicleType => text()();

  TextColumn get cellphoneNumber => text()();

  /// JSON: [{zone, type, x, y}, ...]
  TextColumn get damageMarkers => text()();

  /// JSON: ["iPad", ...]
  TextColumn get personalBelongings => text()();

  /// Base64-encoded PNG, nullable until signed.
  TextColumn get signaturePng => text().nullable()();

  TextColumn get checkInAt => text()();

  TextColumn get checkOutAt => text().nullable()();

  RealColumn get fee => real().nullable()();

  /// `active` | `completed` | `lost` | `draft` (reserved id before check-in completes)
  TextColumn get status => text()();

  /// `pending` | `synced`
  TextColumn get syncStatus => text()();

  TextColumn get createdAt => text()();

  /// Server `transactions.id` (UUID) after draft POST; local [id] stays `TKT-…`.
  TextColumn get serverTicketId => text().named('server_ticket_id').nullable()();

  /// Valet attendant who received the vehicle at check-in.
  TextColumn get driverIn => text().nullable()();

  /// Valet attendant who returned the vehicle at check-out.
  TextColumn get driverOut => text().nullable()();

  /// JSON: `{"area","level","slot"}` from server or check-in.
  TextColumn get parkingInfo => text().nullable()();

  /// JSON snapshot of checkout payment lines (fee breakdown + cash tendered).
  TextColumn get paymentSummaryJson =>
      text().named('payment_summary_json').nullable()();

  /// Parking slot UUID from area detail (`levels[].slots[].id`).
  TextColumn get slotId => text().named('slot_id').nullable()();

  /// Valet receipt number from check-in or server.
  TextColumn get vrNo => text().named('vr_no').nullable()();

  /// Whether overnight fee was applied at checkout.
  BoolColumn get isOvernight => boolean().named('is_overnight').nullable()();

  /// Whether lost ticket surcharge was applied at checkout.
  BoolColumn get ticketLost => boolean().named('ticket_lost').nullable()();

  /// JSON snapshot of `applied_rate` for offline display.
  TextColumn get appliedRateJson =>
      text().named('applied_rate_json').nullable()();

  /// Legacy `void_request` JSON — no longer written; use flat void columns.
  TextColumn get voidRequestJson =>
      text().named('void_request_json').nullable()();

  /// Server void reason (`void_reason`).
  TextColumn get voidReason => text().named('void_reason').nullable()();

  /// JSON `{ id, username, name }` for `voided_by`.
  TextColumn get voidedByJson => text().named('voided_by_json').nullable()();

  /// ISO-8601 when void was applied (`voided_at`).
  TextColumn get voidedAt => text().named('voided_at').nullable()();

  /// Offline void intent — queued until check-in sync sends `void_requested`.
  BoolColumn get pendingVoidRequest =>
      boolean().named('pending_void_request').withDefault(const Constant(false))();

  /// Reason for the offline void-at-intake request.
  TextColumn get pendingVoidReason =>
      text().named('pending_void_reason').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbound sync queue for `shifts` and `tickets`.
class SyncQueue extends Table {
  @override
  String get tableName => 'sync_queue';

  TextColumn get id => text()();

  /// `create` | `update`
  TextColumn get operation => text()();

  /// Logical table for API routing: `shifts` | `tickets` (SQL: `table_name`).
  TextColumn get queueTableName => text().named('table_name')();

  TextColumn get recordId => text()();

  /// Full row JSON.
  TextColumn get payload => text()();

  /// `pending` | `synced` | `failed`
  TextColumn get syncStatus => text()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-branch, per-vehicle-type parking rates (Drift source for [RateService]).
class Rates extends Table {
  @override
  String get tableName => 'rates';

  TextColumn get id => text()();

  TextColumn get branchId => text()();

  TextColumn get vehicleType => text()();

  IntColumn get flatRateHours => integer()();

  RealColumn get flatRateFee => real()();

  RealColumn get succeedingHourFee => real()();

  RealColumn get overnightFee => real()();

  RealColumn get lostTicketFee => real()();

  /// Overnight billing cutoff (`HH:mm`, local); nullable until synced from API.
  TextColumn get overnightCutoff => text().nullable()();

  /// `pending` | `synced`
  TextColumn get syncStatus => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {branchId, vehicleType},
      ];
}

/// Server-fetched branch settings (overnight window, mall hours, etc.).
class BranchConfigs extends Table {
  @override
  String get tableName => 'branch_config';

  TextColumn get id => text()();

  TextColumn get branchId => text()();

  TextColumn get configKey => text()();

  TextColumn get configValue => text()();

  /// `pending` | `synced`
  TextColumn get syncStatus => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {branchId, configKey},
      ];
}

@DriftDatabase(
  tables: [
    DeviceInfo,
    DeviceIdentity,
    OfflineAccounts,
    Sessions,
    Shifts,
    Tickets,
    SyncQueue,
    Rates,
    BranchConfigs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({bool skipDevOfflineSeed = false})
      : _skipDevOfflineSeed = skipDevOfflineSeed,
        super(_openConnection());

  /// In-memory SQLite for tests (skips dev offline seed by default).
  AppDatabase.memory({bool skipDevOfflineSeed = true})
      : _skipDevOfflineSeed = skipDevOfflineSeed,
        super(NativeDatabase.memory());

  /// When true, dev-only offline seed is skipped (use in tests).
  final bool _skipDevOfflineSeed;

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          // Sample dev seeders disabled — server/API deployed; data comes from backend + device setup.
          // if (!_skipDevOfflineSeed) {
          //   await _seedDevOfflineAccountIfAbsent();
          //   await _seedDevBranchConfig();
          //   if (kDebugMode) {
          //     await RatesSeeder().seed(this);
          //   }
          // }
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(deviceIdentity);
          }
          if (from < 3) {
            await customStatement('''
CREATE TABLE offline_accounts_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  server_user_id TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  last_online_login INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
            await customStatement('''
INSERT INTO offline_accounts_new
  (id, server_user_id, email, password_hash, full_name, role, last_online_login, created_at, updated_at)
SELECT id, CAST(server_user_id AS TEXT), email, password_hash, full_name, role, last_online_login, created_at, updated_at
FROM offline_accounts''');
            await customStatement('DROP TABLE offline_accounts');
            await customStatement(
              'ALTER TABLE offline_accounts_new RENAME TO offline_accounts',
            );
          }
          if (from < 4) {
            await m.addColumn(tickets, tickets.serverTicketId);
          }
          if (from < 5) {
            await m.addColumn(tickets, tickets.driverIn);
            await m.addColumn(tickets, tickets.driverOut);
          }
          if (from < 6) {
            await m.addColumn(deviceIdentity, deviceIdentity.branchId);
            await m.addColumn(deviceIdentity, deviceIdentity.areaId);
            await m.addColumn(deviceIdentity, deviceIdentity.serialNumber);
          }
          if (from < 7) {
            await m.addColumn(
              offlineAccounts,
              offlineAccounts.shiftScheduleJson,
            );
          }
          if (from < 8) {
            await m.addColumn(tickets, tickets.parkingInfo);
          }
          if (from < 9) {
            await m.addColumn(rates, rates.overnightCutoff);
          }
          if (from < 10) {
            await m.addColumn(tickets, tickets.slotId);
          }
          if (from < 11) {
            await m.addColumn(tickets, tickets.paymentSummaryJson);
          }
          if (from < 12) {
            await m.addColumn(tickets, tickets.vrNo);
            await m.addColumn(tickets, tickets.isOvernight);
            await m.addColumn(tickets, tickets.ticketLost);
            await m.addColumn(tickets, tickets.appliedRateJson);
            await m.addColumn(tickets, tickets.voidRequestJson);
            await m.addColumn(tickets, tickets.pendingVoidRequest);
            await m.addColumn(tickets, tickets.pendingVoidReason);
          }
          if (from < 13) {
            await m.addColumn(tickets, tickets.voidReason);
            await m.addColumn(tickets, tickets.voidedByJson);
            await m.addColumn(tickets, tickets.voidedAt);
          }
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_user_status '
      'ON shifts(user_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_branch_opened '
      'ON shifts(branch_id, opened_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tickets_shift ON tickets(shift_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tickets_shift_status '
      'ON tickets(shift_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tickets_plate ON tickets(plate_number)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending '
      'ON sync_queue(sync_status, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_rates_branch ON rates(branch_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_branch_config_branch '
      'ON branch_config(branch_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active)',
    );
  }

  /*
  /// Dev-only: 1@1.com / 1, server id 1001, Kindred Inocencio, cashier.
  Future<void> _seedDevOfflineAccountIfAbsent() async {
    const email = '1@1.com';
    const serverUserId = '1001';
    final existing = await (select(offlineAccounts)
          ..where(
            (a) => a.email.equals(email) | a.serverUserId.equals(serverUserId),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hash = BCrypt.hashpw('1', BCrypt.gensalt());
    await into(offlineAccounts).insert(
      OfflineAccountsCompanion.insert(
        serverUserId: serverUserId,
        email: email,
        passwordHash: hash,
        fullName: 'Kindred Inocencio',
        role: 'cashier',
        lastOnlineLogin: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Sample branch_config for dev branch.
  Future<void> _seedDevBranchConfig() async {
    if (_skipDevOfflineSeed) return;
    const branch = 'jazz-mall';
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();
    final entries = <(String, String)>[
      ('overnight_start_time', '01:30'),
      ('overnight_end_time', '06:00'),
      ('mall_open_time', '10:00'),
      ('mall_close_time', '21:00'),
    ];
    for (final e in entries) {
      await customStatement(
        'INSERT OR IGNORE INTO branch_config '
        '(id, branch_id, config_key, config_value, sync_status, updated_at) '
        "VALUES (?, ?, ?, ?, 'synced', ?)",
        [uuid.v4(), branch, e.$1, e.$2, now],
      );
    }
  }
  */

  /// Fills `device_info` from local dev defaults — disabled while server/API is source of truth.
  /// Kept as a no-op so [AuthRepository.seedDevDeviceSiteIfNeeded] call sites stay stable.
  Future<void> seedDevDeviceInfoIfNeeded({
    required String deviceId,
    required String branch,
    required String area,
  }) async {
    if (_skipDevOfflineSeed) return;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'valet_master.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
