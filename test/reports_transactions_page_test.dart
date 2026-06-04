import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_format.dart';
import 'package:valet_handheld_pos/features/reports/domain/reports_transactions_page.dart';

void main() {
  test('ReportsTransactionsPage.fromJson parses paginated payload', () {
    final page = ReportsTransactionsPage.fromJson({
      'total': 42,
      'page': 1,
      'limit': 20,
      'totalPages': 3,
      'data': [
        {
          'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          'ticket_number': 'TKT-0123',
          'vr_no': 'VR-2026-00142',
          'plate_number': 'ABC1234',
          'vehicle': 'Toyota Vios',
          'color': 'White',
          'time_in': '08:00',
          'duration_minutes': 150,
          'duration_display': '1h 20m',
          'slot': 'A-12',
          'status': 'active',
          'amount': 150,
        },
      ],
    });

    expect(page.total, 42);
    expect(page.page, 1);
    expect(page.totalPages, 3);
    expect(page.rows, hasLength(1));
    final row = page.rows.first;
    expect(row.ticketId, 'TKT-0123');
    expect(row.serverTransactionId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
    expect(row.plate, 'ABC1234');
    expect(row.vrNo, 'VR-2026-00142');
    expect(row.vehicle, 'Toyota Vios · White');
    expect(row.timeInDisplay, '08:00');
    expect(row.durationDisplay, '1h 20m');
    expect(row.status, ReportsTicketRowStatus.parked);
    expect(row.detailId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
  });
}
