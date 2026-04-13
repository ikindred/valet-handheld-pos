import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/valet_log.dart';
import '../../../data/local/db/app_database.dart';
import '../../../data/repositories/auth_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required AppDatabase database,
    required Dio dio,
    required AuthRepository authRepository,
  })  : _db = database,
        _dio = dio,
        _auth = authRepository,
        super(const SyncIdle());

  final AppDatabase _db;
  final Dio _dio;
  final AuthRepository _auth;

  Future<int> pendingCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'pending'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> failedCount() async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE sync_status = 'failed'",
      readsFrom: {_db.syncQueue},
    ).getSingle();
    return (row.data['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> retryFailed() async {
    await _db.customStatement(
      "UPDATE sync_queue SET sync_status = 'pending', retry_count = 0 "
      "WHERE sync_status = 'failed'",
    );
    await flush();
  }

  Future<void> flush() async {
    emit(const SyncInProgress());
    var syncedThisRun = 0;
    try {
      final pending = await (_db.select(_db.syncQueue)
            ..where((q) => q.syncStatus.equals('pending'))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

      if (pending.isEmpty) {
        emit(SyncComplete(
          synced: 0,
          failed: await failedCount(),
          pending: 0,
        ));
        return;
      }

      if (AppConfig.useStubApi) {
        for (final row in pending) {
          await _markQueueSynced(row);
          await _markEntitySynced(row);
          syncedThisRun++;
        }
      } else {
        final session = await _auth.getActiveSession();
        final token = session?.authToken;
        if (token == null || token.isEmpty) {
          ValetLog.debug('SyncCubit.flush', 'skip HTTP — no bearer token');
        } else {
          for (final row in pending) {
            final routed = _route(row);
            if (routed == null) {
              ValetLog.error(
                'SyncCubit.flush',
                'unknown route table=${row.queueTableName} op=${row.operation} '
                    'id=${row.id} recordId=${row.recordId} payload=${row.payload}',
                StateError('SYNC_ROUTE'),
              );
              await _markQueueFailed(row);
              continue;
            }
            final (method, url) = routed;
            Object? body;
            try {
              body = jsonDecode(row.payload);
            } catch (e, st) {
              ValetLog.error(
                'SyncCubit.flush',
                'invalid JSON payload queueId=${row.id}',
                e,
                st,
              );
              await _markQueueFailed(row);
              continue;
            }

            try {
              final response = await _send(
                method: method,
                url: url,
                token: token,
                body: body,
              );
              final code = response.statusCode ?? 0;
              if (code == 200 || code == 201) {
                await _markQueueSynced(row);
                await _markEntitySynced(row);
                syncedThisRun++;
              } else if (code >= 400 && code < 500) {
                ValetLog.error(
                  'SyncCubit.flush',
                  'client error $code $method $url body=$body',
                  StateError('HTTP_$code'),
                );
                await _markQueueFailed(row);
              } else {
                await _incrementRetry(row);
              }
            } on DioException catch (e, st) {
              final status = e.response?.statusCode;
              if (status != null && status >= 400 && status < 500) {
                ValetLog.error(
                  'SyncCubit.flush',
                  'client error $status $method $url body=$body',
                  e,
                  st,
                );
                await _markQueueFailed(row);
              } else {
                ValetLog.error(
                  'SyncCubit.flush',
                  'retry $method $url',
                  e,
                  st,
                );
                await _incrementRetry(row);
              }
            }
          }
        }
      }

      emit(SyncComplete(
        synced: syncedThisRun,
        failed: await failedCount(),
        pending: await pendingCount(),
      ));
    } catch (e, st) {
      ValetLog.error('SyncCubit.flush', 'unexpected', e, st);
      emit(SyncError(e.toString()));
    }
  }

  (String method, String url)? _route(SyncQueueData row) {
    final table = row.queueTableName;
    final op = row.operation;
    if (table == 'shifts' && op == 'create') {
      return ('POST', AppConfig.shiftsRest);
    }
    if (table == 'shifts' && op == 'update') {
      return ('PATCH', AppConfig.shiftById(row.recordId));
    }
    if (table == 'tickets' && op == 'create') {
      return ('POST', AppConfig.ticketsRest);
    }
    if (table == 'tickets' && op == 'update') {
      return ('PATCH', AppConfig.ticketById(row.recordId));
    }
    return null;
  }

  Future<Response<dynamic>> _send({
    required String method,
    required String url,
    required String token,
    required Object? body,
  }) async {
    final opts = Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    switch (method) {
      case 'POST':
        return _dio.post<dynamic>(url, data: body, options: opts);
      case 'PATCH':
        return _dio.patch<dynamic>(url, data: body, options: opts);
      default:
        throw StateError('Unsupported method $method');
    }
  }

  Future<void> _markQueueSynced(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          const SyncQueueCompanion(syncStatus: Value('synced')),
        );
  }

  Future<void> _markQueueFailed(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          const SyncQueueCompanion(syncStatus: Value('failed')),
        );
  }

  Future<void> _incrementRetry(SyncQueueData row) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(row.id))).write(
          SyncQueueCompanion(retryCount: Value(row.retryCount + 1)),
        );
  }

  Future<void> _markEntitySynced(SyncQueueData row) async {
    switch (row.queueTableName) {
      case 'shifts':
        await (_db.update(_db.shifts)..where((s) => s.id.equals(row.recordId)))
            .write(
          const ShiftsCompanion(syncStatus: Value('synced')),
        );
        break;
      case 'tickets':
        await (_db.update(_db.tickets)..where((t) => t.id.equals(row.recordId)))
            .write(
          const TicketsCompanion(syncStatus: Value('synced')),
        );
        break;
    }
  }
}
