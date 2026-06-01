import '../../../data/local/db/app_database.dart';

/// Lightweight row for cash modals (not a full domain model).
class OpenTransaction {
  const OpenTransaction({
    required this.ticketId,
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleColor,
    required this.timeIn,
  });

  final String ticketId;
  final String ticketNumber;
  final String plateNumber;
  final String? vehicleBrand;
  final String? vehicleColor;
  final DateTime timeIn;

  factory OpenTransaction.fromTicket(Ticket t) {
    final parsed = DateTime.tryParse(t.checkInAt);
    return OpenTransaction(
      ticketId: t.id,
      ticketNumber: t.id,
      plateNumber: t.plateNumber,
      vehicleBrand: t.vehicleBrand,
      vehicleColor: t.vehicleColor,
      timeIn: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get vehicleLabel {
    final b = vehicleBrand?.trim() ?? '';
    return b.isEmpty ? '—' : b;
  }

  static String formatDurationSince(DateTime timeIn, DateTime now) {
    final d = now.difference(timeIn);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}
