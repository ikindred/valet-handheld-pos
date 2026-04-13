import '../../../data/local/db/app_database.dart';

/// Lightweight row for cash modals (not a full domain model).
class OpenTransaction {
  const OpenTransaction({
    required this.ticketId,
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.timeIn,
  });

  final String ticketId;
  final String ticketNumber;
  final String plateNumber;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final DateTime timeIn;

  factory OpenTransaction.fromTicket(Ticket t) {
    final parsed = DateTime.tryParse(t.checkInAt);
    return OpenTransaction(
      ticketId: t.id,
      ticketNumber: t.id,
      plateNumber: t.plateNumber,
      vehicleBrand: t.vehicleBrand,
      vehicleModel: null,
      vehicleColor: t.vehicleColor,
      timeIn: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get vehicleLabel {
    final parts = [
      if (vehicleBrand != null && vehicleBrand!.trim().isNotEmpty)
        vehicleBrand!.trim(),
      if (vehicleModel != null && vehicleModel!.trim().isNotEmpty)
        vehicleModel!.trim(),
    ];
    if (parts.isEmpty) return '—';
    return parts.join(' ');
  }

  static String formatDurationSince(DateTime timeIn, DateTime now) {
    final d = now.difference(timeIn);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}
