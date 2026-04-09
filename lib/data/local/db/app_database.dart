import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
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

  /// Client UUID for idempotent sync; backfilled on upgrade for legacy rows.
  TextColumn get localUuid => text().nullable().unique()();

  /// Shift that was open when the vehicle was checked in (immutable).
  @ReferenceName('valet_tx_checkin_shift_ref')
  IntColumn get checkinShiftId => integer().references(Shifts, #id)();

  /// Shift responsible for checkout: set when adopting from a prior cashier's
  /// open tickets, or on actual checkout. Null until assigned.
  @ReferenceName('valet_tx_checkout_shift_ref')
  IntColumn get checkoutShiftId =>
      integer().nullable().references(Shifts, #id)();

  IntColumn get userId => integer().references(OfflineAccounts, #id)();

  TextColumn get ticketNumber => text().unique()();

  TextColumn get plateNumber => text()();

  TextColumn get vehicleBrand => text().nullable()();

  TextColumn get vehicleModel => text().nullable()();

  TextColumn get vehicleYear => text().nullable()();

  TextColumn get vehicleColor => text().nullable()();

  TextColumn get vehicleType => text().nullable()();

  TextColumn get slot => text().nullable()();

  TextColumn get parkingLevel => text().nullable()();

  TextColumn get parkingSlot => text().nullable()();

  TextColumn get belongingsJson => text().nullable()();

  TextColumn get otherBelongings => text().nullable()();

  /// Base64-encoded PNG (same bytes as before; stored as TEXT instead of BLOB).
  TextColumn get signaturePng => text().nullable()();

  IntColumn get signatureCapturedAt => integer().nullable()();

  TextColumn get customerFullName => text().nullable()();

  TextColumn get customerMobile => text().nullable()();

  TextColumn get assignedValetDriver => text().nullable()();

  TextColumn get specialInstructions => text().nullable()();

  TextColumn get valetServiceType => text().nullable()();

  TextColumn get vehicleDamageJson => text().nullable()();

  TextColumn get branchSnapshot => text().nullable()();

  TextColumn get areaSnapshot => text().nullable()();

  TextColumn get deviceIdSnapshot => text().nullable()();

  TextColumn get serverTicketId => text().nullable()();

  IntColumn get lastModifiedAt => integer().nullable()();

  IntColumn get localCreatedAt => integer().nullable()();

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
  int get schemaVersion => 11;

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
          if (from < 9) {
            await _migrateTransactionsToV9();
          }
          if (from < 10) {
            await _migrateSignaturePngBlobToText();
          }
          if (from < 11) {
            await _migrateTransactionsToV11();
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

  /// v10: store signature as base64 PNG text instead of SQLite BLOB.
  Future<void> _migrateSignaturePngBlobToText() async {
    final infoRows = await customSelect('PRAGMA table_info(transactions)').get();
    String? sigSqlType;
    for (final r in infoRows) {
      if (r.data['name'] == 'signature_png') {
        sigSqlType = (r.data['type'] as String?)?.toUpperCase();
        break;
      }
    }
    if (sigSqlType == null) return;
    if (sigSqlType == 'TEXT') return;

    await transaction(() async {
      await customStatement(
        'ALTER TABLE transactions ADD COLUMN signature_png_text TEXT',
      );

      final rows = await customSelect(
        'SELECT id, signature_png FROM transactions WHERE signature_png IS NOT NULL',
      ).get();

      for (final row in rows) {
        final id = row.data['id'] as int;
        final blob = row.data['signature_png'];
        if (blob == null) continue;
        final bytes = blob is Uint8List
            ? blob
            : Uint8List.fromList(List<int>.from(blob as List<dynamic>));
        final b64 = base64Encode(bytes);
        await customStatement(
          'UPDATE transactions SET signature_png_text = ? WHERE id = ?',
          [b64, id],
        );
      }

      await customStatement('ALTER TABLE transactions DROP COLUMN signature_png');
      await customStatement(
        'ALTER TABLE transactions RENAME COLUMN signature_png_text TO signature_png',
      );
    });
  }

  /// Offline check-in: extend `transactions` per plan (sections A–J).
  Future<void> _migrateTransactionsToV9() async {
    final cols = await _columnNames('transactions');
    Future<void> addText(String sqlName) async {
      if (!cols.contains(sqlName)) {
        await customStatement(
          'ALTER TABLE transactions ADD COLUMN $sqlName TEXT',
        );
        cols.add(sqlName);
      }
    }

    Future<void> addInt(String sqlName) async {
      if (!cols.contains(sqlName)) {
        await customStatement(
          'ALTER TABLE transactions ADD COLUMN $sqlName INTEGER',
        );
        cols.add(sqlName);
      }
    }

    Future<void> addBlob(String sqlName) async {
      if (!cols.contains(sqlName)) {
        await customStatement(
          'ALTER TABLE transactions ADD COLUMN $sqlName BLOB',
        );
        cols.add(sqlName);
      }
    }

    await addText('local_uuid');
    await addText('vehicle_model');
    await addText('vehicle_year');
    await addText('parking_level');
    await addText('parking_slot');
    await addText('belongings_json');
    await addText('other_belongings');
    await addBlob('signature_png');
    await addInt('signature_captured_at');
    await addText('customer_full_name');
    await addText('assigned_valet_driver');
    await addText('special_instructions');
    await addText('valet_service_type');
    await addText('vehicle_damage_json');
    await addText('branch_snapshot');
    await addText('area_snapshot');
    await addText('device_id_snapshot');
    await addText('server_ticket_id');
    await addInt('last_modified_at');
    await addInt('local_created_at');

    await customStatement(
      "UPDATE transactions SET parking_slot = slot "
      "WHERE (parking_slot IS NULL OR parking_slot = '') "
      "AND slot IS NOT NULL AND TRIM(slot) != ''",
    );

    const uuid = Uuid();
    final rows = await customSelect(
      'SELECT id FROM transactions WHERE local_uuid IS NULL OR local_uuid = \'\'',
    ).get();
    for (final row in rows) {
      final id = row.data['id'] as int;
      await customStatement(
        "UPDATE transactions SET local_uuid = '${uuid.v4()}' WHERE id = $id",
      );
    }

    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_local_uuid '
      'ON transactions(local_uuid) WHERE local_uuid IS NOT NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_shift_time_in '
      'ON transactions(shift_id, time_in)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_pending_sync '
      'ON transactions(synced_at) WHERE synced_at IS NULL',
    );
  }

  /// v11: split transaction shift into check-in vs checkout shift columns + indexes.
  Future<void> _migrateTransactionsToV11() async {
    final cols = await _columnNames('transactions');

    if (!cols.contains('checkin_shift_id')) {
      if (cols.contains('shift_id')) {
        await customStatement(
          'ALTER TABLE transactions RENAME COLUMN shift_id TO checkin_shift_id',
        );
      }
    }

    if (!cols.contains('checkout_shift_id')) {
      await customStatement(
        'ALTER TABLE transactions ADD COLUMN checkout_shift_id INTEGER '
        'REFERENCES shifts(id)',
      );
    }

    await customStatement(
      'UPDATE transactions SET checkout_shift_id = checkin_shift_id '
      'WHERE time_out IS NOT NULL AND checkout_shift_id IS NULL',
    );

    await customStatement('DROP INDEX IF EXISTS idx_transactions_shift');
    await customStatement('DROP INDEX IF EXISTS idx_transactions_shift_time_in');

    await _createTransactionIndexesV11();
  }

  Future<void> _createTransactionIndexesV11() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_checkin_shift '
      'ON transactions(checkin_shift_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_checkout_shift '
      'ON transactions(checkout_shift_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_checkin_time_in '
      'ON transactions(checkin_shift_id, time_in)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_open_checkin '
      'ON transactions(checkin_shift_id, status) WHERE time_out IS NULL',
    );
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_user_open ON shifts(user_id, is_open)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending ON sync_queue(synced_at, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_pending_sync '
      'ON transactions(synced_at) WHERE synced_at IS NULL',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_local_uuid '
      'ON transactions(local_uuid) WHERE local_uuid IS NOT NULL',
    );
    await _createTransactionIndexesV11();
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
