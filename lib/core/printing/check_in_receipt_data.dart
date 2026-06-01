import '../../data/local/db/app_database.dart';
import 'receipt_print_format.dart';

/// Ticket row + optional UI fields not stored on [Ticket].
class CheckInReceiptData {
  const CheckInReceiptData({
    required this.ticket,
    required this.branchName,
    this.customerName,
    this.contactNumber,
    this.parkingLevel,
    this.parkingSlot,
    this.valetTypeLabel,
    this.specialRequest,
    this.hasSignature = false,
    this.qrCode,
    this.mallHours = ReceiptTemplateCopy.defaultMallHours,
    this.flatRatePesos = 0,
    this.flatRateHours = 3,
    this.succeedingHourPesos = 0,
    this.overnightFeePesos = 0,
    this.lostTicketFeePesos = 0,
    this.overnightCutoff = '',
  });

  final Ticket ticket;
  final String branchName;
  final String? customerName;
  final String? contactNumber;
  final String? parkingLevel;
  final String? parkingSlot;
  final String? valetTypeLabel;
  final String? specialRequest;
  final bool hasSignature;

  /// Server `qr_code` (or local ticket number when offline); used for receipt QR only.
  final String? qrCode;

  /// Footer line (ASCII-safe; shown on customer copy).
  final String mallHours;

  final int flatRatePesos;

  /// Flat-rate block length in hours (e.g. first 3 hours).
  final int flatRateHours;
  final int succeedingHourPesos;
  final int overnightFeePesos;
  final int lostTicketFeePesos;

  /// Display label for overnight window (e.g. `after 1:30 AM` or `1:30 AM – 6:00 AM`).
  final String overnightCutoff;
}
