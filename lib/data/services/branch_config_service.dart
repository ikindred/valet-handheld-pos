import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/branch/overnight_window.dart';
import '../../core/config/app_config.dart';
import '../../core/logging/valet_log.dart';
import '../local/db/app_database.dart';
import '../repositories/auth_repository.dart';

/// Single source of truth for branch-level settings (backed by [BranchConfigs]).
///
/// Other services must not read `branch_config` directly — use this class.
class BranchConfigService {
  BranchConfigService(
    this._db,
    this._dio,
    this._auth,
  );

  final AppDatabase _db;
  final Dio _dio;
  final AuthRepository _auth;

  static const _uuid = Uuid();

  /// ISO8601 timestamp string; device should use Asia/Manila wall time.
  static String _nowIso8601() => DateTime.now().toIso8601String();

  /// GET branch detail + global settings; upserts [BranchConfigs] rows.
  Future<void> syncFromServer(String branchId) async {
    final id = branchId.trim();
    if (id.isEmpty) {
      ValetLog.warning('BranchConfigService.syncFromServer', 'empty branchId');
      return;
    }
    if (AppConfig.useStubApi) {
      ValetLog.info(
        'BranchConfigService.syncFromServer',
        'skip: stub API (no API_BASE_URL)',
      );
      return;
    }
    final session = await _auth.getActiveSession();
    final token = session?.authToken;
    if (token == null || token.isEmpty) {
      ValetLog.warning(
        'BranchConfigService.syncFromServer',
        'warn: no bearer token — skip remote sync',
      );
      return;
    }

    final opts = Options(
      headers: {'Authorization': 'Bearer $token'},
      validateStatus: (s) => s != null && s < 500,
    );

    final entries = <({String key, String value})>[];

    try {
      final branchUrl = AppConfig.branchDetailUrl(id);
      final res = await _dio.get<dynamic>(branchUrl, options: opts);
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final root = _asStringKeyedMap(res.data);
        final branch = _unwrapBranchMap(root);
        if (branch != null) {
          final open = _hhMmFromDynamic(
            branch['opensAt'] ??
                branch['opens_at'] ??
                branch['openTime'] ??
                branch['mall_open_time'],
          );
          final close = _hhMmFromDynamic(
            branch['closesAt'] ??
                branch['closes_at'] ??
                branch['closeTime'] ??
                branch['mall_close_time'],
          );
          if (open != null) {
            entries.add((key: 'mall_open_time', value: open));
          }
          if (close != null) {
            entries.add((key: 'mall_close_time', value: close));
          }
        }
      } else if (status == 401 || status == 403) {
        ValetLog.warning(
          'BranchConfigService.syncFromServer',
          'warn: HTTP $status for $branchUrl',
        );
        return;
      } else {
        ValetLog.warning(
          'BranchConfigService.syncFromServer',
          'warn: HTTP $status for $branchUrl',
        );
      }
    } catch (e, st) {
      ValetLog.error(
        'BranchConfigService.syncFromServer',
        'branch detail request failed — continuing with settings',
        e,
        st,
      );
    }

