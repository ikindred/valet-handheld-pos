import 'package:flutter_test/flutter_test.dart';
import 'package:valet_handheld_pos/core/time/check_in_time_resolution.dart';
import 'package:valet_handheld_pos/core/time/philippine_time.dart';

void main() {
  group('CheckInTimeResolution', () {
    test('restores parking day when time_in matches checkout on next day', () {
      final startDate = PhilippineTime.parkingDateUnixSeconds(
        DateTime(2026, 3, 24, 20, 0),
      );
      // Mar 25 8:00 AM PH = UTC Mar 25 00:00.
      final checkoutUnix =
          DateTime.utc(2026, 3, 25).millisecondsSinceEpoch ~/ 1000;

      final resolved = CheckInTimeResolution.resolveWallIsoFromTransaction({
        'start_date': startDate,
        'checkout_timestamp': checkoutUnix,
        // Server wrongly stamped check-in on checkout calendar day at 8pm.
        'time_in': '2026-03-25T20:00:00.000',
      });

      final ph = PhilippineTime.parseWallIso(resolved);
      expect(ph.year, 2026);
      expect(ph.month, 3);
      expect(ph.day, 24);
      expect(ph.hour, 20);
    });

    test('uses local fallback clock when only start_date is present', () {
      final startDate = PhilippineTime.parkingDateUnixSeconds(
        DateTime(2026, 3, 24, 0, 0),
      );

      final resolved = CheckInTimeResolution.resolveWallIsoFromTransaction(
        {'start_date': startDate},
        localFallback: '2026-03-24T20:15:30.000',
      );

      final ph = PhilippineTime.parseWallIso(resolved);
      expect(ph.day, 24);
      expect(ph.hour, 20);
      expect(ph.minute, 15);
    });

    test('keeps time_in when check-in and checkout share calendar day', () {
      final startDate = PhilippineTime.parkingDateUnixSeconds(
        DateTime(2026, 3, 24, 10, 0),
      );
      final checkoutUnix =
          DateTime.utc(2026, 3, 24, 10, 0).millisecondsSinceEpoch ~/ 1000;

      final resolved = CheckInTimeResolution.resolveWallIsoFromTransaction({
        'start_date': startDate,
        'checkout_timestamp': checkoutUnix,
        'time_in': '2026-03-24T10:30:00.000',
      });

      final ph = PhilippineTime.parseWallIso(resolved);
      expect(ph.day, 24);
      expect(ph.hour, 10);
      expect(ph.minute, 30);
    });
  });
}
