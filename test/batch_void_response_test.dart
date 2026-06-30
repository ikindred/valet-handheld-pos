import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/batch_void_payload.dart';
import 'package:valet_handheld_pos/features/check_in/models/batch_check_in_response.dart';

void main() {
  test('voidApiItem builds batch void request item', () {
    final item = voidApiItem(
      id: 'EXP-0001',
      voidReason: 'Wrong amount',
    );

    expect(item['id'], 'EXP-0001');
    expect(item['void_reason'], 'Wrong amount');
  });

  test('parses batch void response with mixed results', () {
    final response = BatchCheckInResponse.fromJson(<String, dynamic>{
      'results': [
        <String, dynamic>{
          'index': 0,
          'status': 'success',
          'id': 'EXP-0001',
          'data': <String, dynamic>{
            'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            'ticket_number': 'EXP-0001',
            'status': 'void',
            'void_reason': 'Entered wrong amount.',
            'voided_at': '2026-06-30T14:30:00.000Z',
          },
        },
        <String, dynamic>{
          'index': 1,
          'status': 'error',
          'id': 'EXP-9999',
          'error': <String, dynamic>{
            'status_code': 409,
            'message': 'Ticket is already voided',
          },
        },
      ],
      'summary': <String, dynamic>{
        'total': 2,
        'succeeded': 1,
        'failed': 1,
      },
    });

    expect(response.summary.total, 2);
    expect(response.summary.succeeded, 1);
    expect(response.summary.failed, 1);
    expect(response.results[0].isSuccess, isTrue);
    expect(response.results[0].ticketNumber, 'EXP-0001');
    expect(response.results[0].serverTransactionId, isNotEmpty);
    expect(response.results[1].isFailed, isTrue);
    expect(response.results[1].error?.isAlreadyVoidedConflict, isTrue);
  });

  test('stubForVoids returns success for each void item', () {
    final response = BatchCheckInResponse.stubForVoids([
      voidApiItem(id: 'TKT-260630-ABCD-120000', voidReason: 'Duplicate'),
      voidApiItem(id: 'EXP-0002'),
    ]);

    expect(response.results.length, 2);
    expect(response.results.every((r) => r.isSuccess), isTrue);
    expect(response.summary.succeeded, 2);
  });
}
