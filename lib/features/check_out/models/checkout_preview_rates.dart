import 'package:equatable/equatable.dart';

import '../../../core/branch/overnight_window.dart';

/// Resolved fee schedule from checkout-preview `rates` (online only).
class CheckoutPreviewRates extends Equatable {
  const CheckoutPreviewRates({
    required this.flatRate,
    required this.succeedingRate,
    required this.overnightFee,
    required this.lostTicketFee,
    required this.overnightStart,
    required this.overnightEnd,
  });

  final double flatRate;
  final double succeedingRate;
  final double overnightFee;
  final double lostTicketFee;

  /// Overnight window start (`HH:mm`, 24h).
  final String overnightStart;

  /// Overnight window end (`HH:mm`, 24h).
  final String overnightEnd;

  /// Parses `response["rates"]`; null when the block is absent (offline / legacy).
  static CheckoutPreviewRates? fromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    if (json.isEmpty) return null;

    final overnight = OvernightWindow.parseTimesFromJson(json);
    final start = overnight.start ?? '';
    final end = overnight.end ?? '';

    return CheckoutPreviewRates(
      flatRate: _dbl(json['flat_rate'] ?? json['flatRate']),
      succeedingRate: _dbl(
        json['succeeding_rate'] ??
            json['succeedingRate'] ??
            json['succeeding_hour'] ??
            json['succeedingHour'],
      ),
      overnightFee: _dbl(json['overnight_fee'] ?? json['overnightFee']),
      lostTicketFee: _dbl(
        json['lost_ticket_fee'] ?? json['lostTicketFee'],
      ),
      overnightStart: start,
      overnightEnd: end,
    );
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  List<Object?> get props => [
        flatRate,
        succeedingRate,
        overnightFee,
        lostTicketFee,
        overnightStart,
        overnightEnd,
      ];
}
