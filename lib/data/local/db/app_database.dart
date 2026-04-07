import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
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

/// Offline credentials (email + bcrypt hash, plus API metadata).
class OfflineAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Canonical user id from API.
  IntColumn get serverUserId => integer().unique()();

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

/// Cash shift (open / close).
class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer().references(Sessions, #id)();

  IntColumn get userId => integer().references(OfflineAccounts, #id)();

  TextColumn get branch => text()();

  TextColumn get area => text()();

  /// YYYY-MM-DD
  TextColumn get shiftDate => text()();

  BoolColumn get isOpen => boolean().withDefault(const Constant(true))();

  RealColumn get openingFloat => real().withDefault(const Constant(0.0))();

  TextColumn get openingNotes => text().nullable()();

  RealColumn get closingFloat => real().nullable()();

  TextColumn get closingNotes => text().nullable()();

  RealColumn get totalSales => real().withDefault(const Constant(0.0))();

  RealColumn get expectedCash => real().nullable()();

  RealColumn get variance => real().nullable()();

  RealColumn get remittance => real().nullable()();

  IntColumn get transactionsCount => integer().withDefault(const Constant(0))();

  IntColumn get openedAt => integer()();

  IntColumn get closedAt => integer().nullable()();

  IntColumn get syncedAt => integer().nullable()();
}

class ShiftOpeningDenominations extends Table {
  @override
  String get tableName => 'shift_opening_denominations';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get shiftId => integer().references(Shifts, #id)();

  /// 1000, 500, 200, …
  IntColumn get denom => integer()();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
}

class ShiftClosingDenominations extends Table {
  @override
  String get tableName => 'shift_closing_denominations';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get shiftId => integer().references(Shifts, #id)();

  IntColumn get denom => integer()();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
}

/// Ticket / parking transaction rows.
class ValetTransactions extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get shiftId => integer().references(Shifts, #id)();

  IntColumn get userId => integer().references(OfflineAccounts, #id)();

  TextColumn get ticketNumber => text().unique()();

  TextColumn get plateNumber => text()();

  TextColumn get vehicleBrand => text().nullable()();

  TextColumn get vehicleColor => text().nullable()();

  TextColumn get vehicleType => text().nullable()();

  TextColumn get slot => text().nullable()();

  TextColumn get customerMobile => text().nullable()();

  IntColumn get timeIn => integer()();

  IntColumn get timeOut => integer().nullable()();

  IntColumn get durationMinutes => integer().nullable()();

  RealColumn get flatRate => real().nullable()();

  RealColumn get succeedingFee => real().nullable()();

  RealColumn get overnightFee => real().nullable()();

  RealColumn get lostTicketFee => real().nullable()();

  RealColumn get totalFee => real().nullable()();

  RealColumn get amountTendered => real().nullable()();

  RealColumn get changeAmount => real().nullable()();

  TextColumn get status => text().withDefault(const Constant('active'))();

  IntColumn get syncedAt => integer().nullable()();
}

class SyncQueue extends Table {
  @override
  String get tableName => 'sync_queue';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  IntColumn get entityId => integer()();

  TextColumn get payload => text()();

  IntColumn get createdAt => integer()();

  IntColumn get syncedAt => integer().nullable()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(
  tables: [
    DeviceInfo,
    OfflineAccounts,
    Sessions,
    Shifts,
    ShiftOpeningDenominations,
    ShiftClosingDenominations,
    ValetTransactions,
    SyncQueue,
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          // TODO(dev-seed): REMOVE before production — fake offline user for local dev.
          if (!_skipDevOfflineSeed) {
            await _seedDevOfflineAccountIfAbsent();
          }
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            await customStatement('DROP TABLE IF EXISTS shifts');
            await customStatement('DROP TABLE IF EXISTS sessions');
            await customStatement('DROP TABLE IF EXISTS offline_accounts');
            await m.createTable(offlineAccounts);
            await m.createTable(sessions);
            await m.createTable(shifts);
          }
          if (from < 4) {
            await customStatement('DROP TABLE IF EXISTS device_infos');
          }
          if (from < 5) {
            await _migrateToV5(m, from);
          }
          // TODO(dev-seed): REMOVE before production — fake offline user for local dev.
          // v7: re-run for DBs that reached v6 before the seed existed (migration is idempotent).
          if (from < 7 && !_skipDevOfflineSeed) {
            await _seedDevOfflineAccountIfAbsent();
          }
          if (from < 8) {
            await _migrateDeviceInfoToV8();
          }
        },
      );

  /// Dev-only: 1@1.com / 1, server id 1001, Kindred Inocencio, cashier.
  /// TODO(dev-seed): REMOVE before production — fake offline user for local dev.
  Future<void> _seedDevOfflineAccountIfAbsent() async {
    const email = '1@1.com';
    const serverUserId = 1001;
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

  Future<void> _migrateDeviceInfoToV8() async {
    final cols = await _columnNames('device_info');
    if (!cols.contains('branch')) {
      await customStatement(
        "ALTER TABLE device_info ADD COLUMN branch TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!cols.contains('area')) {
      await customStatement(
        "ALTER TABLE device_info ADD COLUMN area TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_user_open ON shifts(user_id, is_open)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_shift ON transactions(shift_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending ON sync_queue(synced_at, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active)',
    );
  }

  Future<void> _migrateToV5(Migrator m, int from) async {
    await customStatement(
      'UPDATE offline_accounts SET full_name = COALESCE(full_name, \'\')',
    );
    await customStatement(
      'UPDATE offline_accounts SET role = COALESCE(role, \'\')',
    );

    // v1–2: `from < 3` already recreated shifts with the v5 shape. v3–4: legacy rows need ALTER.
    if (from >= 3) {
      await _alterShiftsAddColumnsIfNeeded();
    }

    if (!await _tableExists('device_info')) {
      await m.createTable(deviceInfo);
    }
    if (!await _tableExists('shift_opening_denominations')) {
      await m.createTable(shiftOpeningDenominations);
    }
    if (!await _tableExists('shift_closing_denominations')) {
      await m.createTable(shiftClosingDenominations);
    }
    if (!await _tableExists('transactions')) {
      await m.createTable(valetTransactions);
    }
    if (!await _tableExists('sync_queue')) {
      await m.createTable(syncQueue);
    }

    await _createIndexes();
  }

  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.data['name'] as String).toSet();
  }

  Future<void> _alterShiftsAddColumnsIfNeeded() async {
    final cols = await _columnNames('shifts');
    Future<void> add(String sql) async => customStatement(sql);

    if (!cols.contains('branch')) {
      await add(
        "ALTER TABLE shifts ADD COLUMN branch TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!cols.contains('area')) {
      await add("ALTER TABLE shifts ADD COLUMN area TEXT NOT NULL DEFAULT ''");
    }
    if (!cols.contains('shift_date')) {
      await add(
        "ALTER TABLE shifts ADD COLUMN shift_date TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!cols.contains('opening_notes')) {
      await add('ALTER TABLE shifts ADD COLUMN opening_notes TEXT');
    }
    if (!cols.contains('closing_float')) {
      await add('ALTER TABLE shifts ADD COLUMN closing_float REAL');
    }
    if (!cols.contains('closing_notes')) {
      await add('ALTER TABLE shifts ADD COLUMN closing_notes TEXT');
    }
    if (!cols.contains('total_sales')) {
      await add(
        'ALTER TABLE shifts ADD COLUMN total_sales REAL NOT NULL DEFAULT 0',
      );
    }
    if (!cols.contains('expected_cash')) {
      await add('ALTER TABLE shifts ADD COLUMN expected_cash REAL');
    }
    if (!cols.contains('variance')) {
      await add('ALTER TABLE shifts ADD COLUMN variance REAL');
    }
    if (!cols.contains('remittance')) {
      await add('ALTER TABLE shifts ADD COLUMN remittance REAL');
    }
    if (!cols.contains('transactions_count')) {
      await add(
        'ALTER TABLE shifts ADD COLUMN transactions_count INTEGER NOT NULL DEFAULT 0',
      );
    }

    await customStatement(
      "UPDATE shifts SET shift_date = strftime('%Y-%m-%d', opened_at, 'unixepoch') "
      "WHERE shift_date IS NULL OR shift_date = ''",
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'valet_master.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
