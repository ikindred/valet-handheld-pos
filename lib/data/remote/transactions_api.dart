import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';

/// Remote transaction list for Tier 2 reports / merge (not sync flush).
class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  /// GET [AppConfig.transactionsList] with query params per Tier 2 spec.
  Future<List<Map<String, dynamic>>> fetchTransactions({
    required String token,
    required int cashierId,
    required String branch,
    required String area,
    required int dateFromUnix,
    required int dateToUnix,
  }) async {
    if (AppConfig.useStubApi) {
      return const [];
    }
    final res = await _dio.get<dynamic>(
      AppConfig.transactionsList,
      queryParameters: <String, dynamic>{
        'cashier_id': cashierId,
        'branch': branch,
        'area': area,
        'date_from': dateFromUnix,
        'date_to': dateToUnix,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return _parseList(res.data);
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
