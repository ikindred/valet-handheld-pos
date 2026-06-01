import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:image_v3/image_v3.dart' as img;
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';

import '../time/philippine_time.dart';
import 'check_in_receipt_data.dart';
import 'checkout_receipt_data.dart';
import 'esc_pos_text_sanitize.dart';
import 'receipt_print_format.dart';

/// Bitmap receipt tuned for 2 in (58 mm) portable printers (e.g. HPRT HM-A300).
class ReceiptRasterBuilder {
  ReceiptRasterBuilder({this.paperSize = PaperSize.mm58});

  final PaperSize paperSize;

  static const _black = 0xff000000;
  static const _white = 0xffffffff;

  /// Side margins on the paper (dots).
  int get _marginH => paperSize == PaperSize.mm58 ? 14 : 10;

  /// Extra inset so wrapped text never touches the edge.
  int get _padH => 6;

  /// Reserve dots on the right so wrapped lines never clip (HM-A300).
  static const _wrapSafetyPx = 48;

  static const _checkInLogoWidthPx = 160;
  static const _checkInValueColumnX = 100;
  static const _checkInQrSizePx = 200;

  int get _widthPx => paperSize.width;

  int get _contentWidthPx => _widthPx - (_marginH + _padH) * 2;

  int get _textWidthPx => _contentWidthPx - _wrapSafetyPx;

  List<int> buildEscPosBytes(CheckInReceiptData data, CapabilityProfile profile) {
    final out = <int>[];
    for (var part = 1; part <= 3; part++) {
      out.addAll(buildCheckInPartEscPosBytes(data, profile, part));
    }
    return out;
  }

  /// Single tear-off part (1 = attendant, 2 = customer+QR, 3 = key tag).
  List<int> buildCheckInPartEscPosBytes(
    CheckInReceiptData data,
    CapabilityProfile profile,
    int part, {
    img.Image? logo,
  }) {
    final gen = Generator(paperSize, profile);
    return [
      ...gen.reset(),
      ...gen.image(
        buildCheckInPartImage(data, part, logo: logo),
        align: PosAlign.center,
      ),
      ...gen.feed(3),
    ];
  }

  List<int> buildCheckoutEscPosBytes(
    CheckoutReceiptData data,
    CapabilityProfile profile, {
    img.Image? logo,
  }) {
    final gen = Generator(paperSize, profile);
    return [
      ...gen.reset(),
      ...gen.image(buildCheckoutImage(data, logo: logo), align: PosAlign.center),
      ...gen.feed(3),
      ...gen.cut(),
    ];
  }

  img.Image buildCheckoutImage(
    CheckoutReceiptData data, {
    img.Image? logo,
  }) {
    return _render(_checkoutBlocks(data, logo: logo));
  }

  List<_Block> _checkoutBlocks(
    CheckoutReceiptData data, {
    img.Image? logo,
  }) {
    return [
      ..._brandHeader(data.branchName, logo: logo),
      const _RuleBlock(),
      const _TextBlock('CHECKOUT RECEIPT', center: true, bold: true),
      const _RuleBlock(),
      const _GapBlock(6),
      _TwoColumnFieldBlock('Ticket', data.ticketNumber),
      _TwoColumnFieldBlock('Plate', data.plateNumber),
      if (data.vehicleReceiptLine.isNotEmpty &&
          data.vehicleReceiptLine != '-' &&
          data.vehicleReceiptLine != '—')
        _TwoColumnFieldBlock('Vehicle', data.vehicleReceiptLine),
      if (data.invoiceNumber != null && data.invoiceNumber!.isNotEmpty)
        _TwoColumnFieldBlock('Invoice', data.invoiceNumber!),
      _TwoColumnFieldBlock('Time in', data.timeInLabel),
      _TwoColumnFieldBlock('Time out', data.timeOutLabel),
      _TwoColumnFieldBlock('Duration', data.durationLabel),
      _TwoColumnFieldBlock('Parking', data.slotLine),
      _TwoColumnFieldBlock('Valet in', data.valetInLabel),
      _TwoColumnFieldBlock('Returning Valet Attendant', data.valetOutLabel),
      const _GapBlock(4),
      const _RuleBlock(),
      const _GapBlock(4),
      _TwoColumnFieldBlock(data.flatRateLabel, data.flatPesosLabel),
      if (data.succeedingLabel.isNotEmpty)
        _TwoColumnFieldBlock(data.succeedingLabel, data.succeedingPesosLabel),
      if (data.showOvernight)
        _TwoColumnFieldBlock(data.overnightRowLabel, data.overnightPesosLabel),
      _TwoColumnFieldBlock('Total', data.totalPesosLabel, boldValue: true),
      _TwoColumnFieldBlock('Cash tendered', data.tenderedPesosLabel),
      _TwoColumnFieldBlock(
        'Change',
        data.changePesosLabel,
        boldValue: data.changeIsNonZero,
      ),
      ..._checkoutFooter(mallHours: data.mallHours),
      const _GapBlock(4),
    ];
  }

