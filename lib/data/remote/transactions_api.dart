import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';

/// Remote transaction list for Tier 2 reports / merge (not sync flush).
class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  /// GET [AppConfig.transactionsList] — `date_from` / `date_to` as `YYYY-MM-DD` (local range).
  ///
  /// [dateFromUnix] / [dateToUnix] are **seconds** since epoch (e.g. from `DateTime.millisecondsSinceEpoch ~/ 1000`).
  Future<List<Map<String, dynamic>>> fetchTransactions({
    required String token,
    required int dateFromUnix,
    required int dateToUnix,
    int limit = 200,
    int page = 1,
  }) async {
    if (AppConfig.useStubApi) {
      return const [];
    }
    final dateFrom = _isoDateFromUnixSeconds(dateFromUnix);
    final dateTo = _isoDateFromUnixSeconds(dateToUnix);
    final res = await _dio.get<dynamic>(
      AppConfig.transactionsList,
      queryParameters: <String, dynamic>{
        'date_from': dateFrom,
        'date_to': dateTo,
        'limit': limit,
        'page': page,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return _parseList(res.data);
  }

  static String _isoDateFromUnixSeconds(int unixSeconds) {
    final local = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: false,
    );
    return local.toIso8601String().substring(0, 10);
  }

  static List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) e
          else if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      for (final key in const ['data', 'transactions', 'results', 'rows']) {
        final v = m[key];
        if (v is List) return _parseList(v);
      }
    }
    return const [];
  }
}
