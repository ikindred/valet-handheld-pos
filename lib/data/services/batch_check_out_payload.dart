import '../../core/time/philippine_time.dart';
import 'batch_check_in_payload.dart';

/// API `time_out` must be after server `time_in`. Offline checkout can be queued
/// before check-in sync, so clamp using check-in wall time and current UTC.
String resolveCheckoutTimeOutForApi({
  required String queuedTimeOut,
  String? checkInAtRaw,
  String? serverTimeInRaw,
}) {
  final queued = DateTime.tryParse(queuedTimeOut.trim())?.toUtc();
  final floors = <DateTime>[PhilippineTime.utcNow()];

  for (final raw in [checkInAtRaw, serverTimeInRaw]) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) continue;
    if (PhilippineTime.isApiInstant(trimmed)) {
      final instant = DateTime.tryParse(trimmed)?.toUtc();
      if (instant != null) floors.add(instant);
    } else {
      floors.add(
        PhilippineTime.wallComponentsToUtc(PhilippineTime.fromApiIso(trimmed)),
      );
    }
  }

  var floor = floors.first;
  for (final candidate in floors.skip(1)) {
    if (candidate.isAfter(floor)) floor = candidate;
  }

  final out = queued ?? floor;
  if (!out.isAfter(floor)) {
    return PhilippineTime.apiIsoInstant(floor.add(const Duration(seconds: 1)));
  }
  return PhilippineTime.apiIsoInstant(out);
}

/// Builds one batch checkout API item from a queued `checkout/finalize` payload.
Map<String, dynamic> checkoutQueuePayloadToApiItem(
  Map<String, dynamic> body, {
  String? serverTicketIdOverride,
  String? checkInAtIso,
  String? serverTimeInRaw,
}) {
  final queuedServerId = body['server_ticket_id']?.toString().trim() ?? '';
  final liveServerId = serverTicketIdOverride?.trim() ?? '';
  final serverId = liveServerId.isNotEmpty ? liveServerId : queuedServerId;
  final ticketNumber = body['ticket_number']?.toString().trim() ?? '';
  final id = serverId.isNotEmpty ? serverId : ticketNumber;
  if (id.isEmpty) {
    throw StateError(
      'Queued checkout/finalize missing id (server_ticket_id or ticket_number)',
    );
  }

  final amountRaw = body['amount'] ?? body['amount_paid'];
  final amount = amountRaw is num
      ? amountRaw.toDouble()
      : double.tryParse('$amountRaw');
  if (amount == null) {
    throw StateError('Queued checkout/finalize missing amount');
  }

  final queuedTimeOut = body['time_out']?.toString().trim() ?? '';
  if (queuedTimeOut.isEmpty) {
    throw StateError('Queued checkout/finalize missing time_out');
  }

  final appliedRate = batchMapField(body['applied_rate']);
  if (appliedRate.isEmpty) {
    throw StateError('Queued checkout/finalize missing applied_rate');
  }

  final item = <String, dynamic>{
    'id': id,
    'amount': amount,
    'time_out': resolveCheckoutTimeOutForApi(
      queuedTimeOut: queuedTimeOut,
      checkInAtRaw: checkInAtIso,
      serverTimeInRaw: serverTimeInRaw,
    ),
    'is_overnight': body['is_overnight'] == true,
    'ticket_lost': body['ticket_lost'] == true,
    'applied_rate': appliedRate,
    'condition_checkout': batchDamageListField(body['condition_checkout']),
    'preview': <String, dynamic>{},
  };

  final cashRaw = body['cash_tendered'] ?? body['cashTendered'];
  if (cashRaw is num) {
    final cash = cashRaw.toDouble();
    if (cash > 0.009) item['cash_tendered'] = cash;
  } else {
    final cash = double.tryParse('$cashRaw');
    if (cash != null && cash > 0.009) item['cash_tendered'] = cash;
  }

  final driverOut = body['driver_out']?.toString().trim() ?? '';
  if (driverOut.isNotEmpty) item['driver_out'] = driverOut;

  return item;
}