  List<_Block> _brandHeader(String branchName, {img.Image? logo}) {
    final branch = sanitizeEscPosText(branchName);
    return [
      if (logo != null) _LogoBlock(logo),
      const _TextBlock(
        ReceiptTemplateCopy.brandName,
        center: true,
        bold: true,
      ),
      if (branch.isNotEmpty && branch.toLowerCase() != 'valet master')
        _TextBlock(branch, center: true),
      const _GapBlock(6),
      const _RuleBlock(),
      const _GapBlock(8),
    ];
  }

  List<_Block> _checkoutFooter({required String mallHours}) => [
        const _GapBlock(6),
        const _RuleBlock(),
        const _GapBlock(4),
        const _TextBlock(
          ReceiptTemplateCopy.thankYouLine,
          center: true,
          bold: true,
        ),
        _TextBlock(mallHours, center: true, small: true),
      ];

  List<int> buildTestEscPosBytes({
    required CapabilityProfile profile,
    required String branchName,
    required String staffLabel,
    img.Image? logo,
  }) {
    final gen = Generator(paperSize, profile);
    final blocks = <_Block>[
      ..._brandHeader(branchName, logo: logo),
      _TextBlock(staffLabel),
      const _GapBlock(8),
    ];
    return [
      ...gen.reset(),
      ...gen.image(_render(blocks), align: PosAlign.center),
      ...gen.feed(2),
      ...gen.cut(),
    ];
  }

  img.Image buildCheckInImage(CheckInReceiptData data) {
    final blocks = <_Block>[
      ..._blocksForPart(data, 1),
      ..._blocksForPart(data, 2),
      ..._blocksForPart(data, 3),
    ];
    return _render(blocks);
  }

  img.Image buildCheckInPartImage(
    CheckInReceiptData data,
    int part, {
    img.Image? logo,
  }) {
    return _render(_blocksForPart(data, part, logo: logo));
  }

  List<_Block> _checkInBrandHeader(String branchName, {img.Image? logo}) {
    final branch = sanitizeEscPosText(branchName);
    return [
      if (logo != null)
        _LogoBlock(logo, displayWidth: _checkInLogoWidthPx)
      else
        const _GapBlock(8),
      const _TextBlock(
        ReceiptTemplateCopy.brandName,
        center: true,
        bold: true,
      ),
      if (branch.isNotEmpty && branch.toLowerCase() != 'valet master')
        _TextBlock(branch, center: true),
      const _GapBlock(6),
      const _DashedRuleBlock(),
      const _GapBlock(8),
    ];
  }

  static String _checkInQrPayload(CheckInReceiptData data) {
    final qr = data.qrCode?.trim();
    if (qr != null && qr.isNotEmpty) return qr;
    return data.ticket.id.trim();
  }

  List<_Block> _blocksForPart(
    CheckInReceiptData data,
    int part, {
    img.Image? logo,
  }) {
    final header = _checkInBrandHeader(data.branchName, logo: logo);
    return switch (part) {
      1 => [
          ...header,
          ..._checkInSection(
            title: 'ATTENDANT COPY',
            data: data,
            includeQr: false,
          ),
          const _GapBlock(10),
        ],
      2 => [
          ...header,
          ..._checkInSection(
            title: 'CUSTOMER COPY',
            data: data,
            includeQr: true,
            includeThankYouFooter: true,
          ),
          const _GapBlock(32),
        ],
      3 => [
          ...header,
          ..._keyTagBlocks(data),
          const _GapBlock(10),
        ],
      _ => throw ArgumentError.value(part, 'part', 'must be 1, 2, or 3'),
    };
  }

