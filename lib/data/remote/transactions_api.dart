import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';

/// Thrown by [TransactionsApi] on HTTP errors or bad response bodies.
class TransactionsApiException implements Exception {
  TransactionsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode != null
          ? 'TransactionsApiException($statusCode): $message'
          : 'TransactionsApiException: $message';
}

/// Remote transactions (list Tier 2, single fetch, ticket number lookup, lost).
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

  /// GET [AppConfig.transactionGetUrl] — single transaction by server UUID.
  Future<Map<String, dynamic>> getTransactionById({
    required String token,
    required String id,
  }) async {
    final sid = id.trim();
    if (sid.isEmpty) {
      throw TransactionsApiException('Transaction id is empty.');
    }
    if (AppConfig.useStubApi) {
      return _stubTransactionMap(serverId: sid, ticketNumber: 'TKT-0001');
    }
    try {
      final res = await _dio.get<dynamic>(
        AppConfig.transactionGetUrl(sid),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwIfBadResponse(res, 'GET transaction $sid');
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _fromDio(e, 'GET transaction $sid');
    }
  }

  /// GET [AppConfig.ticketByNumberUrl] — transaction payload keyed by local ticket number.
  Future<Map<String, dynamic>> getTransactionByTicketNumber({
    required String token,
    required String ticketNumber,
  }) async {
    final code = ticketNumber.trim();
    if (code.isEmpty) {
      throw TransactionsApiException('Ticket number is empty.');
    }
    if (AppConfig.useStubApi) {
      return _stubTransactionMap(
        serverId: '00000000-0000-4000-8000-000000000001',
        ticketNumber: code,
      );
    }
    try {
      final res = await _dio.get<dynamic>(
        AppConfig.ticketByNumberUrl(code),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwIfBadResponse(res, 'GET ticket by number $code');
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _fromDio(e, 'GET ticket by number $code');
    }
  }

  /// POST [AppConfig.ticketLost] — mark ticket lost (live-only; no queue).
  Future<Map<String, dynamic>> markTicketLost({
    required String token,
    required String ticketId,
    String? notes,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) {
      throw TransactionsApiException('Ticket id is empty.');
    }
    if (AppConfig.useStubApi) {
      return <String, dynamic>{'status': 'LOST', 'fee': 200.0};
    }
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.ticketLost(tid),
        data: <String, dynamic>{'notes': notes},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwIfBadResponse(res, 'POST ticket lost $tid');
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _fromDio(e, 'POST ticket lost $tid');
    }
  }

  static Map<String, dynamic> _stubTransactionMap({
    required String serverId,
    required String ticketNumber,
  }) {
    return <String, dynamic>{
      'id': serverId,
      'ticket_number': ticketNumber,
      'check_in_time': DateTime.now().toUtc().toIso8601String(),
      'vehicle': <String, dynamic>{
        'plate_number': '',
        'brand': '',
        'color': '',
        'type': '',
      },
      'status': 'active',
    };
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

  static void _throwIfBadResponse(Response<dynamic> res, String context) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      if (res.data is Map<String, dynamic>) return;
      if (res.data is Map) return;
      throw TransactionsApiException(
        '$context: expected JSON object, got ${res.data.runtimeType}',
        statusCode: code,
      );
    }
    final msg = _messageFromBody(res.data) ?? res.statusMessage ?? 'HTTP $code';
    throw TransactionsApiException('$context: $msg', statusCode: code);
  }

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw TransactionsApiException(
      'Expected JSON object, got ${data.runtimeType}',
    );
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final msg = m['message'] ?? m['detail'] ?? m['error'];
      return msg?.toString();
    }
    return null;
  }

  static TransactionsApiException _fromDio(DioException e, String context) {
    final code = e.response?.statusCode;
    final msg =
        _messageFromBody(e.response?.data) ??
        e.message ??
        e.type.name;
    return TransactionsApiException('$context: $msg', statusCode: code);
  }
}
