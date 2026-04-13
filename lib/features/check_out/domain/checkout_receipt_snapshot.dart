import 'package:equatable/equatable.dart';

import '../../../data/local/db/app_database.dart';
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
    required this.slotLine,
    this.valetName,
    required this.flatBlockHours,
    required this.flatPesos,
    required this.succeedingPesos,
    required this.succeedingExtraMinutes,
    required this.overnightApplied,
    required this.overnightPesos,
    required this.totalPesos,
    required this.amountTendered,
    required this.changePesos,
    this.branchLine,
  });

  final String ticketNumber;
  final String plateNumber;
  final String vehicleReceiptLine;
  final String? customerName;
  final int timeInUnix;
  final int timeOutUnix;
  final int durationMinutes;
  final String slotLine;
  final String? valetName;
  final int flatBlockHours;
  final double flatPesos;
  final double succeedingPesos;
  final int succeedingExtraMinutes;
  final bool overnightApplied;
  final double overnightPesos;
  final double totalPesos;
  final double amountTendered;
  final double changePesos;
  final String? branchLine;

  static String slotLineFromTicket(Ticket t) {
    return '—';
  }

  static String vehicleReceiptLineFromTicket(Ticket t) {
    final parts = <String>[
      t.vehicleBrand.trim(),
      t.vehicleColor.trim(),
      t.vehicleType.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' · ').toUpperCase();
  }

  static String durationLabelFromMinutes(int durationMinutes) {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h <= 0) return '$m mins';
    return '$h hrs $m mins';
  }

  factory CheckoutReceiptSnapshot.capture({
    required Ticket ticket,
    required CheckoutBreakdown b,
    required double tendered,
    required double change,
    required int timeOutUnix,
    int flatBlockHours = CheckoutPricing.defaultFlatBlockHours,
  }) {
    final flatMins = flatBlockHours * 60;
    final extraMins = (b.durationMinutes - flatMins).clamp(0, 1 << 30);
    final branch = ticket.branchId.trim();
    final parsedIn = DateTime.tryParse(ticket.checkInAt);
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
      flatPesos: b.flatPortionPesos.toDouble(),
      succeedingPesos: b.succeedingPortionPesos.toDouble(),
      succeedingExtraMinutes: extraMins,
      overnightApplied: b.overnightApplied,
      overnightPesos: b.overnightPortionPesos.toDouble(),
      totalPesos: b.totalPesos.toDouble(),
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
        totalPesos,
        amountTendered,
        changePesos,
        branchLine,
      ];
}