  List<_Block> _checkInSection({
    required String title,
    required CheckInReceiptData data,
    required bool includeQr,
    bool includeThankYouFooter = false,
  }) {
    final ticketNo = _checkInQrPayload(data);
    final plate = data.ticket.plateNumber.trim();
    final vehicle = _vehicleLine(data);
    final slot = _slotLine(data);
    final belongings = _belongingsLine(data.ticket.personalBelongings);
    final damage = _damageLine(data.ticket.damageMarkers);
    final timeIn = _formatCheckIn(data.ticket.checkInAt);
    final contact = (data.contactNumber ?? data.ticket.cellphoneNumber).trim();
    final driver = data.ticket.driverIn?.trim() ?? '';

    final blocks = <_Block>[
      const _TextBlock('CHECK-IN', bold: true),
      _TextBlock(title, bold: true),
      const _DashedRuleBlock(),
      const _GapBlock(6),
      _CheckInRowBlock('Ticket', ticketNo),
      _CheckInRowBlock('Plate', plate.isEmpty ? 'N/A' : plate),
      if (vehicle.isNotEmpty) _CheckInRowBlock('Vehicle', vehicle),
      if (data.valetTypeLabel?.trim().isNotEmpty == true)
        _CheckInRowBlock('Type', data.valetTypeLabel!.trim()),
      if (slot.isNotEmpty) _CheckInRowBlock('Slot', slot),
      _CheckInRowBlock('Time in', timeIn),
      const _DashedRuleBlock(),
      const _GapBlock(4),
      if (contact.isNotEmpty) _CheckInRowBlock('Contact', contact),
      if (data.customerName?.trim().isNotEmpty == true)
        _CheckInRowBlock('Guest', data.customerName!.trim()),
      if (driver.isNotEmpty) _CheckInRowBlock('Valet', driver),
      if (contact.isNotEmpty ||
          data.customerName?.trim().isNotEmpty == true ||
          driver.isNotEmpty)
        const _DashedRuleBlock(),
      if (belongings.isNotEmpty) ...[
        const _GapBlock(4),
        _LabeledWrapBlock('Belongings', belongings),
      ],
      if (damage.isNotEmpty) _LabeledWrapBlock('Damage', damage),
      if (data.specialRequest?.trim().isNotEmpty == true)
        _LabeledWrapBlock('Notes', data.specialRequest!.trim()),
      _CheckInRowBlock(
        'Signature',
        data.hasSignature ? 'Signed' : 'Pending',
      ),
    ];

    if (includeQr && ticketNo.isNotEmpty) {
      blocks.addAll([
        const _DashedRuleBlock(),
        const _GapBlock(8),
        _QrBlock(ticketNo, sizePx: _checkInQrSizePx),
        const _GapBlock(8),
        const _TextBlock(
          ReceiptTemplateCopy.scanQrHint,
          center: true,
        ),
        const _DashedRuleBlock(),
      ]);
    } else {
      blocks.add(const _DashedRuleBlock());
    }

    if (includeThankYouFooter) {
      blocks.addAll([
        const _GapBlock(4),
        const _TextBlock(
          ReceiptTemplateCopy.thankYouLine,
          center: true,
          bold: true,
        ),
        _TextBlock(data.mallHours, center: true),
      ]);
    }

    return blocks;
  }

  List<_Block> _keyTagBlocks(CheckInReceiptData data) {
    final ticketId = _checkInQrPayload(data);
    final plate = data.ticket.plateNumber.trim();
    final slot = _slotLine(data);
    return [
      const _TextBlock('CHECK-IN', bold: true),
      const _TextBlock('KEY TAG', bold: true),
      const _DashedRuleBlock(),
      const _GapBlock(6),
      _TextBlock(ticketId, bold: true, large: true),
      if (plate.isNotEmpty) _TextBlock(plate, bold: true, large: true),
      if (slot.isNotEmpty) _TextBlock(slot),
    ];
  }

