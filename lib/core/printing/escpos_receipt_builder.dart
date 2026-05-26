import 'dart:convert';

import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:image_v3/image_v3.dart' as img;
import 'package:intl/intl.dart';

import '../time/philippine_time.dart';
import 'check_in_receipt_data.dart';
import 'checkout_receipt_data.dart';
import 'esc_pos_text_sanitize.dart';
import 'receipt_print_format.dart';

class EscPosReceiptBuilder {
  EscPosReceiptBuilder(this.profile, {this.paperSize = PaperSize.mm58});

  final CapabilityProfile profile;
  final PaperSize paperSize;

  Generator _generator() => Generator(paperSize, profile);

  bool get _isNarrow => paperSize == PaperSize.mm58;

  int get _charsPerLine => switch (paperSize) {
    PaperSize.mm80 => 48,
    PaperSize.mm72 => 38,
    PaperSize.mm58 => 32,
    _ => 32,
  };

  QRSize get _qrSize =>
      paperSize == PaperSize.mm58 ? QRSize.Size4 : QRSize.Size8;

  int _lineCharCount({PosTextSize width = PosTextSize.size1}) {
    final scale = width.value.clamp(1, 4);
    return (_charsPerLine / scale).floor().clamp(10, _charsPerLine);
  }

  List<int> buildTestReceipt({
    required String branchName,
    required String staffLabel,
    img.Image? logo,
  }) {
    final gen = _generator();
    final bytes = <int>[];
    bytes.addAll(gen.reset());
    bytes.addAll(_printerInit());
    bytes.addAll(_brandHeader(gen, branchName, logo: logo));
    bytes.addAll(_printLines(staffLabel));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  /// Checkout payment receipt (single tear-off).
  List<int> buildCheckoutReceipt(CheckoutReceiptData data, {img.Image? logo}) {
    final gen = _generator();
    final bytes = <int>[];

    bytes.addAll(gen.reset());
    bytes.addAll(_printerInit());
    bytes.addAll(_brandHeader(gen, data.branchName, logo: logo));
    bytes.addAll(_checkoutSectionTitle());
    bytes.addAll(_labeledRow('Ticket', data.ticketNumber));
    bytes.addAll(_labeledRow('Plate', data.plateNumber));
    if (data.vehicleReceiptLine.isNotEmpty &&
        data.vehicleReceiptLine != '-' &&
        data.vehicleReceiptLine != '—') {
      bytes.addAll(_labeledRow('Vehicle', data.vehicleReceiptLine));
    }
    if (data.invoiceNumber != null && data.invoiceNumber!.isNotEmpty) {
      bytes.addAll(_labeledRow('Invoice', data.invoiceNumber!));
    }
    bytes.addAll(_labeledRow('Time in', data.timeInLabel));
    bytes.addAll(_labeledRow('Time out', data.timeOutLabel));
    bytes.addAll(_labeledRow('Duration', data.durationLabel));
    bytes.addAll(_labeledRow('Parking', data.slotLine));
    bytes.addAll(_labeledRow('Valet in', data.valetInLabel));
    bytes.addAll(_labeledRow('Valet out', data.valetOutLabel));
    bytes.addAll(_hr());
    bytes.addAll(_moneyRow(data.flatRateLabel, data.flatPesosLabel));
    if (data.succeedingLabel.isNotEmpty) {
      bytes.addAll(_moneyRow(data.succeedingLabel, data.succeedingPesosLabel));
    }
    if (data.showOvernight) {
      bytes.addAll(_moneyRow('Overnight', data.overnightPesosLabel));
    }
    bytes.addAll(_moneyRow('Total', data.totalPesosLabel, bold: true));
    bytes.addAll(_moneyRow('Cash tendered', data.tenderedPesosLabel));
    bytes.addAll(
      _moneyRow('Change', data.changePesosLabel, bold: data.changeIsNonZero),
    );
    bytes.addAll(_checkoutFooter(mallHours: data.mallHours));

    bytes.addAll(gen.feed(3));
    bytes.addAll(gen.cut());
    return bytes;
  }

  List<int> _moneyRow(String label, String amount, {bool bold = false}) =>
      _labeledRow(label, amount, bold: bold);

  List<int> _checkoutSectionTitle() => [
    ..._hr(),
    ..._printLines('CHECKOUT RECEIPT', align: PosAlign.center, bold: true),
    ..._hr(),
  ];

  List<int> _checkoutFooter({required String mallHours}) => [
    ..._hr(),
    ..._printLines(
      ReceiptTemplateCopy.orDisclaimerNote,
      align: PosAlign.center,
    ),
    ..._printLines(
      ReceiptTemplateCopy.thankYouLine,
      align: PosAlign.center,
      bold: true,
    ),
    ..._printLines(mallHours, align: PosAlign.center),
  ];

  /// Label left, value right (space-padded on wide paper).
  List<int> _labeledRow(String label, String value, {bool bold = false}) {
    if (_isNarrow) {
      return [
        ..._printLines(label, bold: true),
        ..._printLines(value, bold: bold),
      ];
    }
    return _printLines(_twoColumnText('$label:', value), bold: bold);
  }

  String _twoColumnText(String label, String value) {
    final l = sanitizeEscPosText(label);
    final v = sanitizeEscPosText(value);
    return _formatTwoColumn(l, v, _charsPerLine);
  }

  static String _formatTwoColumn(String label, String value, int width) {
    final gap = width - label.length - value.length;
    if (gap >= 1) {
      return '$label${' ' * gap}$value';
    }
    if (label.length >= width) {
      return '$label\n${value.length >= width ? value.substring(0, width) : value}';
    }
    return '$label\n${' ' * (width - value.length).clamp(0, width)}$value';
  }

  /// Check-in ticket: all three parts concatenated (legacy / tests).
  List<int> buildCheckInReceipt(CheckInReceiptData data) {
    final bytes = <int>[];
    for (var part = 1; part <= 3; part++) {
      bytes.addAll(buildCheckInPartReceipt(data, part: part));
    }
    return bytes;
  }

  /// Single tear-off part (1 = attendant, 2 = customer+QR, 3 = key tag).
  List<int> buildCheckInPartReceipt(
    CheckInReceiptData data, {
    required int part,
    img.Image? logo,
  }) {
    final gen = _generator();
    final bytes = <int>[];

    final ticketId = data.ticket.id.trim();
    final plate = data.ticket.plateNumber.trim();
    final vehicleLine = _vehicleLine(data);
    final slotLine = _slotLine(data);
    final belongings = _belongingsLine(data.ticket.personalBelongings);
    final damage = _damageLine(data.ticket.damageMarkers);
    final timeIn = _formatCheckIn(data.ticket.checkInAt);
    final contact = (data.contactNumber ?? data.ticket.cellphoneNumber).trim();
    final driver = data.ticket.driverIn?.trim() ?? '';

    bytes.addAll(gen.reset());
    bytes.addAll(_printerInit());
    bytes.addAll(_brandHeader(gen, data.branchName, logo: logo));

    switch (part) {
      case 1:
        bytes.addAll(
          _section(
            gen,
            title: 'ATTENDANT COPY',
            ticketId: ticketId,
            qrPayload: (data.qrCode ?? ticketId).trim(),
            plate: plate,
            vehicleLine: vehicleLine,
            slotLine: slotLine,
            timeIn: timeIn,
            contact: contact,
            driver: driver,
            customerName: data.customerName,
            valetType: data.valetTypeLabel,
            special: data.specialRequest,
            belongings: belongings,
            damage: damage,
            signatureSigned: data.hasSignature,
            mallHours: data.mallHours,
            includeThankYouFooter: false,
          ),
        );
      case 2:
        bytes.addAll(
          _section(
            gen,
            title: 'CUSTOMER COPY',
            ticketId: ticketId,
            qrPayload: (data.qrCode ?? ticketId).trim(),
            plate: plate,
            vehicleLine: vehicleLine,
            slotLine: slotLine,
            timeIn: timeIn,
            contact: contact,
            driver: driver,
            customerName: data.customerName,
            valetType: data.valetTypeLabel,
            special: data.specialRequest,
            belongings: belongings,
            damage: damage,
            signatureSigned: data.hasSignature,
            mallHours: data.mallHours,
            includeThankYouFooter: true,
            includeQr: true,
          ),
        );
      case 3:
        bytes.addAll(
          _keyTag(ticketId: ticketId, plate: plate, slotLine: slotLine),
        );
      default:
        throw ArgumentError.value(part, 'part', 'must be 1, 2, or 3');
    }

    bytes.addAll(gen.feed(6));
    return bytes;
  }

  List<int> _brandHeader(Generator gen, String branchName, {img.Image? logo}) {
    final out = <int>[];
    if (logo != null) {
      const targetW = 220;
      final resized = logo.width == targetW
          ? logo
          : img.copyResize(logo, width: targetW);
      final grayscale = img.grayscale(resized);
      out.addAll(gen.imageRaster(grayscale, align: PosAlign.center));
      out.addAll(gen.feed(1));
    }
    out.addAll(_printLines('SPiD', align: PosAlign.center, bold: true));
    out.addAll(
      _printLines('SMART PARKING TECHNOLOGIES', align: PosAlign.center),
    );
    out.addAll(gen.feed(1));
    out.addAll(
      _printLines(
        ReceiptTemplateCopy.brandName,
        align: PosAlign.center,
        bold: true,
      ),
    );
    final branch = sanitizeEscPosText(branchName);
    if (branch.isNotEmpty && branch.toLowerCase() != 'valet master') {
      out.addAll(_printLines(branch, align: PosAlign.center));
    }
    out.addAll(_hr());
    return out;
  }

  List<int> _receiptFooter({
    required String mallHours,
    required bool includeThankYou,
    bool includePrintedAt = true,
  }) {
    final out = <int>[..._hr()];
    out.addAll(
      _printLines(ReceiptTemplateCopy.orDisclaimerNote, align: PosAlign.center),
    );
    if (includeThankYou) {
      out.addAll(
        _printLines(
          ReceiptTemplateCopy.thankYouLine,
          align: PosAlign.center,
          bold: true,
        ),
      );
      out.addAll(_printLines(mallHours, align: PosAlign.center));
    }
    if (includePrintedAt) {
      out.addAll(
        _printLines(
          ReceiptPrintFormat.printedAtLabel(),
          align: PosAlign.center,
        ),
      );
    }
    return out;
  }

  List<int> _section(
    Generator gen, {
    required String title,
    required String ticketId,
    required String qrPayload,
    required String plate,
    required String vehicleLine,
    required String slotLine,
    required String timeIn,
    required String contact,
    required String driver,
    required String belongings,
    required String damage,
    required bool signatureSigned,
    required String mallHours,
    required bool includeThankYouFooter,
    String? customerName,
    String? valetType,
    String? special,
    bool includeQr = false,
  }) {
    final out = <int>[
      ..._printLines('CHECK-IN', align: PosAlign.center, bold: true),
      ..._printLines(title, align: PosAlign.center, bold: true),
      ..._highlightField('Ticket No.', ticketId),
      ..._highlightField('Plate', plate.isEmpty ? 'N/A' : plate),
      if (vehicleLine.isNotEmpty) ..._field('Vehicle', vehicleLine),
      if (valetType != null && valetType.trim().isNotEmpty)
        ..._field('Valet type', valetType.trim()),
      if (slotLine.isNotEmpty) ..._field('Parking', slotLine),
      ..._field('Time in', timeIn),
    ];

    if (contact.isNotEmpty ||
        (customerName != null && customerName.trim().isNotEmpty) ||
        driver.isNotEmpty) {
      out.addAll(gen.feed(1));
      if (contact.isNotEmpty) out.addAll(_field('Contact', contact));
      if (customerName != null && customerName.trim().isNotEmpty) {
        out.addAll(_field('Guest', customerName.trim()));
      }
      if (driver.isNotEmpty) out.addAll(_field('Valet driver', driver));
    }

    out.addAll(gen.feed(1));
    if (belongings.isNotEmpty) out.addAll(_field('Belongings', belongings));
    if (damage.isNotEmpty) out.addAll(_field('Damage', damage));
    if (special != null && special.trim().isNotEmpty) {
      out.addAll(_field('Notes', special.trim()));
    }
    out.addAll(_field('Signature', signatureSigned ? 'Signed' : 'Pending'));

    if (includeQr && qrPayload.isNotEmpty) {
      out.addAll(gen.feed(2));
      out.addAll(_escAlign(PosAlign.center));
      out.addAll(gen.qrcode(qrPayload, size: _qrSize, align: PosAlign.center));
      out.addAll(gen.feed(2));
      out.addAll(_escAlign(PosAlign.left));
      out.addAll(
        _printLines(ReceiptTemplateCopy.scanQrHint, align: PosAlign.center),
      );
    }

    out.addAll(
      _receiptFooter(
        mallHours: mallHours,
        includeThankYou: includeThankYouFooter,
        includePrintedAt: false,
      ),
    );
    return out;
  }

  List<int> _highlightField(String label, String value) {
    if (!_isNarrow) {
      return _printLines(_twoColumnText('$label:', value), bold: true);
    }
    return [
      ..._printLines(label, bold: true),
      ..._printLines(value, bold: true, height: PosTextSize.size2),
    ];
  }

  List<int> _keyTag({
    required String ticketId,
    required String plate,
    required String slotLine,
  }) {
    return [
      ..._printLines('CHECK-IN', align: PosAlign.center, bold: true),
      ..._printLines('KEY TAG', align: PosAlign.center, bold: true),
      ..._printLines(
        ticketId,
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
      if (plate.isNotEmpty) ..._printLines(plate, align: PosAlign.center),
      if (slotLine.isNotEmpty) ..._printLines(slotLine, align: PosAlign.center),
    ];
  }

  /// Narrow printers: label on one line, value on the next (fits 2 in receipt mode).
  List<int> _field(String label, String value) {
    if (!_isNarrow) {
      return _printLines(_twoColumnText('$label:', value));
    }
    return [..._printLines(label, bold: true), ..._printLines(value)];
  }

  List<int> _hr() => _printLines(
    List.filled(_charsPerLine, '-').join(),
    align: PosAlign.center,
  );

  /// Plain ESC/POS lines (no GS absolute positioning — works on HPRT / most BT printers).
  List<int> _printLines(
    String text, {
    PosAlign align = PosAlign.left,
    bool bold = false,
    PosTextSize height = PosTextSize.size1,
    PosTextSize width = PosTextSize.size1,
    int linesAfter = 0,
  }) {
    final out = <int>[];
    final maxChars = _lineCharCount(width: width);
    final usePaddedAlign = _isNarrow && align != PosAlign.left;

    out.addAll(_escAlign(PosAlign.left));

    final enlarged = height != PosTextSize.size1 || width != PosTextSize.size1;
    if (enlarged) {
      out.addAll(_escTextSize(height, width));
    }
    if (bold) {
      out.addAll(const [0x1B, 0x45, 0x01]);
    }

    for (final line in _wrapText(sanitizeEscPosText(text), maxChars)) {
      final printed = usePaddedAlign ? _padLine(line, maxChars, align) : line;
      out.addAll('$printed\n'.codeUnits);
    }

    if (bold) {
      out.addAll(const [0x1B, 0x45, 0x00]);
    }
    if (enlarged) {
      out.addAll(_escTextSize(PosTextSize.size1, PosTextSize.size1));
    }

    for (var i = 0; i < linesAfter; i++) {
      out.add(0x0A);
    }
    return out;
  }

  static String _padLine(String line, int width, PosAlign align) {
    if (line.length >= width) {
      return line.substring(0, width);
    }
    final pad = width - line.length;
    return switch (align) {
      PosAlign.center => '${' ' * (pad ~/ 2)}$line',
      PosAlign.right => '${' ' * pad}$line',
      _ => line,
    };
  }

  List<int> _escAlign(PosAlign align) {
    final code = switch (align) {
      PosAlign.center => 1,
      PosAlign.right => 2,
      _ => 0,
    };
    return [0x1B, 0x61, code];
  }

  List<int> _escTextSize(PosTextSize height, PosTextSize width) {
    final n = 16 * (width.value - 1) + (height.value - 1);
    return [0x1D, 0x21, n];
  }

  /// Reset alignment/size; on 2 in paper also clear left margin (HPRT HM-A300).
  List<int> _printerInit() {
    final out = <int>[
      ..._escAlign(PosAlign.left),
      ..._escTextSize(PosTextSize.size1, PosTextSize.size1),
      ...const [0x1B, 0x45, 0x00],
    ];
    if (_isNarrow) {
      out.addAll(const [0x1D, 0x4C, 0x00, 0x00]);
    }
    return out;
  }

  static List<String> _wrapText(String text, int width) {
    if (text.isEmpty) return [''];
    final lines = <String>[];
    final paragraphs = text.split('\n');
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) {
        lines.add('');
        continue;
      }
      final words = trimmed.split(RegExp(r'\s+'));
      var current = '';
      for (final word in words) {
        if (word.length > width) {
          if (current.isNotEmpty) {
            lines.add(current);
            current = '';
          }
          for (var i = 0; i < word.length; i += width) {
            final end = (i + width > word.length) ? word.length : i + width;
            lines.add(word.substring(i, end));
          }
          continue;
        }
        final candidate = current.isEmpty ? word : '$current $word';
        if (candidate.length > width) {
          lines.add(current);
          current = word;
        } else {
          current = candidate;
        }
      }
      if (current.isNotEmpty) lines.add(current);
    }
    return lines.isEmpty ? [''] : lines;
  }

