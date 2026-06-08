import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/cash_session_close_payload.dart';

void main() {
  test('buildCashSessionCloseBody omits shift id (resolved from Bearer token)', () {
    expect(
      buildCashSessionCloseBody(
        actualCash: 2430,
        timestampUtcIso: '2026-06-05T16:47:36.568709Z',
        notes: 'end of shift',
      ),
      <String, dynamic>{
        'actualCash': 2430,
        'timestamp': '2026-06-05T16:47:36.568709Z',
        'notes': 'end of shift',
      },
    );
    expect(
      buildCashSessionCloseBody(
        actualCash: 2430,
        timestampUtcIso: '2026-06-05T16:47:36.568709Z',
      ).containsKey('shiftId'),
      isFalse,
    );
  });

  test('buildCashSessionCloseBody defaults notes to empty string', () {
    final body = buildCashSessionCloseBody(
      actualCash: 500,
      timestampUtcIso: '2026-05-16T17:00:00.000Z',
    );
    expect(body['notes'], '');
  });
}
