import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/data/remote/check_in_http.dart';

void main() {
  test('detects VR conflict from 409 message', () {
    expect(
      isVrNumberAlreadyExistsResponse(
        409,
        {'message': 'VR number EP432624 already exists'},
      ),
      isTrue,
    );
  });

  test('does not treat unrelated 409 as VR conflict', () {
    expect(
      isVrNumberAlreadyExistsResponse(
        409,
        {'message': 'Vehicle is already checked in'},
      ),
      isFalse,
    );
  });

  test('requires 409 status', () {
    expect(
      isVrNumberAlreadyExistsResponse(
        400,
        {'message': 'VR number EP432624 already exists'},
      ),
      isFalse,
    );
  });
}
