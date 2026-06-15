import 'package:equatable/equatable.dart';

import '../../../core/time/philippine_time.dart';
import '../../../core/printing/receipt_print_format.dart';
import '../../../data/local/db/app_database.dart';
import '../../check_in/domain/vehicle_body_type.dart';
import 'checkout_pricing.dart';

/// Immutable receipt data captured at checkout finalize (ticket row is cleared from state after).
class CheckoutReceiptSnapshot extends Equatable {
  const CheckoutReceiptSnapshot({
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleReceiptLine,
    this.customerName,
    required this.timeInUnix,
    required this.timeOutUnix,
    required this.durationMinutes,
    this.durationLabel,
    required this.slotLine,
    this.valetName,
    this.valetOutName,
    this.flatRateLabel,
    this.succeedingTimeLabel,
    required this.flatBlockHours,
    required this.flatPesos,
    required this.succeedingPesos,
    required this.succeedingExtraMinutes,
    required this.overnightApplied,
    required this.overnightPesos,
    this.overnightStart = '',
    this.overnightEnd = '',
    required this.totalPesos,
    required this.amountTendered,
    required this.changePesos,
    this.branchLine,
    this.invoiceNumber,
  });

  final String ticketNumber;
  final String plateNumber;
  final String vehicleReceiptLine;
  final String? customerName;
  final int timeInUnix;
  final int timeOutUnix;
  final int durationMinutes;
  final String? durationLabel;
  final String slotLine;
  final String? valetName;
  final String? valetOutName;
  final String? flatRateLabel;
  final String? succeedingTimeLabel;
  final int flatBlockHours;
  final double flatPesos;
  final double succeedingPesos;
  final int succeedingExtraMinutes;
  final bool overnightApplied;
  final double overnightPesos;
  /// Overnight window start in `HH:mm` 24-hour format (e.g. `"21:00"`).
  final String overnightStart;
  /// Overnight window end in `HH:mm` 24-hour format (e.g. `"05:00"`).
  final String overnightEnd;
  final double totalPesos;
  final double amountTendered;
  final double changePesos;
  final String? branchLine;
  final String? invoiceNumber;

  static String slotLineFromTicket(Ticket t) {
    return '—';
  }

  static String vehicleReceiptLineFromTicket(Ticket t) {
    final typeLabel = vehicleTypeDisplayLabel(t.vehicleType);
    final parts = <String>[
      t.vehicleBrand.trim(),
      t.vehicleColor.trim(),
      typeLabel,
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' · ').toUpperCase();
  }