  img.Image _render(List<_Block> blocks) {
    final heights = blocks.map((b) => b.measure(this)).toList();
    final gaps = math.max(0, blocks.length - 1) * 2;
    final totalH = _marginH * 2 + heights.fold<int>(0, (a, b) => a + b) + gaps;

    final out = img.Image(_widthPx, math.max(totalH, 100).toInt());
    img.fill(out, _white);

    var y = _marginH;
    for (var i = 0; i < blocks.length; i++) {
      y += blocks[i].paint(this, out, y);
      if (i < blocks.length - 1) y += 2;
    }
    return out;
  }

  // ── Layout primitives ─────────────────────────────────────────────

  List<String> wrapText(
    String text,
    img.BitmapFont font, {
    int? maxWidthPx,
  }) {
    final safe = math.max(48, maxWidthPx ?? _textWidthPx);
    return _wrap(sanitizeEscPosText(text), safe, font);
  }

  int textWidth(String text, img.BitmapFont font) {
    var w = 0;
    for (final c in sanitizeEscPosText(text).codeUnits) {
      final ch = font.characters[c];
      if (ch != null) w += ch.xadvance;
    }
    return w;
  }

  int textBlockHeight(
    String text,
    img.BitmapFont font, {
    int lineHeight = 17,
  }) {
    final rows = wrapText(text, font);
    return math.max(lineHeight, rows.length * lineHeight);
  }

  void paintTextRows(
    img.Image out,
    List<String> rows,
    int x,
    int y,
    img.BitmapFont font, {
    int lineHeight = 17,
    int color = _black,
  }) {
    var yy = y;
    for (final row in rows) {
      img.drawString(out, font, x, yy, row, color: color);
      yy += lineHeight;
    }
  }

  void paintCenteredRows(
    img.Image out,
    List<String> rows,
    int y,
    img.BitmapFont font, {
    int lineHeight = 17,
    int color = _black,
  }) {
    var yy = y;
    for (final row in rows) {
      img.drawStringCentered(out, font, row, y: yy, color: color);
      yy += lineHeight;
    }
  }

  void paintRule(img.Image out, int y, {bool thick = false}) {
    final y0 = y + 4;
    final left = _marginH;
    final right = _widthPx - _marginH;
    if (thick) {
      img.drawLine(out, left, y0, right, y0, _black);
      img.drawLine(out, left, y0 + 1, right, y0 + 1, _black);
    } else {
      for (var x = left; x < right; x += 4) {
        img.drawLine(out, x, y0, math.min(x + 2, right), y0, _black);
      }
    }
  }

  void paintDashedRule(img.Image out, int y) {
    final left = _marginH;
    final right = _widthPx - _marginH;
    for (var x = left; x < right; x += 6) {
      img.drawLine(out, x, y, math.min(x + 2, right), y, _black);
    }
  }

  void paintQr(img.Image out, String data, int topY, {int? sizePx}) {
    final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final maxQr = _textWidthPx - 20;
    final fallback = paperSize == PaperSize.mm58 ? 110 : 140;
    final targetPx = sizePx ?? math.min(maxQr, fallback);
    final module = math.max(1, targetPx ~/ qrImage.moduleCount);
    final size = qrImage.moduleCount * module;
    final left = (_widthPx - size) ~/ 2;

    for (var row = 0; row < qrImage.moduleCount; row++) {
      for (var col = 0; col < qrImage.moduleCount; col++) {
        if (!qrImage.isDark(row, col)) continue;
        img.fillRect(
          out,
          left + col * module,
          topY + row * module,
          left + (col + 1) * module - 1,
          topY + (row + 1) * module - 1,
          _black,
        );
      }
    }
  }

  List<String> _wrap(String text, int maxPx, img.BitmapFont font) {
    if (text.isEmpty) return [''];
    final rows = <String>[];

    for (final paragraph in text.split('\n')) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) {
        rows.add('');
        continue;
      }

      final words = trimmed.split(RegExp(r'\s+'));
      var current = '';

