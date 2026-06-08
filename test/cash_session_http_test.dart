import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/services/cash_session_http.dart';

void main() {
  test('detects already-open cash session from 409', () {
    expect(isCashSessionAlreadyOpenResponse(409, null), isTrue);
  });

  test('detects already-open cash session from message body', () {
    expect(
      isCashSessionAlreadyOpenResponse(
        400,
        {'message': 'Cash session is already open'},
      ),
      isTrue,
    );
  });

  test('does not treat unrelated 400 as already open', () {
    expect(
      isCashSessionAlreadyOpenResponse(400, {'message': 'Invalid opening balance'}),
      isFalse,
    );
  });
}
