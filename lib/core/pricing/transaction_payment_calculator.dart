import '../../core/time/philippine_time.dart';
import '../../data/services/rate_service.dart' show CheckoutRatesResolved, RateService;
import '../../features/check_out/domain/checkout_pricing.dart';
import '../api/transaction_payment_fields.dart';
import '../api/transaction_payment_summary.dart';
import '../printing/receipt_print_format.dart';

/// Builds [TransactionPaymentSummary] from local Drift rates + transaction API cash fields.
///
/// Duration and fee lines use [CheckoutPricing] (time in → time out). API
/// `duration_minutes` and `change` are ignored. Change is `cash_tendered - amount`.
class TransactionPaymentCalculator {
  const TransactionPaymentCalculator(this._rateService);

  final RateService _rateService;

  Future<TransactionPaymentSummary?> fromTransactionJson({
    required Map<String, dynamic> json,
    required String branchId,
    String? vehicleType,
    DateTime? timeInOverride,
    DateTime? timeOutOverride,
  }) async {
    final amount = TransactionPaymentFields.amountFrom(json);
    if (amount == null || amount < 0.009) return null;

    final tendered = TransactionPaymentFields.cashTenderedFrom(json);
    final change = computedChange(amount: amount, cashTendered: tendered);
    final isLost = isLostTicketFromJson(json);

    final timeIn = timeInOverride ?? parseTransactionDateTime(_timeInRaw(json));
    final timeOut = timeOutOverride ??
        parseTransactionDateTime(_timeOutRaw(json)) ??
        timeIn;

    if (timeIn == null) {
      return _summaryWithoutDuration(
        amount: amount,
        cashTendered: tendered,
        change: change,
        isLost: isLost,
        branchId: branchId,
        vehicleType: vehicleType,
      );
    }

    final resolved = await _rateService.checkoutRatesForOffline(
      branchId: branchId,
      vehicleType: vehicleType,
    );

    final breakdown = CheckoutPricing.compute(
      timeIn: timeIn,
      timeOut: timeOut ?? timeIn,
      rates: resolved.rates,
      flatBlockHours: resolved.flatBlockHours,
      overnightStart: resolved.overnightStart,
      overnightEnd: resolved.overnightEnd,
    );

    final lostFee =
        isLost ? resolved.rates.lostTicketFeePesos.toDouble() : 0.0;

    return summaryFromBreakdown(
      breakdown: breakdown,
      flatBlockHours: resolved.flatBlockHours,
      succeedingRatePerHour: resolved.rates.succeedingHourPesos.toDouble(),
      totalDue: amount,
      cashTendered: tendered,
      change: change,
      isLostTicket: isLost,
      lostTicketFee: lostFee,
      overnightStart: resolved.overnightStart,
      overnightEnd: resolved.overnightEnd,
    );
  }

  /// Checkout finalize / reprint when breakdown is already computed.
  TransactionPaymentSummary fromCheckoutBreakdown({
    required CheckoutBreakdown breakdown,
    required CheckoutRatesResolved rates,
    required double totalDue,
    required double cashTendered,
    bool isLostTicket = false,
  }) {
    final lostFee =
        isLostTicket ? rates.rates.lostTicketFeePesos.toDouble() : 0.0;
    final change = computedChange(amount: totalDue, cashTendered: cashTendered);

    return summaryFromBreakdown(
      breakdown: breakdown,
      flatBlockHours: rates.flatBlockHours,
      succeedingRatePerHour: rates.rates.succeedingHourPesos.toDouble(),
      totalDue: totalDue,
      cashTendered: cashTendered,
      change: change,
      isLostTicket: isLostTicket,
      lostTicketFee: lostFee,
      overnightStart: rates.overnightStart,
      overnightEnd: rates.overnightEnd,
    );
  }

  static TransactionPaymentSummary summaryFromBreakdown({
    required CheckoutBreakdown breakdown,
    required int flatBlockHours,
    required double succeedingRatePerHour,
    required double totalDue,
    double? cashTendered,
    double? change,
    required bool isLostTicket,
    required double lostTicketFee,
    String overnightStart = '',
    String overnightEnd = '',
  }) {
    final flatMins = flatBlockHours * 60;
    final extraMins = (breakdown.durationMinutes - flatMins).clamp(0, 1 << 30);
    final succeedingHoursLabel = extraMins > 0
        ? ReceiptPrintFormat.durationLabel(extraMins)
        : '0m';

    return TransactionPaymentSummary(
      totalDue: totalDue,
      flatRate: breakdown.flatRateAmount,
      flatRateLabel: 'Flat rate (${flatBlockHours}h)',
      flatBlockHours: flatBlockHours,
      succeedingHoursLabel: succeedingHoursLabel,
      succeedingRatePerHour: succeedingRatePerHour,
      succeedingTotal: breakdown.succeedingAmount,
      overnightFee: breakdown.overnightAmount,
      overnightStart: overnightStart,
      overnightEnd: overnightEnd,
      lostTicketFee: lostTicketFee,
      cashTendered: cashTendered,
      change: change,
      isLostTicket: isLostTicket,
      isOvernight: breakdown.overnightApplied,
      durationMinutes: breakdown.durationMinutes,
    );
  }

  static double? computedChange({
    required double amount,
    double? cashTendered,
  }) {
    if (cashTendered == null) return null;
    final diff = cashTendered - amount;
    return diff < 0.009 ? 0 : diff;
  }

  static bool isLostTicketFromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString().trim().toLowerCase();
    return json['ticket_lost'] == true ||
        json['ticketLost'] == true ||
        status == 'lost';
  }

  static DateTime? parseTransactionDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.isEmpty) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return PhilippineTime.fromApiIso(s);
  }

  static dynamic _timeInRaw(Map<String, dynamic> json) =>
      json['time_in'] ??
      json['timeIn'] ??
      json['check_in_time'] ??
      json['checkInTime'] ??
      json['check_in_at'];

  static dynamic _timeOutRaw(Map<String, dynamic> json) =>
      json['time_out'] ?? json['timeOut'] ?? json['check_out_at'];

  Future<TransactionPaymentSummary?> _summaryWithoutDuration({
    required double amount,
    double? cashTendered,
    double? change,
    required bool isLost,
    required String branchId,
    String? vehicleType,
  }) async {
    final resolved = await _rateService.checkoutRatesForOffline(
      branchId: branchId,
      vehicleType: vehicleType,
    );
    final lostFee =
        isLost ? resolved.rates.lostTicketFeePesos.toDouble() : 0.0;
    return TransactionPaymentSummary(
      totalDue: amount,
      flatRate: amount - lostFee > 0.009 ? amount - lostFee : amount,
      flatRateLabel: 'Flat rate (${resolved.flatBlockHours}h)',
      flatBlockHours: resolved.flatBlockHours,
      succeedingHoursLabel: '0m',
      succeedingRatePerHour: resolved.rates.succeedingHourPesos.toDouble(),
      lostTicketFee: lostFee,
      cashTendered: cashTendered,
      change: change,
      isLostTicket: isLost,
    );
  }
}