      for (final word in words) {
        if (word.isEmpty) continue;

        if (_textWidth(word, font) > maxPx) {
          if (current.isNotEmpty) {
            rows.add(current);
            current = '';
          }
          rows.addAll(_splitLongWord(word, maxPx, font));
          continue;
        }

        final candidate = current.isEmpty ? word : '$current $word';
        if (_textWidth(candidate, font) <= maxPx) {
          current = candidate;
        } else {
          if (current.isNotEmpty) rows.add(current);
          current = word;
        }
      }
      if (current.isNotEmpty) rows.add(current);
    }

    return rows.isEmpty ? [''] : rows;
  }

  List<String> _splitLongWord(String word, int maxPx, img.BitmapFont font) {
    final parts = <String>[];
    var chunk = '';
    for (var i = 0; i < word.length; i++) {
      final next = '$chunk${word[i]}';
      if (_textWidth(next, font) <= maxPx) {
        chunk = next;
      } else {
        if (chunk.isNotEmpty) parts.add(chunk);
        chunk = word[i];
      }
    }
    if (chunk.isNotEmpty) parts.add(chunk);
    return parts.isEmpty ? [word.substring(0, 1)] : parts;
  }

  int _textWidth(String text, img.BitmapFont font) {
    var w = 0;
    for (final c in text.codeUnits) {
      final ch = font.characters[c];
      if (ch != null) w += ch.xadvance;
    }
    return w;
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
    return DateFormat('MMM d, yyyy h:mm a').format(ph);
  }
}

// ── Block types (measure + paint) ─────────────────────────────────

abstract class _Block {
  const _Block();

  int measure(ReceiptRasterBuilder b);
  int paint(ReceiptRasterBuilder b, img.Image out, int y);
}

class _GapBlock extends _Block {
  const _GapBlock(this.px);
  final int px;

  @override
  int measure(ReceiptRasterBuilder b) => px;

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) => px;
}

class _RuleBlock extends _Block {
  const _RuleBlock({this.thick = false});
  final bool thick;

  @override
  int measure(ReceiptRasterBuilder b) => thick ? 12 : 10;

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    b.paintRule(out, y, thick: thick);
    return measure(b);
  }
}

class _DashedRuleBlock extends _Block {
  const _DashedRuleBlock();

  @override
  int measure(ReceiptRasterBuilder b) => 13;

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    b.paintDashedRule(out, y + 6);
    return measure(b);
  }
}

class _TextBlock extends _Block {
  const _TextBlock(
    this.text, {
    this.center = false,
    this.bold = false,
    this.small = false,
    this.large = false,
  });

  final String text;
  final bool center;
  final bool bold;
  final bool small;
  final bool large;

  img.BitmapFont _font(ReceiptRasterBuilder b) =>
      large ? img.arial_24 : img.arial_14;

  int _lineH() {
    if (large) return 26;
    return small ? 15 : 17;
  }

  @override
  int measure(ReceiptRasterBuilder b) =>
      b.textBlockHeight(text, _font(b), lineHeight: _lineH());

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final font = _font(b);
    final rows = b.wrapText(text, font);
    final lh = _lineH();
    final x = b._marginH + b._padH;
    if (center) {
      b.paintCenteredRows(out, rows, y, font, lineHeight: lh);
      if (bold) {
        b.paintCenteredRows(out, rows, y, font, lineHeight: lh);
      }
    } else {
      b.paintTextRows(out, rows, x, y, font, lineHeight: lh);
      if (bold) {
        b.paintTextRows(out, rows, x + 1, y, font, lineHeight: lh);
      }
    }
    return measure(b);
  }
}

class _LogoBlock extends _Block {
  const _LogoBlock(this.image, {this.displayWidth});

  final img.Image image;
  final int? displayWidth;

  int _targetWidth(ReceiptRasterBuilder b) =>
      displayWidth ?? math.min(image.width, b._textWidthPx);

  @override
  int measure(ReceiptRasterBuilder b) {
    final targetW = _targetWidth(b);
    final h = (image.height * targetW / image.width).round();
    return h + 10;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final targetW = _targetWidth(b);
    final resized = image.width == targetW
        ? image
        : img.copyResize(image, width: targetW);
    final x = (b._widthPx - resized.width) ~/ 2;
    img.drawImage(out, resized, dstX: x, dstY: y);
    return measure(b);
  }
}

class _CheckInRowBlock extends _Block {
  const _CheckInRowBlock(this.label, this.value);

  final String label;
  final String value;

