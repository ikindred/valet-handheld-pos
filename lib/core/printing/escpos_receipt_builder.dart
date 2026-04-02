import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';

class EscPosReceiptBuilder {
  EscPosReceiptBuilder(this.profile);

  final CapabilityProfile profile;

  List<int> buildTestReceipt({
    required String branchName,
    required String staffLabel,
  }) {
    final gen = Generator(PaperSize.mm80, profile);

    final bytes = <int>[];
    bytes.addAll(gen.reset());
    bytes.addAll(gen.text(branchName, styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(gen.text('Valet Master', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.hr());
    bytes.addAll(gen.text(staffLabel));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}

