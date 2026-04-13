import '../../data/local/db/app_database.dart';

/// Stub until Bluetooth printer SDK is provided.
abstract interface class ValetPrintService {
  Future<void> printCheckInTicket(Ticket ticket);
}

class NoopValetPrintService implements ValetPrintService {
  @override
  Future<void> printCheckInTicket(Ticket ticket) async {
    // TODO: Implement when client provides Bluetooth printer device and SDK
  }
}
