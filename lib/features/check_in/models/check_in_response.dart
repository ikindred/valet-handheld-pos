class CheckInResponse {
  const CheckInResponse({
    required this.id,
    required this.ticketNumber,
    required this.qrCode,
  });

  final String id;
  final String ticketNumber;
  final String qrCode;

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      id: json['id']?.toString() ?? '',
      ticketNumber:
          json['ticket_number']?.toString() ?? json['ticketNumber']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? json['qrCode']?.toString() ?? '',
    );
  }
}
