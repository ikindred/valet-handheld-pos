/// Payload for [TicketService.createTicket] (valet_tickets row).
class CheckInFormData {
  const CheckInFormData({
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleColor,
    this.vehicleType = '',
    this.driverIn,
    required this.cellphoneNumber,
    required this.damageMarkersJson,
    required this.personalBelongingsJson,
  });

  final String plateNumber;
  final String vehicleBrand;
  final String vehicleColor;

  /// Optional; persisted on `tickets.vehicle_type` when set (per-vehicle-type rates TBD).
  final String vehicleType;

  /// Valet attendant who received the vehicle (optional).
  final String? driverIn;
  final String cellphoneNumber;
  final String damageMarkersJson;
  final String personalBelongingsJson;

  bool get isComplete =>
      plateNumber.isNotEmpty &&
      vehicleBrand.isNotEmpty &&
      vehicleColor.isNotEmpty &&
      cellphoneNumber.isNotEmpty;
}
