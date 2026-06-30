import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/reports_row_cache_mapper.dart';
import 'package:valet_handheld_pos/data/services/reports_today_row_mapper.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_format.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_models.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_today_response.dart';

void main() {
  test('ReportsTodayResponse parses currently_parked rows', () {
    final response = ReportsTodayResponse.fromJson(<String, dynamic>{
      'shift_id': 'shift-1',
      'total_transactions': 12,
      'currently_parked': [
        <String, dynamic>{
          'id': 'srv-1',
          'ticket_number': 'EXP-0001',
          'plate_number': 'ABC1234',
          'vehicle': 'Toyota Vios',
          'time_in': '08:00',
          'time_out': '10:30',
          'status': 'completed',
          'amount': 150,
          'is_express': true,
        },
      ],
      'alerts': [
        <String, dynamic>{
          'type': 'warning',
          'message': 'TKT-0042 parked over 3 hours',
        },
      ],
    });

    expect(response.shiftId, 'shift-1');
    expect(response.totalTransactions, 12);
    expect(response.currentlyParked, hasLength(1));
    expect(response.alerts, hasLength(1));
  });

  test('ReportsTodayRowMapper normalizes clock times and express flags', () {
    final mapped = ReportsTodayRowMapper.toServerCacheJson(
      <String, dynamic>{
        'id': 'srv-1',
        'ticket_number': 'EXP-0001',
        'plate_number': 'ABC1234',
        'vehicle': 'Toyota Vios',
        'slot': 'A-12',
        'time_in': '08:00',
        'time_out': '10:30',
        'status': 'completed',
        'amount': 150,
        'is_express': true,
      },
      markExpress: true,
    );

    expect(mapped['is_express_cashier'], isTrue);
    expect(mapped['vehicle'], isA<Map>());
    expect((mapped['vehicle'] as Map)['plate_number'], 'ABC1234');
    expect(mapped['parking'], isA<Map>());
    expect(mapped['time_in'], contains('T08:00:00'));
    expect(mapped['time_out'], contains('T10:30:00'));
  });

  test('ReportsRowCacheMapper maps completed express reports row', () {
    final ph = DateTime(2026, 6, 30, 9, 15);
    final mapped = ReportsRowCacheMapper.fromReportsRow(
      ReportsTicketRow(
        ticketId: 'EXP-0001',
        serverTransactionId: 'srv-1',
        plate: 'ABC1234',
        vrNo: 'EP123456',
        vehicle: 'Toyota Vios',
        timeIn: ph,
        duration: Duration.zero,
        slot: '—',
        status: ReportsTicketRowStatus.checkedOut,
        fee: 136,
        isVoided: false,
      ),
      markExpress: true,
    );

    expect(mapped['id'], 'srv-1');
    expect(mapped['ticket_number'], 'EXP-0001');
    expect(mapped['status'], 'completed');
    expect(mapped['is_express_cashier'], isTrue);
    expect(mapped['amount'], 136);
  });
}
