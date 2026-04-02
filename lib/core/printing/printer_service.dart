import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';

enum PrinterConnection {
  bluetooth,
  usb,
  network,
}

class PrinterDevice {
  const PrinterDevice({
    required this.id,
    required this.name,
    required this.connection,
  });

  final String id;
  final String name;
  final PrinterConnection connection;
}

abstract interface class PrinterService {
  Future<List<PrinterDevice>> discover();

  Future<void> connect(PrinterDevice device);

  Future<void> disconnect();

  Future<void> printBytes(List<int> bytes);

  CapabilityProfile get profile;
}

