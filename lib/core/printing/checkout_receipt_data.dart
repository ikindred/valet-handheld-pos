import '../../core/api/transaction_payment_summary.dart';
import '../../features/check_out/models/checkout_preview_rates.dart';
import '../../data/local/db/app_database.dart';
import '../../features/check_out/domain/checkout_pricing.dart';
import '../../features/check_out/domain/checkout_receipt_snapshot.dart';
import '../../features/dashboard/domain/ticket_parking_info.dart';
import '../time/philippine_time.dart';
import '../formatting/valet_type_format.dart';
import 'receipt_print_format.dart';

/// Thermal checkout receipt payload (ESC/POS + raster).
class CheckoutReceiptData {
  const CheckoutReceiptData({
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleReceiptLine,
    required this.timeInLabel,
    required this.timeOutLabel,
    required this.durationLabel,
    required this.slotLine,
    required this.valetInLabel,
    required this.valetOutLabel,
    this.valetTypeLabel,
    required this.flatRateLabel,
    required this.flatPesosLabel,
    required this.succeedingLabel,
    required this.succeedingPesosLabel,
    required this.overnightPesosLabel,
    required this.showOvernight,
    required this.totalPesosLabel,
    required this.tenderedPesosLabel,
    required this.changePesosLabel,
    required this.changePesos,
    required this.branchName,
    required this.mallHours,
    required this.isLostTicket,
    required this.lostFeePesosLabel,
    required this.flatRateHoursLabel,
    required this.succeedingHoursLabel,
    required this.succeedingRateLabel,
    required this.succeedingTotalLabel,
    required this.overnightFeeLabel,
    required this.overnightRowLabel,
    this.invoiceNumber,
  });

  final String ticketNumber;
  final String plateNumber;
  final String vehicleReceiptLine;
  final String timeInLabel;
  final String timeOutLabel;
  final String durationLabel;
  final String slotLine;
  final String valetInLabel;
  final String valetOutLabel;
  final String? valetTypeLabel;
  final String flatRateLabel;
  final String flatPesosLabel;
  final String succeedingLabel;
  final String succeedingPesosLabel;
  final String overnightPesosLabel;
  final bool showOvernight;
  final String totalPesosLabel;
  final String tenderedPesosLabel;
  final String changePesosLabel;
  final double changePesos;
  final String branchName;
  final String mallHours;
  final bool isLostTicket;
  final String lostFeePesosLabel;
  final String flatRateHoursLabel;
  final String succeedingHoursLabel;
  final String succeedingRateLabel;
  final String succeedingTotalLabel;
  final String overnightFeeLabel;
  /// Full overnight row title, e.g. `"Overnight fee (9:00 PM – 5:00 AM)"`.
  final String overnightRowLabel;
  final String? invoiceNumber;

  bool get changeIsNonZero => changePesos > 0.009;

  bool get showValetStaff => !ValetTypeFormat.isSelfParkDisplayLabel(valetTypeLabel);

