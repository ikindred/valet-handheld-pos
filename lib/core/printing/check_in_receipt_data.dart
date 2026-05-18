import '../../data/local/db/app_database.dart';

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
}
