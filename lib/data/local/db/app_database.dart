import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/seeders/rates_seeder.dart';

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
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          // TODO(dev-seed): REMOVE before production — fake offline user for local dev.
          if (!_skipDevOfflineSeed) {
            await _seedDevOfflineAccountIfAbsent();
            await _seedDevBranchConfig();
            if (kDebugMode) {
              await RatesSeeder().seed(this);
            }
          }
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

  /// Dev-only: 1@1.com / 1, server id 1001, Kindred Inocencio, cashier.
  /// TODO(dev-seed): REMOVE before production — fake offline user for local dev.
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

  /// TODO(dev-seed): REMOVE before production — sample branch_config for dev branch.
  /// Idempotent: [BranchConfigs.uniqueKeys] on `(branch_id, config_key)` + `INSERT OR IGNORE`.
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

  /// TODO(dev-seed): REMOVE before production — fills `device_info` for the real [deviceId] when missing or empty.
  /// Skipped when [_skipDevOfflineSeed] (tests).
  Future<void> seedDevDeviceInfoIfNeeded({
    required String deviceId,
    required String branch,
    required String area,
  }) async {
    if (_skipDevOfflineSeed) return;
    if (branch.isEmpty || area.isEmpty) return;
    final existing = await (select(deviceInfo)
          ..where((d) => d.deviceId.equals(deviceId))
          ..limit(1))
        .getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (existing == null) {
      await into(deviceInfo).insert(
        DeviceInfoCompanion.insert(
          deviceId: deviceId,
          branch: Value(branch),
          area: Value(area),
          registeredAt: now,
        ),
      );
      return;
    }
    if (existing.branch.trim().isEmpty && existing.area.trim().isEmpty) {
      await (update(deviceInfo)..where((d) => d.id.equals(existing.id)))
          .write(
        DeviceInfoCompanion(
          branch: Value(branch),
          area: Value(area),
          registeredAt: Value(now),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'valet_master.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
