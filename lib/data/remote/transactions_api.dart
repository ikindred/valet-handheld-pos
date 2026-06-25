import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../features/check_in/models/check_in_response.dart';
import '../../features/check_out/models/check_out_response.dart';
import '../../features/check_out/models/checkout_preview_rates.dart';
import '../../features/check_out/models/checkout_preview_response.dart';
import '../../features/reports/domain/reports_transactions_page.dart';
import 'api_error_message.dart';
import 'check_in_http.dart';
import 'check_in_exceptions.dart';
import 'checkout_exceptions.dart';

/// Thrown by [TransactionsApi] on HTTP errors or bad response bodies.
class TransactionsApiException implements Exception {
  TransactionsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode != null
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
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _parseList(res.data);
  }

  /// GET [AppConfig.reportsTransactions] — mobile Reports tab (paginated, filtered).
  ///
  /// Requires open shift (Bearer token). Query: `search`, `status`, `date_from`,
  /// `date_to` (`YYYY-MM-DD`, inclusive range), `sort`, `limit`, `page`.
  Future<ReportsTransactionsPage> fetchReportsTransactions({
    required String token,
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
    String sort = 'desc',
    int limit = 20,
    int page = 1,
  }) async {
    if (AppConfig.useStubApi) {
      return ReportsTransactionsPage(
        total: 1,
        page: 1,
        limit: limit,
        totalPages: 1,
        rows: [
          ReportsTicketRowMapper.fromApi({
            'id': '00000000-0000-4000-8000-000000000099',
            'ticket_number': 'TKT-0123',
            'plate_number': 'ABC1234',
            'vehicle': 'Toyota Vios',
            'color': 'White',
            'time_in': '8:00 AM',
            'duration_display': '1h 20m',
            'duration_minutes': 80,
            'slot': 'A-12',
            'status': 'active',
            'amount': 150,
          }),
        ],
      );
    }
    final params = <String, dynamic>{
      'limit': limit,
      'page': page,
      'sort': sort,
    };
    final q = search?.trim();
    if (q != null && q.isNotEmpty) params['search'] = q;
    final st = status?.trim();
    if (st != null && st.isNotEmpty) params['status'] = st;
    final from = dateFrom?.trim();
    if (from != null && from.isNotEmpty) params['date_from'] = from;
    final to = dateTo?.trim();
    if (to != null && to.isNotEmpty) params['date_to'] = to;

    try {
      final res = await _dio.get<dynamic>(
        AppConfig.reportsTransactions,
        queryParameters: params,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwIfBadResponse(res, 'GET reports/transactions');
      return ReportsTransactionsPage.fromJson(res.data);
    } on DioException catch (e) {
      throw _fromDio(e, 'GET reports/transactions');
    }
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

  /// POST [AppConfig.checkoutPreviewUrl] — persist checkout payload + refresh preview.
  Future<CheckoutPreviewResponse> postCheckoutPreview({
    required String token,
    required String ticketId,
    required String driverOut,
    required List<Map<String, dynamic>> conditionCheckout,
  }) async {
    final id = ticketId.trim();
    if (id.isEmpty) {
      throw CheckoutApiException('Transaction id is empty.');
    }
    if (AppConfig.useStubApi) {
      return _stubCheckoutPreview(ticketId: id);
    }
    final body = <String, dynamic>{
      'driver_out': driverOut,
      'condition_checkout': conditionCheckout,
      'status': 'active',
    };
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.checkoutPreviewUrl(id),
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwCheckoutIfBad(res, 'POST checkout-preview $id');
      return CheckoutPreviewResponse.fromResponseBody(_asJsonMap(res.data));
    } on DioException catch (e) {
      _rethrowCheckoutDio(e, 'POST checkout-preview $id');
    }
  }

  /// GET [AppConfig.checkoutPreviewUrl] — server pricing + condition comparison.
  Future<CheckoutPreviewResponse> getCheckoutPreview({
    required String token,
    required String ticketId,
  }) async {
    final id = ticketId.trim();
    if (id.isEmpty) {
      throw CheckoutApiException('Transaction id is empty.');
    }
    if (AppConfig.useStubApi) {
      return _stubCheckoutPreview(ticketId: id);
    }
    try {
      final res = await _dio.get<dynamic>(
        AppConfig.checkoutPreviewUrl(id),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwCheckoutIfBad(res, 'GET checkout-preview $id');
      return CheckoutPreviewResponse.fromResponseBody(_asJsonMap(res.data));
    } on DioException catch (e) {
      _rethrowCheckoutDio(e, 'GET checkout-preview $id');
    }
  }

  /// POST [AppConfig.checkOutUrl] — finalize checkout.
  ///
  /// Server computes `preview` in the response; do not echo GET checkout-preview
  /// fields (`release_summary`, `ticket`, `condition_comparison`) in the body.
  Future<CheckOutResponse> submitCheckOut({
    required String token,
    required String ticketId,
    required double amount,
    required String timeOut,
    required bool isOvernight,
    required bool ticketLost,
    double? cashTendered,
    List<Map<String, dynamic>>? conditionCheckout,
    Map<String, dynamic>? appliedRate,
  }) async {
    final id = ticketId.trim();
    if (id.isEmpty) {
      throw CheckoutApiException('Transaction id is empty.');
    }
    if (AppConfig.useStubApi) {
      return CheckOutResponse(
        invoiceNumber: 'INV-STUB-001',
        transactionId: id,
        status: 'completed',
        total: amount,
      );
    }
    final body = <String, dynamic>{
      'amount': amount,
      'time_out': timeOut,
      'is_overnight': isOvernight,
      'ticket_lost': ticketLost,
      // Mobile-computed totals only at top level. Do not echo GET preview blocks
      // (`release_summary`, `ticket`, `condition_comparison`) — server rejects them.
      'preview': <String, dynamic>{},
      'condition_checkout': conditionCheckout ?? const [],
    };
    if (cashTendered != null && cashTendered > 0.009) {
      body['cash_tendered'] = cashTendered;
    }
    if (appliedRate != null && appliedRate.isNotEmpty) {
      body['applied_rate'] = appliedRate;
    }
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.checkOutUrl(id),
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwCheckoutIfBad(res, 'POST check-out $id');
      return CheckOutResponse.fromResponseBody(_asJsonMap(res.data));
    } on DioException catch (e) {
      _rethrowCheckoutDio(e, 'POST check-out $id');
    }
  }

  /// POST [AppConfig.checkInUrl] — full check-in (multipart).
  Future<CheckInResponse> submitCheckIn({
    required String token,
    required String ticketNumber,
    required String slotId,
    required String contactNumber,
    required String valetType,
    required File signatureFile,
    required Map<String, dynamic> vehicle,
    required List<String> belongings,
    required List<Map<String, dynamic>> damages,
    String? customerName,
    String? driverIn,
    String? driverOut,
    String? notes,
    String? vrNo,
    bool voidRequested = false,
    String? voidReason,
  }) async {
    if (AppConfig.useStubApi) {
      return CheckInResponse(
        id: '00000000-0000-4000-8000-000000000099',
        ticketNumber: 'TKT-0001',
        qrCode: 'TKT-0001',
      );
    }

    final fields = <MapEntry<String, String>>[
      MapEntry('ticket_number', ticketNumber.trim()),
      MapEntry('slot_id', slotId.trim()),
      MapEntry('contact_number', contactNumber),
      MapEntry('valet_type', valetType),
      MapEntry('vehicle', jsonEncode(vehicle)),
      MapEntry('belongings', jsonEncode(belongings)),
      MapEntry('damages', jsonEncode(damages)),
    ];

    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) {
      fields.add(MapEntry('customer_name', name));
    }
    final driver = driverIn?.trim();
    if (driver != null && driver.isNotEmpty) {
      fields.add(MapEntry('driver_in', driver));
    }
    final driverOutName = driverOut?.trim();
    if (driverOutName != null && driverOutName.isNotEmpty) {
      fields.add(MapEntry('driver_out', driverOutName));
    }
    final note = notes?.trim();
    if (note != null && note.isNotEmpty) {
      fields.add(MapEntry('notes', note));
    }
    final vr = vrNo?.trim();
    if (vr != null && vr.isNotEmpty) {
      fields.add(MapEntry('vr_no', vr));
    }
    if (voidRequested) {
      fields.add(const MapEntry('void_requested', 'true'));
      final reason = voidReason?.trim();
      if (reason != null && reason.isNotEmpty) {
        fields.add(MapEntry('void_reason', reason));
      }
    }

    final form = FormData.fromMap({
      for (final e in fields) e.key: e.value,
      'signature': await MultipartFile.fromFile(
        signatureFile.path,
        filename: 'signature.png',
        contentType: DioMediaType.parse('image/png'),
      ),
    });

    try {
      final res = await _dio.post<dynamic>(
        AppConfig.checkInUrl,
        data: form,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
          contentType: 'multipart/form-data',
        ),
      );

      final code = res.statusCode ?? 0;
      if (code == 201) {
        final body = _checkInBodyMap(res.data);
        return CheckInResponse.fromJson(body);
      }
      if (code == 400) {
        throw CheckInValidationException(
          messageFromResponseData(res.data) ?? 'Invalid check-in data.',
        );
      }
      if (code == 401) {
        throw LoginApiFailure(
          messageFromResponseData(res.data) ?? 'Unauthorized.',
        );
      }
      if (code == 409) {
        if (isVrNumberAlreadyExistsResponse(code, res.data)) {
          throw VrNumberConflictOnServerException(
            messageFromResponseData(res.data),
          );
        }
        throw VehicleAlreadyCheckedInException();
      }
      throw CheckInApiException(
        messageFromResponseData(res.data) ?? res.statusMessage ?? 'HTTP $code',
        statusCode: code,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        rethrow;
      }
      final code = e.response?.statusCode;
      if (code == 400) {
        throw CheckInValidationException(
          messageFromResponseData(e.response?.data) ?? 'Invalid check-in data.',
        );
      }
      if (code == 401) {
        throw LoginApiFailure(
          messageFromResponseData(e.response?.data) ?? 'Unauthorized.',
        );
      }
      if (code == 409) {
        if (isVrNumberAlreadyExistsResponse(code, e.response?.data)) {
          throw VrNumberConflictOnServerException(
            messageFromResponseData(e.response?.data),
          );
        }
        throw VehicleAlreadyCheckedInException();
      }
      throw CheckInApiException(
        messageFromResponseData(e.response?.data) ??
            e.message ??
            'Check-in failed',
        statusCode: code,
      );
    }
  }

  /// POST [AppConfig.checkInUrl] — express cashier manual ticketing (minimal multipart).
  Future<CheckInResponse> submitExpressCheckIn({
    required String token,
    required String ticketNumber,
    required String plateNumber,
    required double amount,
    required String vrNo,
    String? driverIn,
    String? driverOut,
  }) async {
    if (AppConfig.useStubApi) {
      return CheckInResponse(
        id: '00000000-0000-4000-8000-000000000099',
        ticketNumber: ticketNumber.trim(),
        qrCode: ticketNumber.trim(),
      );
    }

    final plate = plateNumber.trim();
    final fields = <MapEntry<String, String>>[
      MapEntry('ticket_number', ticketNumber.trim()),
      // NestJS multipart expects nested keys as vehicle[plate_number], not a
      // top-level plate_number. Keep JSON vehicle too for the same parser as
      // full check-in.
      MapEntry('vehicle[plate_number]', plate),
      MapEntry(
        'vehicle',
        jsonEncode(<String, dynamic>{'plate_number': plate}),
      ),
      MapEntry('amount', amount.toStringAsFixed(2)),
      const MapEntry('express_cashier', 'true'),
      MapEntry('vr_no', vrNo.trim()),
    ];
    final driverInName = driverIn?.trim();
    if (driverInName != null && driverInName.isNotEmpty) {
      fields.add(MapEntry('driver_in', driverInName));
    }
    final driverOutName = driverOut?.trim();
    if (driverOutName != null && driverOutName.isNotEmpty) {
      fields.add(MapEntry('driver_out', driverOutName));
    }

    final form = FormData.fromMap({for (final e in fields) e.key: e.value});

    try {
      final res = await _dio.post<dynamic>(
        AppConfig.checkInUrl,
        data: form,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
          contentType: 'multipart/form-data',
        ),
      );

      final code = res.statusCode ?? 0;
      if (code == 201) {
        final body = _checkInBodyMap(res.data);
        return CheckInResponse.fromJson(body);
      }
      if (code == 400) {
        throw CheckInValidationException(
          messageFromResponseData(res.data) ?? 'Invalid check-in data.',
        );
      }
      if (code == 401) {
        throw LoginApiFailure(
          messageFromResponseData(res.data) ?? 'Unauthorized.',
        );
      }
      if (code == 409) {
        if (isVrNumberAlreadyExistsResponse(code, res.data)) {
          throw VrNumberConflictOnServerException(
            messageFromResponseData(res.data),
          );
        }
        throw VehicleAlreadyCheckedInException();
      }
      throw CheckInApiException(
        messageFromResponseData(res.data) ?? res.statusMessage ?? 'HTTP $code',
        statusCode: code,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        rethrow;
      }
      final code = e.response?.statusCode;
      if (code == 400) {
        throw CheckInValidationException(
          messageFromResponseData(e.response?.data) ?? 'Invalid check-in data.',
        );
      }
      if (code == 401) {
        throw LoginApiFailure(
          messageFromResponseData(e.response?.data) ?? 'Unauthorized.',
        );
      }
      if (code == 409) {
        if (isVrNumberAlreadyExistsResponse(code, e.response?.data)) {
          throw VrNumberConflictOnServerException(
            messageFromResponseData(e.response?.data),
          );
        }
        throw VehicleAlreadyCheckedInException();
      }
      throw CheckInApiException(
        messageFromResponseData(e.response?.data) ??
            e.message ??
            'Check-in failed',
        statusCode: code,
      );
    }
  }

  /// PATCH [AppConfig.transactionPatchUrl] — partial update for driver fields.
  Future<void> patchTransactionDrivers({
    required String token,
    required String ticketId,
    String? driverIn,
    String? driverOut,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) throw TransactionsApiException('Ticket id is empty.');
    if (AppConfig.useStubApi) return;

    final body = <String, dynamic>{};
    final inName = driverIn?.trim();
    if (inName != null && inName.isNotEmpty) {
      body['driver_in'] = inName;
    }
    final outName = driverOut?.trim();
    if (outName != null && outName.isNotEmpty) {
      body['driver_out'] = outName;
    }
    if (body.isEmpty) return;

    try {
      final res = await _dio.patch<dynamic>(
        AppConfig.transactionPatchUrl(tid),
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwPlateUpdateIfBad(res, tid);
    } on DioException catch (e) {
      throw _fromDio(e, 'PATCH transaction $tid');
    }
  }

  static Map<String, dynamic> _checkInBodyMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return _unwrapTransaction(data);
    }
    if (data is Map) {
      return _unwrapTransaction(Map<String, dynamic>.from(data));
    }
    throw CheckInApiException('Expected JSON object, got ${data.runtimeType}');
  }

  /// PATCH [AppConfig.transactionPatchUrl] — partial update; only sends `vehicle.plate_number`.
  Future<void> patchVehiclePlate({
    required String token,
    required String ticketId,
    required String plateNumber,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) throw TransactionsApiException('Ticket id is empty.');
    if (AppConfig.useStubApi) return;
    final body = <String, dynamic>{
      'vehicle': <String, dynamic>{'plate_number': plateNumber.trim()},
    };
    try {
      final res = await _dio.patch<dynamic>(
        AppConfig.transactionPatchUrl(tid),
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      _throwPlateUpdateIfBad(res, tid);
    } on DioException catch (e) {
      throw _fromDio(e, 'PATCH transaction $tid');
    }
  }

  /// Specialised 400 handler for plate-update PATCH.
  ///
  /// The server may return a list of "property X should not exist" errors when
  /// its validation runs against the merged stored transaction instead of just
  /// the incoming patch body. Surface a single, readable message in that case.
  static void _throwPlateUpdateIfBad(Response<dynamic> res, String tid) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    if (code == 400) {
      final raw = _messageFromBody(res.data);
      // Detect the "server merges existing data before validation" pattern:
      // the response lists known transaction fields as "should not exist".
      final isMergeValidationBug =
          raw != null && raw.contains('should not exist');
      if (isMergeValidationBug) {
        throw TransactionsApiException(
          'Plate update is temporarily unavailable — the server rejected the '
          'request (validation conflict). Please try again or contact support.',
          statusCode: code,
        );
      }
      throw TransactionsApiException(
        raw ?? 'Invalid plate number.',
        statusCode: code,
      );
    }
    final msg = _messageFromBody(res.data) ?? res.statusMessage ?? 'HTTP $code';
    throw TransactionsApiException(
      'PATCH transaction $tid: $msg',
      statusCode: code,
    );
  }

  /// POST [AppConfig.ticketVoidUrl] — void active ticket immediately.
  Future<Map<String, dynamic>> requestVoid({
    required String token,
    required String ticketId,
    String? reason,
  }) async {
    final tid = ticketId.trim();
    if (tid.isEmpty) {
      throw TransactionsApiException('Ticket id is empty.');
    }
    if (AppConfig.useStubApi) {
      return <String, dynamic>{
        'id': tid,
        'status': 'VOID',
        'voidReason': reason ?? 'Voided',
      };
    }
    final body = <String, dynamic>{};
    final r = reason?.trim();
    if (r != null && r.isNotEmpty) {
      body['reason'] = r;
    }
    try {
      final res = await _dio.post<dynamic>(
        AppConfig.ticketVoidUrl(tid),
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return _asJsonMap(res.data);
      }
      final msg =
          _messageFromBody(res.data) ?? res.statusMessage ?? 'HTTP $code';
      throw TransactionsApiException(msg, statusCode: code);
    } on DioException catch (e) {
      throw _fromDio(e, 'POST ticket void $tid');
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
      'status': 'completed',
      'amount': 150,
      'cash_tendered': 200,
      'change': {},
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
          if (e is Map<String, dynamic>)
            e
          else if (e is Map)
            Map<String, dynamic>.from(e),
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
    if (data is Map<String, dynamic>) {
      return _unwrapTransaction(data);
    }
    if (data is Map) {
      return _unwrapTransaction(Map<String, dynamic>.from(data));
    }
    throw TransactionsApiException(
      'Expected JSON object, got ${data.runtimeType}',
    );
  }

  static Map<String, dynamic> _unwrapTransaction(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    // Checkout-preview / check-out envelopes: keep siblings (preview, compute).
    if (root.containsKey('preview') ||
        root.containsKey('compute') ||
        root.containsKey('release_summary')) {
      return root;
    }

    for (final key in const ['transaction', 'result']) {
      final inner = root[key];
      if (inner is Map<String, dynamic>) return inner;
      if (inner is Map) return Map<String, dynamic>.from(inner);
    }
    return root;
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final msg = m['message'] ?? m['detail'] ?? m['error'];
      if (msg is List) {
        return msg.map((e) => e.toString()).join('; ');
      }
      return msg?.toString();
    }
    return null;
  }

  static TransactionsApiException _fromDio(DioException e, String context) {
    final code = e.response?.statusCode;
    final msg = _messageFromBody(e.response?.data) ?? e.message ?? e.type.name;
    return TransactionsApiException('$context: $msg', statusCode: code);
  }

  static void _throwCheckoutIfBad(Response<dynamic> res, String context) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      if (res.data is Map || res.data is Map<String, dynamic>) return;
      throw CheckoutApiException(
        '$context: expected JSON object',
        statusCode: code,
      );
    }
    final msg = _messageFromBody(res.data) ?? res.statusMessage ?? 'HTTP $code';
    throw _checkoutExceptionForStatus(code, msg);
  }

  static Never _checkoutExceptionForStatus(int code, String msg) {
    switch (code) {
      case 400:
        throw CheckOutValidationException(msg);
      case 401:
        throw CheckoutAuthException(msg);
      case 404:
        throw TicketNotFoundException(msg);
      case 409:
        final lower = msg.toLowerCase();
        if (lower.contains('void') || lower.contains('pending')) {
          throw TicketVoidPendingException(msg);
        }
        throw TicketAlreadyCheckedOutException(msg);
      default:
        throw CheckoutApiException(msg, statusCode: code);
    }
  }

  static Never _rethrowCheckoutDio(DioException e, String context) {
    final code = e.response?.statusCode;
    if (code != null) {
      final msg =
          _messageFromBody(e.response?.data) ?? e.message ?? 'HTTP $code';
      _checkoutExceptionForStatus(code, msg);
    }
    throw e;
  }

  static CheckoutPreviewResponse _stubCheckoutPreview({
    required String ticketId,
  }) {
    return CheckoutPreviewResponse(
      transactionId: '00000000-0000-4000-8000-000000000001',
      customerContact: '09171234567',
      belongings: const ['iPad', 'Cellphone / Charger'],
      releaseSummary: const ReleaseSummary(
        plate: 'ABC 1234',
        customer: 'Juan dela Cruz',
        duration: '2h 15m',
      ),
      rates: const CheckoutPreviewRates(
        flatRate: 150,
        succeedingRate: 30,
        overnightFee: 200,
        lostTicketFee: 200,
        overnightStart: '01:30',
        overnightEnd: '05:30',
      ),
      ticket: CheckoutPreviewTicket(
        ticketNumber: ticketId,
        plate: 'ABC 1234',
        vehicleMake: 'Toyota Vios',
        vehicleColor: 'White',
        vehicleType: 'Sedan',
        timeIn: DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        duration: '2h 15m',
        flatRateAmount: 0,
        succeedingRateAmount: 0,
        totalAmount: 0,
      ),
      conditionComparison: const [
        ConditionComparison(
          zone: 'Front Bumper',
          type: 'scratch',
          x: 0.5,
          y: 0.05,
          isNew: true,
        ),
      ],
    );
  }
}