  factory CheckoutReceiptData.fromSnapshot(
    CheckoutReceiptSnapshot snap, {
    required String mallHours,
    String? branchDisplayName,
    bool isLostTicket = false,
    double lostTicketFee = 0,
  }) {
    String pesoNum(double v) => ReceiptPrintFormat.pesoAmount(v);

    final timeIn = _formatUnix(snap.timeInUnix);
    final timeOut = _formatUnix(snap.timeOutUnix);
    final parsedIn = snap.timeInUnix > 0
        ? PhilippineTime.fromUnixSeconds(snap.timeInUnix)
        : null;
    final parsedOut = snap.timeOutUnix > 0
        ? PhilippineTime.fromUnixSeconds(snap.timeOutUnix)
        : null;
    final effectiveMinutes = parsedIn != null && parsedOut != null
        ? CheckoutPricing.durationMinutesCeil(parsedIn, parsedOut)
        : snap.durationMinutes;
    final duration = effectiveMinutes > 0
        ? ReceiptPrintFormat.durationLabel(effectiveMinutes)
        : '0m';

    final flatLabel = snap.flatRateLabel?.trim().isNotEmpty == true
        ? snap.flatRateLabel!.trim()
        : 'Flat rate';
    final succeedingAmount = snap.succeedingPesos;
    final showSucceeding = succeedingAmount > 0.009;
    final succeedingLabel = showSucceeding
        ? (snap.succeedingTimeLabel?.trim().isNotEmpty == true
            ? snap.succeedingTimeLabel!.trim()
            : 'Succeeding hours')
        : '';

    final flatHours = snap.flatBlockHours > 0 ? snap.flatBlockHours : 3;
    final flatRateHoursLabel = 'Flat rate (${flatHours}h)';

    final succeedingMinutes = snap.succeedingExtraMinutes;
    final succeedingH = succeedingMinutes ~/ 60;
    final succeedingM = succeedingMinutes % 60;
    final succeedingHoursLabel = succeedingMinutes > 0
        ? (succeedingH > 0 ? '${succeedingH}h ${succeedingM}m' : '${succeedingM}m')
        : '0m';

    final succeedingHoursCount = succeedingMinutes > 0
        ? (succeedingMinutes / 60).ceil()
        : 0;
    final succeedingRatePerHr = snap.flatBlockHours > 0 && succeedingMinutes > 0
        ? (snap.succeedingPesos /
                ((succeedingMinutes / 60).ceil().clamp(1, 999)))
            .clamp(0.0, double.infinity)
        : succeedingHoursCount > 0
            ? snap.succeedingPesos / succeedingHoursCount
            : 0.0;
    final succeedingRateLabel = succeedingHoursCount > 0
        ? '${pesoNum(succeedingRatePerHr)}/hr'
        : '—';

    final succeedingTotalLabel = pesoNum(snap.succeedingPesos);
    final overnightFeeLabel = pesoNum(snap.overnightPesos);
    final overnightRowLabel = ReceiptPrintFormat.overnightFeeRowLabel(
      startHhMm24: snap.overnightStart,
      endHhMm24: snap.overnightEnd,
    );

    final branch = (branchDisplayName ?? snap.branchLine ?? '').trim();
    final branchHeader = branch;
    final lostFeeLabel = ReceiptPrintFormat.pesoAmount(lostTicketFee);

    return CheckoutReceiptData(
      ticketNumber: snap.ticketNumber,
      plateNumber:
          snap.plateNumber.trim().isEmpty ? '-' : snap.plateNumber.trim(),
      vehicleReceiptLine: snap.vehicleReceiptLine.trim(),
      timeInLabel: timeIn,
      timeOutLabel: timeOut,
      durationLabel: duration,
      slotLine: snap.slotLine.trim().isEmpty ? '-' : snap.slotLine.trim(),
      valetInLabel: _driverLabel(snap.valetName),
      valetOutLabel: _driverLabel(snap.valetOutName),
      valetTypeLabel: snap.valetTypeLabel,
      flatRateLabel: flatLabel,
      flatPesosLabel: pesoNum(snap.flatPesos),
      succeedingLabel: showSucceeding ? succeedingLabel : '',
      succeedingPesosLabel: showSucceeding ? pesoNum(succeedingAmount) : '',
      showOvernight: snap.overnightApplied && snap.overnightPesos > 0.009,
      overnightPesosLabel: pesoNum(snap.overnightPesos),
      totalPesosLabel: pesoNum(snap.totalPesos),
      tenderedPesosLabel: pesoNum(snap.amountTendered),
      changePesosLabel: pesoNum(snap.changePesos),
      changePesos: snap.changePesos,
      branchName: branchHeader,
      mallHours: mallHours.trim().isEmpty
          ? ReceiptTemplateCopy.defaultMallHours
          : mallHours.trim(),
      isLostTicket: isLostTicket,
      lostFeePesosLabel: lostFeeLabel,
      flatRateHoursLabel: flatRateHoursLabel,
      succeedingHoursLabel: succeedingHoursLabel,
      succeedingRateLabel: succeedingRateLabel,
      succeedingTotalLabel: succeedingTotalLabel,
      overnightFeeLabel: overnightFeeLabel,
      overnightRowLabel: overnightRowLabel,
      invoiceNumber: snap.invoiceNumber?.trim(),
    );
  }

