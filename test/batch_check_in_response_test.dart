import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/check_in/models/batch_check_in_response.dart';

void main() {
  test('parses batch check-in response with mixed results', () {
    final response = BatchCheckInResponse.fromJson(<String, dynamic>{
      'results': [
        <String, dynamic>{
          'index': 0,
          'status': 'success',
          'ticket_number': 'TKT-0042',
          'plate_number': 'ABC1234',
          'vr_no': 'EP432624',
          'server_transaction_id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'transaction': <String, dynamic>{
            'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            'status': 'parked',
          },
        },
        <String, dynamic>{
          'index': 1,
          'status': 'failed',
          'ticket_number': 'TKT-0043',
          'plate_number': 'XYZ9876',
          'vr_no': 'EP432625',
          'error': <String, dynamic>{
            'status_code': 409,
            'code': 'VR_NUMBER_ALREADY_EXISTS',
            'message': 'VR number EP432625 already exists',
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
    expect(response.results[0].serverTransactionId, isNotEmpty);
    expect(response.results[1].isFailed, isTrue);
    expect(response.results[1].error?.isVrConflict, isTrue);
  });

  test('parses live backend envelope with data.transaction and HTTP 201 shape', () {
    final response = BatchCheckInResponse.fromJson(<String, dynamic>{
      'results': [
        <String, dynamic>{
          'index': 0,
          'status': 'success',
          'ticket_number': 'TKT-260626-3EF8-074523',
          'data': <String, dynamic>{
            'invoice_number': 'INV-BR-07-0001',
            'transaction': <String, dynamic>{
              'id': 'b4b4f116-cd34-4d8d-aa9f-bdcccf48127e',
              'ticket_number': 'TKT-260626-3EF8-074523',
              'vr_no': 'EP123206',
              'status': 'completed',
              'vehicle': <String, dynamic>{'plate_number': 'ABC1234'},
            },
          },
        },
      ],
    });

    final result = response.results.single;
    expect(result.isSuccess, isTrue);
    expect(
      result.serverTransactionId,
      'b4b4f116-cd34-4d8d-aa9f-bdcccf48127e',
    );
    expect(result.vrNo, 'EP123206');
    expect(result.plateNumber, 'ABC1234');
  });

  test('parses HTTP 400 batch body with status error and ticket conflict', () {
    final item = BatchCheckInResultItem.fromJson(<String, dynamic>{
      'index': 0,
      'status': 'error',
      'ticket_number': 'TKT-260626-3EF8-074523',
      'error': <String, dynamic>{
        'status_code': 409,
        'message': 'Ticket number TKT-260626-3EF8-074523 already exists',
      },
    });

    expect(item.isFailed, isTrue);
    expect(item.isSuccess, isFalse);
    expect(item.error?.isTicketNumberConflict, isTrue);
    expect(item.error?.isAlreadyOnServerConflict, isTrue);
  });
}
