import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';

/// Receipt width for ESC/POS layout (most portable printers use 58mm).
enum PrinterPaperWidth {
  mm58,
  mm80,
}

extension PrinterPaperWidthX on PrinterPaperWidth {
  PaperSize get paperSize => switch (this) {
        PrinterPaperWidth.mm58 => PaperSize.mm58,
        PrinterPaperWidth.mm80 => PaperSize.mm80,
      };

  String get label => switch (this) {
        PrinterPaperWidth.mm58 => '2 in (58 mm)',
        PrinterPaperWidth.mm80 => '3 in (80 mm)',
      };

  static PrinterPaperWidth fromStored(String? value) {
    return value == 'mm80' ? PrinterPaperWidth.mm80 : PrinterPaperWidth.mm58;
  }

  String get storageValue => switch (this) {
        PrinterPaperWidth.mm58 => 'mm58',
        PrinterPaperWidth.mm80 => 'mm80',
      };
}
