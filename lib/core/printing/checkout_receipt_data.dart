import '../../data/local/db/app_database.dart';
import '../../features/check_out/domain/checkout_receipt_snapshot.dart';
import '../../features/dashboard/domain/ticket_parking_info.dart';
import '../time/philippine_time.dart';
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
    required this.flatRateLabel,
    required this.flatPesosLabel,
    required this.succeedingLabel,
    required this.succeedingPesosLabel,
    required this.overnightPesosLabel,
    required this.showOvernight,
    required this.totalPesosLabel,
    required this.tenderedPesosLabel,
    required this.changePesosLabel,
    required this.branchName,
    required this.mallHours,
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
  final String flatRateLabel;
  final String flatPesosLabel;
  final String succeedingLabel;
  final String succeedingPesosLabel;
  final String overnightPesosLabel;
  final bool showOvernight;
  final String totalPesosLabel;
  final String tenderedPesosLabel;
  final String changePesosLabel;
  final String branchName;
  final String mallHours;
  final String? invoiceNumber;

  factory CheckoutReceiptData.fromSnapshot(
    CheckoutReceiptSnapshot snap, {
    required String mallHours,
    String? branchDisplayName,
  }) {
    String pesoNum(double v) => ReceiptPrintFormat.pesoAmount(v);

    final timeIn = _formatUnix(snap.timeInUnix);
    final timeOut = _formatUnix(snap.timeOutUnix);
    final duration = snap.durationLabel?.trim().isNotEmpty == true
        ? snap.durationLabel!.trim()
        : CheckoutReceiptSnapshot.durationLabelFromMinutes(
            snap.durationMinutes,
          );

    final flatLabel = snap.flatRateLabel?.trim().isNotEmpty == true
        ? snap.flatRateLabel!.trim()
        : 'Flat rate';
    final succeedingLabel = snap.succeedingTimeLabel?.trim().isNotEmpty == true
        ? snap.succeedingTimeLabel!.trim()
        : '';
    final succeedingAmount = snap.succeedingPesos;
    final showSucceeding = succeedingLabel.isNotEmpty && succeedingAmount > 0.009;

    var flatDisplay = snap.flatPesos;
    if (flatDisplay < 0.009 && snap.totalPesos > 0.009 && !showSucceeding) {
      flatDisplay = snap.totalPesos;
    }

    final branch = (branchDisplayName ?? snap.branchLine ?? '').trim();
    final branchHeader = branch.isEmpty ? 'Valet Master' : branch;

    return CheckoutReceiptData(
      ticketNumber: snap.ticketNumber,
      plateNumber:
          snap.plateNumber.trim().isEmpty ? '—' : snap.plateNumber.trim(),
      vehicleReceiptLine: snap.vehicleReceiptLine.trim(),
      timeInLabel: timeIn,
      timeOutLabel: timeOut,
      durationLabel: duration,
      slotLine: snap.slotLine.trim().isEmpty ? '—' : snap.slotLine.trim(),
      valetInLabel: (snap.valetName ?? '').trim().isEmpty
          ? '—'
          : snap.valetName!.trim(),
      valetOutLabel: (snap.valetOutName ?? '').trim().isEmpty
          ? '—'
          : snap.valetOutName!.trim(),
      flatRateLabel: flatLabel,
      flatPesosLabel: pesoNum(flatDisplay),
      succeedingLabel: showSucceeding ? succeedingLabel : '',
      succeedingPesosLabel: showSucceeding ? pesoNum(succeedingAmount) : '',
      showOvernight: snap.overnightApplied && snap.overnightPesos > 0.009,
      overnightPesosLabel: pesoNum(snap.overnightPesos),
      totalPesosLabel: pesoNum(snap.totalPesos),
      tenderedPesosLabel: pesoNum(snap.amountTendered),
      changePesosLabel: pesoNum(snap.changePesos),
      branchName: branchHeader,
      mallHours: mallHours.trim().isEmpty
          ? 'MONDAY – SUNDAY · 10:00AM – 9:00PM'
          : mallHours.trim(),
      invoiceNumber: snap.invoiceNumber?.trim(),
    );
  }

  /// Dashboard ticket detail — completed / lost checkout reprint.
  factory CheckoutReceiptData.fromTicketDetail({
    required Ticket ticket,
    TicketParkingInfo? parking,
    String? branchDisplayName,
    String mallHours = 'MONDAY – SUNDAY · 10:00AM – 9:00PM',
  }) {
    String pesoNum(double v) => ReceiptPrintFormat.pesoAmount(v);

    final checkIn = DateTime.tryParse(ticket.checkInAt)?.toUtc();
    final checkOut = DateTime.tryParse(ticket.checkOutAt ?? '')?.toUtc();
    final timeInUnix = checkIn != null
        ? checkIn.millisecondsSinceEpoch ~/ 1000
        : 0;
    final timeOutUnix = checkOut != null
        ? checkOut.millisecondsSinceEpoch ~/ 1000
        : timeInUnix;

    var durationLabel = '—';
    if (checkIn != null && checkOut != null) {
      final totalM = checkOut.difference(checkIn).inMinutes;
      final h = totalM ~/ 60;
      final m = totalM % 60;
      durationLabel = h < 1 ? '${totalM}m' : '${h}h ${m}m';
    }

    final total = (ticket.fee ?? 0).toDouble();
    final branch = (branchDisplayName ?? '').trim();
    final branchHeader = branch.isEmpty ? 'Valet Master' : branch;

    return CheckoutReceiptData(
      ticketNumber: ticket.id,
      plateNumber:
          ticket.plateNumber.trim().isEmpty ? '—' : ticket.plateNumber.trim(),
      vehicleReceiptLine:
          CheckoutReceiptSnapshot.vehicleReceiptLineFromTicket(ticket),
      timeInLabel: _formatUnix(timeInUnix),
      timeOutLabel: _formatUnix(timeOutUnix),
      durationLabel: durationLabel,
      slotLine: _slotLineFromParking(parking),
      valetInLabel: _plainDriverLabel(ticket.driverIn),
      valetOutLabel: _plainDriverLabel(ticket.driverOut),
      flatRateLabel: 'Amount paid',
      flatPesosLabel: pesoNum(total),
      succeedingLabel: '',
      succeedingPesosLabel: '',
      showOvernight: false,
      overnightPesosLabel: pesoNum(0),
      totalPesosLabel: pesoNum(total),
      tenderedPesosLabel: pesoNum(total),
      changePesosLabel: pesoNum(0),
      branchName: branchHeader,
      mallHours: mallHours.trim().isEmpty
          ? 'MONDAY – SUNDAY · 10:00AM – 9:00PM'
          : mallHours.trim(),
    );
  }

  static String _slotLineFromParking(TicketParkingInfo? parking) {
    if (parking == null || !parking.hasAny) return '—';
    final parts = <String>[];
    if (parking.areaLabel != '—') parts.add(parking.areaLabel);
    if (parking.levelLabel != '—') parts.add(parking.levelLabel);
    if (parking.slotLabel != '—') parts.add(parking.slotLabel);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  static String _plainDriverLabel(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t.startsWith('{')) return '—';
    return t;
  }

  static String _formatUnix(int unix) {
    if (unix <= 0) return '—';
    final ph = PhilippineTime.fromUnixSeconds(unix);
    return ReceiptPrintFormat.dateTimeLabel(ph);
  }
}
