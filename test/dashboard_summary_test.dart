import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/remote/dashboard_summary.dart';

void main() {
  test('DashboardSummary.fromResponseData parses shift KPIs and recent list', () {
    final summary = DashboardSummary.fromResponseData({
      'shift_id': 'shift-uuid',
      'total_vehicles_in': 14,
      'checked_out_total': 12,
      'active_slots': 38,
      'total_slots': 120,
      'recent_transactions': [
        {
          'id': 'ticket-uuid',
          'ticket_number': 'TKT-0123',
          'plate_number': 'ABC1234',
          'status': 'COMPLETED',
          'amount': 150,
          'time_out': '2026-05-08T02:30:00.000Z',
        },
      ],
    });

    expect(summary, isNotNull);
    expect(summary!.totalVehiclesIn, 14);
    expect(summary.checkedOutTotal, 12);
    expect(summary.activeSlots, 38);
    expect(summary.totalSlots, 120);
    expect(summary.recent, hasLength(1));
    expect(summary.recent.first.plateNumber, 'ABC1234');

    final row = summary.recent.first.toRecentRow();
    expect(row.isCheckedOut, isTrue);
    expect(row.plate, 'ABC1234');
  });
}