  @override
  int measure(ReceiptRasterBuilder b) {
    final valueText = sanitizeEscPosText(value);
    final maxValueW =
        b._widthPx - b._marginH - b._padH - ReceiptRasterBuilder._checkInValueColumnX;
    final rows = b.wrapText(valueText, img.arial_14, maxWidthPx: maxValueW);
    return 17 + rows.length * 17 + 2;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final left = b._marginH + b._padH;
    final valueX = ReceiptRasterBuilder._checkInValueColumnX;
    final labelText = sanitizeEscPosText(label);
    final valueText = sanitizeEscPosText(value);
    final valueFont = img.arial_14;

    img.drawString(out, img.arial_14, left, y + 1, '$labelText ');

    final maxValueW = b._widthPx - b._marginH - b._padH - valueX;
    final valueRows = b.wrapText(valueText, valueFont, maxWidthPx: maxValueW);
    b.paintTextRows(out, valueRows, valueX, y, valueFont, lineHeight: 17);
    return measure(b);
  }
}

class _LabeledWrapBlock extends _Block {
  const _LabeledWrapBlock(this.label, this.value);

  final String label;
  final String value;

  @override
  int measure(ReceiptRasterBuilder b) {
    final labelText = '${sanitizeEscPosText(label)}:';
    final valueText = sanitizeEscPosText(value);
    final labelH = b.textBlockHeight(labelText, img.arial_14, lineHeight: 17);
    final valueH = b.textBlockHeight(
      valueText,
      img.arial_14,
      lineHeight: 17,
    );
    return labelH + valueH + 4;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final left = b._marginH + b._padH;
    final labelText = '${sanitizeEscPosText(label)}:';
    final valueText = sanitizeEscPosText(value);
    img.drawString(out, img.arial_14, left, y + 1, labelText);
    final labelH = b.textBlockHeight(labelText, img.arial_14, lineHeight: 17);
    final rows = b.wrapText(valueText, img.arial_14);
    b.paintTextRows(out, rows, left, y + labelH, img.arial_14, lineHeight: 17);
    return measure(b);
  }
}

class _TwoColumnFieldBlock extends _Block {
  const _TwoColumnFieldBlock(
    this.label,
    this.value, {
    this.boldValue = false,
  });

  final String label;
  final String value;
  final bool boldValue;

  @override
  int measure(ReceiptRasterBuilder b) {
    final left = b._marginH + b._padH;
    final right = b._widthPx - b._marginH - b._padH;
    final labelText = '${sanitizeEscPosText(label)}:';
    final valueText = sanitizeEscPosText(value);
    final valueFont = boldValue ? img.arial_24 : img.arial_14;
    final lineH = boldValue ? 22 : 17;
    final labelW = b.textWidth(labelText, img.arial_14);
    final valueW = b.textWidth(valueText, valueFont);
    if (valueW <= right - left - labelW - 4) return lineH + 4;
    final rows = b.wrapText(valueText, valueFont);
    return lineH + rows.length * lineH + 4;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final left = b._marginH + b._padH;
    final right = b._widthPx - b._marginH - b._padH;
    final labelText = '${sanitizeEscPosText(label)}:';
    final valueText = sanitizeEscPosText(value);
    final valueFont = boldValue ? img.arial_24 : img.arial_14;
    final lineH = boldValue ? 22 : 17;

    img.drawString(out, img.arial_14, left, y + 1, labelText);

    final labelW = b.textWidth(labelText, img.arial_14);
    final valueW = b.textWidth(valueText, valueFont);
    if (valueW <= right - left - labelW - 4) {
      img.drawString(
        out,
        valueFont,
        right - valueW,
        y + 1,
        valueText,
      );
      return measure(b);
    }

    final rows = b.wrapText(valueText, valueFont);
    b.paintTextRows(out, rows, left, y + lineH, valueFont, lineHeight: lineH);
    return measure(b);
  }
}

class _QrBlock extends _Block {
  const _QrBlock(this.data, {this.sizePx});

  final String data;
  final int? sizePx;

  int _qrPixelSize(ReceiptRasterBuilder b) {
    final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final maxQr = b._textWidthPx - 20;
    final fallback = b.paperSize == PaperSize.mm58 ? 110 : 140;
    final targetPx = sizePx ?? math.min(maxQr, fallback);
    final module = math.max(1, targetPx ~/ qrImage.moduleCount);
    return qrImage.moduleCount * module;
  }

  @override
  int measure(ReceiptRasterBuilder b) => _qrPixelSize(b);

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    b.paintQr(out, data, y, sizePx: sizePx);
    return measure(b);
  }
}
