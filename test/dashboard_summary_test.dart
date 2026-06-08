import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/remote/dashboard_summary.dart';

void main() {
  test('DashboardSummary.fromResponseData parses shift KPIs and recent list', () {
    final summary = DashboardSummary.fromResponseData({
      'shift_id': 'shift-uuid',
      'total_vehicles_in': 14,
      'checked_out_total': 12,
      'active_slots': 38,
      'remaining_count': 82,
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
    expect(summary.remainingCount, 82);
    expect(summary.totalSlots, 120);
    expect(summary.recent, hasLength(1));
    expect(summary.recent.first.plateNumber, 'ABC1234');

    final row = summary.recent.first.toRecentRow();
    expect(row.isCheckedOut, isTrue);
    expect(row.plate, 'ABC1234');
    expect(row.line1, '—');
    expect(row.line2, contains('Out at'));
    expect(row.line2, contains('₱150.00'));
  });

  test('checked-out recent row shows cash tendered when present', () {
    final row = DashboardSummaryRecent.fromJson({
      'id': 'ticket-uuid',
      'ticket_number': 'TKT-0123',
      'plate_number': 'ABC1234',
      'status': 'COMPLETED',
      'amount': 150,
      'cash_tendered': 200,
      'change': {},
      'time_out': '2026-05-08T02:30:00.000Z',
    })!.toRecentRow();

    expect(row.line2, contains('Cash'));
    expect(row.line2, contains('₱200.00'));
    expect(row.line2, contains('Chg'));
    expect(row.line2, contains('₱50.00'));
  });

  test('toRecentRow uses vehicle and slot fields when present', () {
    final row = DashboardSummaryRecent.fromJson({
      'id': 'ticket-uuid',
      'ticket_number': 'TKT-0123',
      'plate_number': 'ABC 1234',
      'status': 'ACTIVE',
      'time_in': '2026-05-08T01:32:00.000Z',
      'vehicle': {'brand': 'Toyota', 'model': 'Vios', 'color': 'White'},
      'parking': {'slot': 'B-04'},
    })!.toRecentRow();

    expect(row.isCheckedOut, isFalse);
    expect(row.line1, 'Toyota Vios · White');
    expect(row.line2, contains('In at'));
    expect(row.line2, contains('Slot B-04'));
    expect(row.line2, isNot(contains('TKT-0123')));
  });

  test('checkoutCountsByVehicleRateKey groups completed recent rows', () {
    final summary = DashboardSummary.fromResponseData({
      'checked_out_total': 3,
      'recent_transactions': [
        {
          'id': '1',
          'ticket_number': 'TKT-1',
          'status': 'COMPLETED',
          'vehicle': {'type': 'sedan'},
        },
        {
          'id': '2',
          'ticket_number': 'TKT-2',
          'status': 'COMPLETED',
          'vehicle': {'type': 'suv'},
        },
        {
          'id': '3',
          'ticket_number': 'TKT-3',
          'status': 'COMPLETED',
          'vehicle_type': 'suv',
        },
        {
          'id': '4',
          'ticket_number': 'TKT-4',
          'status': 'ACTIVE',
          'vehicle': {'type': 'van'},
        },
      ],
    });

    expect(summary, isNotNull);
    expect(summary!.checkoutCountsByVehicleRateKey(), {
      'sedan': 1,
      'suv': 2,
    });
  });

  test('remaining_count falls back to total_slots minus active_slots', () {
    final summary = DashboardSummary.fromResponseData({
      'total_vehicles_in': 2,
      'active_slots': 2,
      'total_slots': 30,
    });

    expect(summary, isNotNull);
    expect(summary!.remainingCount, 28);
  });
}