  /// Dashboard ticket detail — completed / lost checkout reprint.
  factory CheckoutReceiptData.fromTicketDetail({
    required Ticket ticket,
    TicketParkingInfo? parking,
    String? branchDisplayName,
    String mallHours = 'MONDAY – SUNDAY · 10:00AM – 9:00PM',
    TransactionPaymentSummary? payment,
    CheckoutPreviewRates? appliedRate,
    double? cashTendered,
    double? changePesos,
    String? valetTypeLabel,
  }) {
    String pesoNum(double v) => ReceiptPrintFormat.pesoAmount(v);

    final checkIn = PhilippineTime.fromApiIso(ticket.checkInAt);
    final checkOut = ticket.checkOutAt != null && ticket.checkOutAt!.trim().isNotEmpty
        ? PhilippineTime.fromApiIso(ticket.checkOutAt!)
        : null;
    final timeInUnix = checkIn.millisecondsSinceEpoch ~/ 1000;
    final timeOutUnix = checkOut != null
        ? checkOut.millisecondsSinceEpoch ~/ 1000
        : timeInUnix;

    final p = appliedRate != null && appliedRate.flatRateHours > 0
        ? payment?.withFlatBlockHours(appliedRate.flatRateHours)
        : payment;
    final durationMinutes = checkOut != null
        ? CheckoutPricing.durationMinutesCeil(checkIn, checkOut)
        : (p?.durationMinutes ?? 0);
    final durationLabel = durationMinutes > 0
        ? ReceiptPrintFormat.durationLabel(durationMinutes)
        : '0m';
    final total = p?.totalDue ?? (ticket.fee ?? 0).toDouble();
    final flatAmount = p?.flatRate ?? total;
    final flatLabel = p?.flatRateLabel.trim().isNotEmpty == true
        ? p!.flatRateLabel.trim()
        : 'Flat rate';
    final succeedingLabel = p?.succeedingLineLabel.trim().isNotEmpty == true
        ? p!.succeedingLineLabel.trim()
        : (p?.hasSucceedingHours == true ? p!.succeedingHoursLabel.trim() : '');
    final succeedingAmount = p?.succeedingTotal ?? 0;
    final showSucceeding =
        succeedingLabel.isNotEmpty && succeedingAmount > 0.009;
    final showOvernight =
        (p?.overnightFee ?? 0) > 0.009 || p?.isOvernight == true;
    final overnightAmount = p?.overnightFee ?? 0;
    final isLost = p?.isLostTicket == true || ticket.status == 'lost';
    final lostFee = p?.lostTicketFee ?? 0;

    final tendered = cashTendered ??
        p?.cashTendered ??
        (total > 0.009 ? total : 0);
    final change = changePesos ??
        p?.change ??
        (tendered > total + 1e-6 ? tendered - total : 0.0);

    final flatHours = p?.flatBlockHours ?? 3;
    final flatRateHoursLabel = p?.flatRateLabel.trim().isNotEmpty == true
        ? p!.flatRateLabel.trim()
        : 'Flat rate (${flatHours}h)';
    final succeedingHoursLabel = p?.succeedingHoursLabel.trim().isNotEmpty == true
        ? p!.succeedingHoursLabel.trim()
        : '0m';
    final succeedingRatePerHr = (p?.succeedingRatePerHour ?? 0) > 0.009
        ? p!.succeedingRatePerHour
        : 0.0;
    final succeedingRateLabel = succeedingRatePerHr > 0.009
        ? '${pesoNum(succeedingRatePerHr)}/hr'
        : '—';

    final branch = (branchDisplayName ?? '').trim();
    final branchHeader = branch;
    final overnightRowLabel = ReceiptPrintFormat.overnightFeeRowLabel(
      startHhMm24: p?.overnightStart ?? '',
      endHhMm24: p?.overnightEnd ?? '',
    );

    final valetType = valetTypeLabel ??
        ValetTypeFormat.labelIfPresent(
          ValetTypeFormat.fromDriverOutMeta(ticket.driverOut),
        );
    final showValetStaff = !ValetTypeFormat.isSelfParkDisplayLabel(valetType);

    return CheckoutReceiptData(
      ticketNumber: ticket.id,
      plateNumber:
          ticket.plateNumber.trim().isEmpty ? '-' : ticket.plateNumber.trim(),
      vehicleReceiptLine:
          CheckoutReceiptSnapshot.vehicleReceiptLineFromTicket(ticket),
      timeInLabel: _formatUnix(timeInUnix),
      timeOutLabel: _formatUnix(timeOutUnix),
      durationLabel: durationLabel,
      slotLine: _slotLineFromParking(parking),
      valetInLabel:
          showValetStaff ? _plainDriverLabel(ticket.driverIn) : '-',
      valetOutLabel:
          showValetStaff ? _plainDriverLabel(ticket.driverOut) : '-',
      valetTypeLabel: valetType,
      flatRateLabel: flatLabel,
      flatPesosLabel: pesoNum(flatAmount),
      succeedingLabel: showSucceeding ? succeedingLabel : '',
      succeedingPesosLabel: showSucceeding ? pesoNum(succeedingAmount) : '',
      showOvernight: showOvernight,
      overnightPesosLabel: pesoNum(overnightAmount),
      totalPesosLabel: pesoNum(total),
      tenderedPesosLabel: pesoNum(tendered),
      changePesosLabel: pesoNum(change),
      changePesos: change,
      branchName: branchHeader,
      mallHours: mallHours.trim().isEmpty
          ? ReceiptTemplateCopy.defaultMallHours
          : mallHours.trim(),
      isLostTicket: isLost,
      lostFeePesosLabel: pesoNum(lostFee),
      flatRateHoursLabel: flatRateHoursLabel,
      succeedingHoursLabel: succeedingHoursLabel,
      succeedingRateLabel: succeedingRateLabel,
      succeedingTotalLabel: pesoNum(succeedingAmount),
      overnightFeeLabel: pesoNum(overnightAmount),
      overnightRowLabel: overnightRowLabel,
      invoiceNumber: null,
    );
  }

  static String _slotLineFromParking(TicketParkingInfo? parking) {
    if (parking == null || !parking.hasAny) return '-';
    final parts = <String>[];
    if (parking.areaLabel != '—') parts.add(parking.areaLabel);
    if (parking.levelLabel != '—') parts.add(parking.levelLabel);
    if (parking.slotLabel != '—') parts.add(parking.slotLabel);
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  static String _driverLabel(String? raw) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? '-' : t;
  }

  static String _plainDriverLabel(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t.startsWith('{')) return '-';
    return t;
  }

  static String _formatUnix(int unix) {
    if (unix <= 0) return '—';
    final ph = PhilippineTime.fromUnixSeconds(unix);
    return ReceiptPrintFormat.dateTimeLabel(ph);
  }
}
