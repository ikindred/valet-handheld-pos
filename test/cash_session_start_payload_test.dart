import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/cash_session_start_payload.dart';

void main() {
  test('buildCashSessionStartBody matches mobile API', () {
    expect(
      buildCashSessionStartBody(
        openingBalance: 1000,
        timestampUtcIso: '2026-05-16T08:00:00.000Z',
        notes: 'float from supervisor',
      ),
      <String, dynamic>{
        'openingBalance': 1000,
        'timestamp': '2026-05-16T08:00:00.000Z',
        'notes': 'float from supervisor',
      },
    );
  });

  test('buildCashSessionStartBody defaults notes to empty string', () {
    final body = buildCashSessionStartBody(
      openingBalance: 500,
      timestampUtcIso: '2026-05-16T08:00:00.000Z',
    );
    expect(body['notes'], '');
  });

  test('cashSessionStartTimestamp normalizes to UTC ISO', () {
    expect(
      cashSessionStartTimestamp(
        openedAtIso: '2026-05-16T16:00:00.000+08:00',
      ),
      '2026-05-16T08:00:00.000Z',
    );
  });
}
