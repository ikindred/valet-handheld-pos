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

  /// GET branch config, upsert rows, swallow errors (cache stays valid).
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

    try {
      final url = AppConfig.branchConfigUrl(id);
      final res = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final status = res.statusCode ?? 0;
      if (status == 401 || status == 403) {
        ValetLog.warning(
          'BranchConfigService.syncFromServer',
          'warn: HTTP $status for $url',
        );
        return;
      }
      if (status < 200 || status >= 300) {
        ValetLog.warning(
          'BranchConfigService.syncFromServer',
          'warn: HTTP $status for $url',
        );
        return;
      }
      final list = _parseConfigList(res.data);
      if (list.isEmpty) {
        ValetLog.info(
          'BranchConfigService.syncFromServer',
          'empty config list for branch=$id',
        );
        return;
      }
      final updatedAt = _nowIso8601();
      await _db.transaction(() async {
        for (final item in list) {
          final key = (item['configKey'] ?? item['config_key'] ?? '')
              .toString()
              .trim();
          final value =
              (item['configValue'] ?? item['config_value'] ?? '').toString();
          if (key.isEmpty) continue;
          await _upsertRow(branchId: id, configKey: key, configValue: value, updatedAt: updatedAt);
        }
      });
      ValetLog.info(
        'BranchConfigService.syncFromServer',
        'saved ${list.length} keys for branch=$id',
      );
    } catch (e, st) {
      ValetLog.error(
        'BranchConfigService.syncFromServer',
        'network or parse failure — keeping cache',
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

  static List<Map<String, dynamic>> _parseConfigList(dynamic data) {
    if (data is List) {
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) e
          else if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      for (final key in const ['data', 'config', 'items', 'results']) {
        final v = m[key];
        final parsed = _parseConfigList(v);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return const [];
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