    try {
      final settingsUrl = AppConfig.config;
      final res = await _dio.get<dynamic>(settingsUrl, options: opts);
      final status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final root = _asStringKeyedMap(res.data);
        final settings = _unwrapSettingsMap(root);
        if (settings != null) {
          final cutoff = _hhMmFromDynamic(
            settings['overnightCutoff'] ??
                settings['overnight_cutoff'] ??
                settings['overnightStart'] ??
                settings['overnight_start_time'],
          );
          if (cutoff != null) {
            entries.add((key: 'overnight_start_time', value: cutoff));
          }
        }
        entries.add((key: 'overnight_end_time', value: '06:00'));
      } else {
        ValetLog.warning(
          'BranchConfigService.syncFromServer',
          'warn: HTTP $status for $settingsUrl',
        );
      }
    } catch (e, st) {
      ValetLog.error(
        'BranchConfigService.syncFromServer',
        'settings request failed',
        e,
        st,
      );
    }

    if (entries.isEmpty) {
      ValetLog.info(
        'BranchConfigService.syncFromServer',
        'no branch/settings keys parsed for branch=$id',
      );
      return;
    }

    final updatedAt = _nowIso8601();
    try {
      await _db.transaction(() async {
        for (final e in entries) {
          await _upsertRow(
            branchId: id,
            configKey: e.key,
            configValue: e.value,
            updatedAt: updatedAt,
          );
        }
      });
      ValetLog.info(
        'BranchConfigService.syncFromServer',
        'saved ${entries.length} keys for branch=$id',
      );
    } catch (e, st) {
      ValetLog.error(
        'BranchConfigService.syncFromServer',
        'persist failure — keeping prior cache',
        e,
        st,
      );
    }
  }

  /// Uses [AuthRepository.branchAndAreaFromDb] branch string when non-empty.
  Future<void> syncFromServerForDeviceBranch() async {
    final site = await _auth.branchAndAreaFromDb();
    await syncFromServer(site.branch);
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Map<String, dynamic>? _unwrapBranchMap(Map<String, dynamic>? root) {
    if (root == null) return null;
    for (final key in const ['data', 'branch', 'result']) {
      final v = root[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return root;
  }

  static Map<String, dynamic>? _unwrapSettingsMap(Map<String, dynamic>? root) {
    if (root == null) return null;
    for (final key in const ['data', 'settings', 'result']) {
      final v = root[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return root;
  }

  /// Parses ISO datetime or `HH:mm` into `HH:mm` for [OvernightWindow.parseHhMm].
  static String? _hhMmFromDynamic(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return '${iso.hour.toString().padLeft(2, '0')}:'
          '${iso.minute.toString().padLeft(2, '0')}';
    }
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
    if (m != null) {
      final h = int.tryParse(m.group(1)!) ?? 0;
      final min = int.tryParse(m.group(2)!) ?? 0;
      return '${h.toString().padLeft(2, '0')}:'
          '${min.toString().padLeft(2, '0')}';
    }
    return null;
  }

  Future<void> _upsertRow({
    required String branchId,
    required String configKey,
    required String configValue,
    required String updatedAt,
  }) async {
    final existing = await (_db.select(_db.branchConfigs)
          ..where(
            (c) =>
                c.branchId.equals(branchId) & c.configKey.equals(configKey),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.branchConfigs)..where((c) => c.id.equals(existing.id)))
          .write(
        BranchConfigsCompanion(
          configValue: Value(configValue),
          syncStatus: const Value('synced'),
          updatedAt: Value(updatedAt),
        ),
      );
    } else {
      await _db.into(_db.branchConfigs).insert(
            BranchConfigsCompanion.insert(
              id: _uuid.v4(),
              branchId: branchId,
              configKey: configKey,
              configValue: configValue,
              syncStatus: 'synced',
              updatedAt: updatedAt,
            ),
          );
    }
  }

  /// All key/value rows for [branchId] (empty map if none — logs warning).
  Future<Map<String, String>> getConfig(String branchId) async {
    final id = branchId.trim();
    final rows = await (_db.select(_db.branchConfigs)
          ..where((c) => c.branchId.equals(id)))
        .get();
    if (rows.isEmpty) {
      ValetLog.warning(
        'BranchConfigService.getConfig',
        'warn: no branch_config rows for branchId=$id',
      );
      return {};
    }
    return {for (final r in rows) r.configKey: r.configValue};
  }

  /// From cached `overnight_start_time` / `overnight_end_time` (`HH:mm`).
  Future<OvernightWindow?> getOvernightWindow(String branchId) async {
    final map = await getConfig(branchId.trim());
    final start = OvernightWindow.parseHhMm(map['overnight_start_time']);
    final end = OvernightWindow.parseHhMm(map['overnight_end_time']);
    if (start == null || end == null) return null;
    return OvernightWindow(startTime: start, endTime: end);
  }
}
