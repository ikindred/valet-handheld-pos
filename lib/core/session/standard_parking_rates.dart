import 'package:equatable/equatable.dart';

/// Standard parking fees from the admin / login API (`standard_rates` payload).
class StandardParkingRates extends Equatable {
  const StandardParkingRates({
    required this.flatRatePesos,
    required this.succeedingHourPesos,
    required this.overnightFeePesos,
    required this.lostTicketFeePesos,
  });

  /// When the API sends no rates (or offline login), [RateService] seeds the local
  /// `rates` table with these values so checkout / Branch Rates work offline-first.
  /// Matches stub login defaults in [AuthApi].
  static const StandardParkingRates offlineDefault = StandardParkingRates(
    flatRatePesos: 150,
    succeedingHourPesos: 30,
    overnightFeePesos: 200,
    lostTicketFeePesos: 200,
  );

  /// First block (e.g. first 3 hours).
  final int flatRatePesos;

  /// Per hour after the flat block.
  final int succeedingHourPesos;

  /// Charged after overnight cutoff (e.g. after 1:30 AM).
  final int overnightFeePesos;

  final int lostTicketFeePesos;

  /// Parses the full login (or bootstrap) JSON and returns [standard_rates] if present.
  static StandardParkingRates? fromLoginResponseJson(Map<String, dynamic>? root) {
    if (root == null) return null;
    final raw = root['standard_rates'] ?? root['standardRates'] ?? root['rates'];
    if (raw is! Map<String, dynamic>) return null;
    return StandardParkingRates.fromJson(raw);
  }

  factory StandardParkingRates.fromJson(Map<String, dynamic> json) {
    int pick(String snake, String camel) {
      final v = json[snake] ?? json[camel];
      if (v is int) return v;
      if (v is num) return v.round();
      return 0;
    }

    return StandardParkingRates(
      flatRatePesos: pick('flat_rate', 'flatRate'),
      succeedingHourPesos: pick('succeeding_hour', 'succeedingHour'),
      overnightFeePesos: pick('overnight_fee', 'overnightFee'),
      lostTicketFeePesos: pick('lost_ticket_fee', 'lostTicketFee'),
    );
  }

  @override
  List<Object?> get props => [
    flatRatePesos,
    succeedingHourPesos,
    overnightFeePesos,
    lostTicketFeePesos,
  ];
}