  static String _vehicleLine(CheckInReceiptData data) {
    final parts = <String>[
      data.ticket.vehicleBrand.trim(),
      data.ticket.vehicleColor.trim(),
      if (data.ticket.vehicleType.trim().isNotEmpty)
        data.ticket.vehicleType.trim(),
    ]..removeWhere((s) => s.isEmpty);
    return parts.join(' / ');
  }

  static String _slotLine(CheckInReceiptData data) {
    final a = data.parkingLevel?.trim() ?? '';
    final b = data.parkingSlot?.trim() ?? '';
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a / $b';
  }

  static String _belongingsLine(String jsonRaw) {
    try {
      final decoded = jsonDecode(jsonRaw);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.map((e) => e.toString()).join(', ');
      }
    } catch (_) {}
    return '';
  }

  static String _damageLine(String jsonRaw) {
    try {
      final decoded = jsonDecode(jsonRaw);
      if (decoded is! List || decoded.isEmpty) return '';
      final parts = <String>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final type = (item['type'] ?? '').toString();
        final zone = (item['zone'] ?? '').toString().trim();
        if (type.isEmpty) continue;
        parts.add(zone.isEmpty ? type : '$type / $zone');
      }
      return parts.join('; ');
    } catch (_) {
      return '';
    }
  }

  static String _formatCheckIn(String iso) {
    if (iso.trim().isEmpty) return iso;
    final ph = PhilippineTime.fromApiIso(iso);
    return DateFormat('MMM d, yyyy - h:mm a').format(ph);
  }
}
