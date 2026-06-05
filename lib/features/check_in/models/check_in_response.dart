class CheckInResponse {
  const CheckInResponse({
    required this.id,
    required this.ticketNumber,
    required this.qrCode,
    this.rawJson = const {},
  });

  final String id;
  final String ticketNumber;
  final String qrCode;

  /// Full API body for void/status metadata after check-in.
  final Map<String, dynamic> rawJson;

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      id: json['id']?.toString() ?? '',
      ticketNumber:
          json['ticket_number']?.toString() ?? json['ticketNumber']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? json['qrCode']?.toString() ?? '',
      rawJson: Map<String, dynamic>.from(json),
    );
  }
}
