import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/batch_check_out_payload.dart';
import 'package:valet_handheld_pos/core/time/philippine_time.dart';

void main() {
  test('builds batch checkout item from queued payload', () {
    final item = checkoutQueuePayloadToApiItem(<String, dynamic>{
      'ticket_number': 'TKT-260626-3EF8-081735',
      'server_ticket_id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      'amount': 180,
      'time_out': '2026-03-24T05:47:00.000Z',
      'is_overnight': false,
      'ticket_lost': false,
      'applied_rate': <String, dynamic>{
        'flat_rate': 150,
        'flat_rate_hours': 3,
        'succeeding_rate': 30,
        'overnight_fee': 500,
        'lost_ticket_fee': 200,
        'overnight_start_time': '22:00',
        'overnight_end_time': '05:00',
      },
      'cash_tendered': 200,
      'driver_out': 'Pedro Santos',
      'condition_checkout': <Map<String, dynamic>>[
        <String, dynamic>{
          'zone': 'Front bumper',
          'type': 'scratch',
          'x': 0.05,
          'y': 0.5,
        },
      ],
    });

    expect(item['id'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    expect(item['amount'], 180);
    expect(item['time_out'], isNotEmpty);
    expect(item['is_overnight'], isFalse);
    expect(item['ticket_lost'], isFalse);
    expect(item['cash_tendered'], 200);
    expect(item['driver_out'], 'Pedro Santos');
    expect(item['preview'], isEmpty);
    expect(item['condition_checkout'], hasLength(1));
  });

  test('uses ticket_number as id when server_ticket_id missing', () {
    final item = checkoutQueuePayloadToApiItem(<String, dynamic>{
      'ticket_number': 'TKT-0142',
      'amount': 120,
      'time_out': '2026-03-24T06:00:00.000Z',
      'is_overnight': false,
      'ticket_lost': false,
      'applied_rate': <String, dynamic>{
        'flat_rate': 150,
        'flat_rate_hours': 3,
        'succeeding_rate': 30,
        'overnight_fee': 200,
        'lost_ticket_fee': 200,
        'overnight_start_time': '22:00',
        'overnight_end_time': '05:00',
      },
      'condition_checkout': <Map<String, dynamic>>[],
    });

    expect(item['id'], 'TKT-0142');
    expect(item.containsKey('cash_tendered'), isFalse);
  });

  test('clamps time_out after check-in when queued checkout is earlier', () {
    final item = checkoutQueuePayloadToApiItem(
      <String, dynamic>{
        'ticket_number': 'TKT-0142',
        'server_ticket_id': 'cd1342bd-5b3c-42fd-84c0-5ac64b20b66e',
        'amount': 150,
        'time_out': '2026-06-26T01:31:37.782657Z',
        'is_overnight': false,
        'ticket_lost': false,
        'applied_rate': <String, dynamic>{
          'flat_rate': 150,
          'flat_rate_hours': 3,
          'succeeding_rate': 30,
          'overnight_fee': 200,
          'lost_ticket_fee': 200,
          'overnight_start_time': '22:00',
          'overnight_end_time': '05:00',
        },
        'condition_checkout': <Map<String, dynamic>>[],
      },
      serverTicketIdOverride: 'cd1342bd-5b3c-42fd-84c0-5ac64b20b66e',
      checkInAtIso: '2026-06-26T09:32:15.189',
    );

    expect(item['id'], 'cd1342bd-5b3c-42fd-84c0-5ac64b20b66e');
    final out = DateTime.parse(item['time_out'] as String).toUtc();
    final checkInUtc = PhilippineTime.wallComponentsToUtc(
      PhilippineTime.fromApiIso('2026-06-26T09:32:15.189'),
    );
    expect(out.isAfter(checkInUtc), isTrue);
  });

  test('resolveCheckoutTimeOutForApi bumps before server created_at', () {
    final resolved = resolveCheckoutTimeOutForApi(
      queuedTimeOut: '2026-06-26T04:10:25.121217Z',
      checkInAtRaw: '2026-06-26T12:07:00.000',
      serverTimeInRaw: '2026-06-26T04:10:25.330Z',
    );
    final out = DateTime.parse(resolved).toUtc();
    final serverIn = DateTime.parse('2026-06-26T04:10:25.330Z').toUtc();
    expect(out.isAfter(serverIn), isTrue);
  });

  test('resolveCheckoutTimeOutForApi bumps before check-in wall time', () {
    final resolved = resolveCheckoutTimeOutForApi(
      queuedTimeOut: '2026-06-26T01:31:37.782657Z',
      checkInAtRaw: '2026-06-26T09:32:15.189',
    );
    final out = DateTime.parse(resolved).toUtc();
    final checkInUtc = PhilippineTime.wallComponentsToUtc(
      PhilippineTime.fromApiIso('2026-06-26T09:32:15.189'),
    );
    expect(out.isAfter(checkInUtc), isTrue);
  });
}