  static String durationLabelFromMinutes(int durationMinutes) {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h <= 0) return '$m mins';
    return '$h hrs $m mins';
  }

  /// Receipt snapshot at finalize — duration and fee lines from local rates.
  factory CheckoutReceiptSnapshot.fromCheckoutFinalize({
    required String localTicketId,
    required Ticket ticket,
    required CheckoutBreakdown breakdown,
    required int flatBlockHours,
    required double totalPesos,
    required double tendered,
    required double change,
    required int timeOutUnix,
    String? invoiceNumber,
    String? branchName,
    String? plateNumber,
    String? vehicleReceiptLine,
    String? slotLine,
    String? valetIn,
    String? valetOut,
    String overnightStart = '',
    String overnightEnd = '',
  }) {
    final parsedIn = PhilippineTime.fromApiIso(ticket.checkInAt);
    final parsedOut = PhilippineTime.fromUnixSeconds(timeOutUnix);
    final timeInUnix = parsedIn != null
        ? parsedIn.millisecondsSinceEpoch ~/ 1000
        : timeOutUnix;
    final durationMinutes = parsedIn != null
        ? CheckoutPricing.durationMinutesCeil(parsedIn, parsedOut)
        : breakdown.durationMinutes;
    final flatMins = flatBlockHours * 60;
    final extraMins = (durationMinutes - flatMins).clamp(0, 1 << 30);

    return CheckoutReceiptSnapshot(
      ticketNumber: localTicketId,
      plateNumber: plateNumber ?? ticket.plateNumber.trim(),
      vehicleReceiptLine:
          vehicleReceiptLine ?? vehicleReceiptLineFromTicket(ticket),
      timeInUnix: timeInUnix,
      timeOutUnix: timeOutUnix,
      durationMinutes: durationMinutes,
      durationLabel: ReceiptPrintFormat.durationLabel(durationMinutes),
      slotLine: slotLine ?? slotLineFromTicket(ticket),
      valetName: valetIn,
      valetOutName: valetOut,
      flatBlockHours: flatBlockHours,
      flatPesos: breakdown.flatRateAmount,
      flatRateLabel: 'Flat rate (${flatBlockHours}h)',
      succeedingPesos: breakdown.succeedingAmount,
      succeedingTimeLabel: extraMins > 0
          ? ReceiptPrintFormat.durationLabel(extraMins)
          : null,
      succeedingExtraMinutes: extraMins,
      overnightApplied: breakdown.overnightApplied,
      overnightPesos: breakdown.overnightAmount,
      overnightStart: overnightStart,
      overnightEnd: overnightEnd,
      totalPesos: totalPesos,
      amountTendered: tendered,
      changePesos: change,
      branchLine: branchName,
      invoiceNumber: invoiceNumber,
    );
  }

  factory CheckoutReceiptSnapshot.capture({
    required Ticket ticket,
    required CheckoutBreakdown b,
    required double tendered,
    required double change,
    required int timeOutUnix,
    int flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
    double? totalPesos,
    String overnightStart = '',
    String overnightEnd = '',
  }) {
    final flatMins = flatBlockHours * 60;
    final extraMins = (b.durationMinutes - flatMins).clamp(0, 1 << 30);
    final branch = ticket.branchId.trim();
    final parsedIn = PhilippineTime.fromApiIso(ticket.checkInAt);
    final timeInUnix = parsedIn != null
        ? parsedIn.millisecondsSinceEpoch ~/ 1000
        : timeOutUnix;
    return CheckoutReceiptSnapshot(
      ticketNumber: ticket.id,
      plateNumber: ticket.plateNumber.trim(),
      vehicleReceiptLine: vehicleReceiptLineFromTicket(ticket),
      customerName: null,
      timeInUnix: timeInUnix,
      timeOutUnix: timeOutUnix,
      durationMinutes: b.durationMinutes,
      slotLine: slotLineFromTicket(ticket),
      valetName: null,
      flatBlockHours: flatBlockHours,
      flatPesos: b.flatRateAmount,
      succeedingPesos: b.succeedingAmount,
      succeedingExtraMinutes: extraMins,
      overnightApplied: b.overnightApplied,
      overnightPesos: b.overnightAmount,
      overnightStart: overnightStart,
      overnightEnd: overnightEnd,
      totalPesos: totalPesos ?? b.total,
      amountTendered: tendered,
      changePesos: change,
      branchLine: branch.isEmpty ? null : branch,
    );
  }

  /// When only receipt totals exist (e.g. tests).
  factory CheckoutReceiptSnapshot.minimal({
    required String ticketNumber,
    required double totalPesos,
    required double changePesos,
  }) {
    return CheckoutReceiptSnapshot(
      ticketNumber: ticketNumber,
      plateNumber: '',
      vehicleReceiptLine: '',
      timeInUnix: 0,
      timeOutUnix: 0,
      durationMinutes: 0,
      slotLine: '—',
      flatBlockHours: CheckoutPricing.defaultFlatBlockHours,
      flatPesos: 0,
      succeedingPesos: 0,
      succeedingExtraMinutes: 0,
      overnightApplied: false,
      overnightPesos: 0,
      totalPesos: totalPesos,
      amountTendered: totalPesos + changePesos,
      changePesos: changePesos,
    );
  }

  @override
  List<Object?> get props => [
        ticketNumber,
        plateNumber,
        vehicleReceiptLine,
        customerName,
        timeInUnix,
        timeOutUnix,
        durationMinutes,
        slotLine,
        valetName,
        flatBlockHours,
        flatPesos,
        succeedingPesos,
        succeedingExtraMinutes,
        overnightApplied,
        overnightPesos,
        overnightStart,
        overnightEnd,
        totalPesos,
        amountTendered,
        changePesos,
        branchLine,
        invoiceNumber,
        durationLabel,
        valetOutName,
        flatRateLabel,
        succeedingTimeLabel,
      ];
}
