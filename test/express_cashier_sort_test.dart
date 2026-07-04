import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/features/express_cashier/state/express_cashier_state.dart';

ExpressCashierTransaction _tx({
  required String ticketId,
  required String checkInAt,
  bool includedInCloseCash = false,
}) {
  return ExpressCashierTransaction(
    ticketId: ticketId,
    plateNumber: 'ABC123',
    amount: 100,
    syncStatus: 'synced',
    status: 'completed',
    checkInAt: checkInAt,
    createdAt: checkInAt,
    includedInCloseCash: includedInCloseCash,
  );
}

void main() {
  test('sortedForDisplay puts current shift first, newest first within group',
      () {
    final sorted = ExpressCashierTransaction.sortedForDisplay([
      _tx(ticketId: 'closed-old', checkInAt: '2026-07-04T08:00:00.000Z', includedInCloseCash: true),
      _tx(ticketId: 'active-old', checkInAt: '2026-07-04T10:00:00.000Z'),
      _tx(ticketId: 'closed-new', checkInAt: '2026-07-04T12:00:00.000Z', includedInCloseCash: true),
      _tx(ticketId: 'active-new', checkInAt: '2026-07-04T14:00:00.000Z'),
    ]);

    expect(
      sorted.map((t) => t.ticketId).toList(),
      [
        'active-new',
        'active-old',
        'closed-new',
        'closed-old',
      ],
    );
  });
}
