import 'dart:convert';

import 'transaction_payment_fields.dart';

/// Fee breakdown + cash lines for ticket detail and thermal reprint.
///
/// Fee lines are built from local Drift rates via [TransactionPaymentCalculator].
class TransactionPaymentSummary {
  const TransactionPaymentSummary({
    required this.totalDue,
    this.flatRate = 0,
    this.flatRateLabel = 'Flat rate',
    this.flatBlockHours = 3,
    this.succeedingHoursLabel = '',
    this.succeedingLineLabel = '',
    this.succeedingRatePerHour = 0,
    this.succeedingTotal = 0,
    this.overnightFee = 0,
    this.overnightStart = '',
    this.overnightEnd = '',
    this.lostTicketFee = 0,
    this.cashTendered,
    this.change,
    this.isLostTicket = false,
    this.isOvernight = false,
    this.durationMinutes = 0,
  });

  final double totalDue;
  final double flatRate;
  final String flatRateLabel;
  final int flatBlockHours;
  final String succeedingHoursLabel;
  final String succeedingLineLabel;
  final double succeedingRatePerHour;
  final double succeedingTotal;
  final double overnightFee;
  /// Overnight window start in `HH:mm` 24-hour format (e.g. `"21:00"`).
  final String overnightStart;
  /// Overnight window end in `HH:mm` 24-hour format (e.g. `"05:00"`).
  final String overnightEnd;
  final double lostTicketFee;
  final double? cashTendered;
  final double? change;
  final bool isLostTicket;
  final bool isOvernight;
  final int durationMinutes;

  bool get hasTotal => totalDue > 0.009;
  bool get hasFlatRate => flatRate > 0.009;
  bool get hasSucceedingHours => succeedingHoursLabel.trim().isNotEmpty;
  bool get hasSucceedingTotal => succeedingTotal > 0.009;
  bool get hasOvernightFee => overnightFee > 0.009;
  bool get hasLostTicketFee => lostTicketFee > 0.009;
  bool get hasCashTendered => cashTendered != null && cashTendered! > 0.009;
  bool get hasChange => change != null && change! > 0.009;

  bool get hasFeeBreakdown =>
      (hasSucceedingTotal ||
          hasOvernightFee ||
          hasLostTicketFee ||
          (hasFlatRate && (flatRate - totalDue).abs() > 0.009)) &&
      !(hasFlatRate &&
          (flatRate - totalDue).abs() < 0.009 &&
          !hasSucceedingTotal &&
          !hasOvernightFee &&
          !hasLostTicketFee);

  Map<String, dynamic> toJson() => {
    'totalDue': totalDue,
    'flatRate': flatRate,
    'flatRateLabel': flatRateLabel,
    'flatBlockHours': flatBlockHours,
    'succeedingHoursLabel': succeedingHoursLabel,
    'succeedingLineLabel': succeedingLineLabel,
    'succeedingRatePerHour': succeedingRatePerHour,
    'succeedingTotal': succeedingTotal,
    'overnightFee': overnightFee,
    if (overnightStart.isNotEmpty) 'overnightStart': overnightStart,
    if (overnightEnd.isNotEmpty) 'overnightEnd': overnightEnd,
    'lostTicketFee': lostTicketFee,
    if (cashTendered != null) 'cashTendered': cashTendered,
    if (change != null) 'change': change,
    'isLostTicket': isLostTicket,
    'isOvernight': isOvernight,
    'durationMinutes': durationMinutes,
  };

  static TransactionPaymentSummary? fromStoredJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final body = jsonDecode(raw);
      if (body is! Map) return null;
      return fromStoredMap(Map<String, dynamic>.from(body));
    } catch (_) {
      return null;
    }
  }

  static TransactionPaymentSummary? fromStoredMap(Map<String, dynamic> json) {
    final total = TransactionPaymentFields.optionalMoney(json['totalDue']);
    if (total == null || total < 0.009) return null;
    return TransactionPaymentSummary(
      totalDue: total,
      flatRate:
          TransactionPaymentFields.optionalMoney(json['flatRate']) ?? total,
      flatRateLabel: json['flatRateLabel']?.toString().trim().isNotEmpty == true
          ? json['flatRateLabel'].toString().trim()
          : 'Flat rate',
      flatBlockHours: _storedInt(json['flatBlockHours'], fallback: 3),
      succeedingHoursLabel: json['succeedingHoursLabel']?.toString() ?? '',
      succeedingLineLabel: json['succeedingLineLabel']?.toString() ?? '',
      succeedingRatePerHour:
          TransactionPaymentFields.optionalMoney(
            json['succeedingRatePerHour'],
          ) ??
          0,
      succeedingTotal:
          TransactionPaymentFields.optionalMoney(json['succeedingTotal']) ?? 0,
      overnightFee:
          TransactionPaymentFields.optionalMoney(json['overnightFee']) ?? 0,
      overnightStart: json['overnightStart']?.toString() ?? '',
      overnightEnd: json['overnightEnd']?.toString() ?? '',
      lostTicketFee:
          TransactionPaymentFields.optionalMoney(json['lostTicketFee']) ?? 0,
      cashTendered: TransactionPaymentFields.optionalMoney(
        json['cashTendered'],
      ),
      change: TransactionPaymentFields.optionalMoney(json['change']),
      isLostTicket: json['isLostTicket'] == true,
      isOvernight: json['isOvernight'] == true,
      durationMinutes: _storedInt(json['durationMinutes']),
    );
  }

  static int _storedInt(dynamic raw, {int fallback = 0}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }
}
