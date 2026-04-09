import '../../../data/local/db/app_database.dart';

/// Lightweight row for cash modals (not a full domain model).
class OpenTransaction {
  const OpenTransaction({
    required this.transactionId,
    required this.ticketNumber,
    required this.plateNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.timeIn,
  });

  final int transactionId;
  final String ticketNumber;
  final String plateNumber;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final DateTime timeIn;

  factory OpenTransaction.fromRow(ValetTransaction t) {
    return OpenTransaction(
      transactionId: t.id,
      ticketNumber: t.ticketNumber,
      plateNumber: t.plateNumber,
      vehicleBrand: t.vehicleBrand,
      vehicleModel: t.vehicleModel,
      vehicleColor: t.vehicleColor,
      timeIn: DateTime.fromMillisecondsSinceEpoch(t.timeIn * 1000, isUtc: true),
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
