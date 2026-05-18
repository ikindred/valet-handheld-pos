import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:image_v3/image_v3.dart' as img;
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';

import '../time/philippine_time.dart';
import 'check_in_receipt_data.dart';
import 'esc_pos_text_sanitize.dart';

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
    int part,
  ) {
    final gen = Generator(paperSize, profile);
    return [
      ...gen.reset(),
      ...gen.image(buildCheckInPartImage(data, part), align: PosAlign.center),
      ...gen.feed(3),
    ];
  }

  List<int> buildTestEscPosBytes({
    required CapabilityProfile profile,
    required String branchName,
    required String staffLabel,
  }) {
    final gen = Generator(paperSize, profile);
    final blocks = <_Block>[
      _HeaderBlock(sanitizeEscPosText(branchName)),
      _TextBlock('VALET MASTER', center: true, bold: true),
      const _GapBlock(4),
      const _RuleBlock(),
      const _GapBlock(6),
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

  img.Image buildCheckInPartImage(CheckInReceiptData data, int part) {
    return _render(_blocksForPart(data, part));
  }

  List<_Block> _blocksForPart(CheckInReceiptData data, int part) {
    final header = <_Block>[
      _HeaderBlock(sanitizeEscPosText(data.branchName)),
      _TextBlock('VALET MASTER', center: true, bold: true),
      const _GapBlock(6),
      const _RuleBlock(),
      const _GapBlock(8),
    ];
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
          ),
          const _GapBlock(10),
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
  }) {
    final ticketId = data.ticket.id.trim();
    final plate = data.ticket.plateNumber.trim();
    final vehicle = _vehicleLine(data);
    final slot = _slotLine(data);
    final belongings = _belongingsLine(data.ticket.personalBelongings);
    final damage = _damageLine(data.ticket.damageMarkers);
    final timeIn = _formatCheckIn(data.ticket.checkInAt);
    final contact = (data.contactNumber ?? data.ticket.cellphoneNumber).trim();
    final driver = data.ticket.driverIn?.trim() ?? '';

    final blocks = <_Block>[
      _SectionTitleBlock(title),
      const _GapBlock(4),
      _FieldBlock('Ticket No.', ticketId, highlight: true),
      _FieldBlock('Plate', plate.isEmpty ? 'N/A' : plate),
      if (vehicle.isNotEmpty) _FieldBlock('Vehicle', vehicle),
      if (data.valetTypeLabel?.trim().isNotEmpty == true)
        _FieldBlock('Valet type', data.valetTypeLabel!.trim()),
      if (slot.isNotEmpty) _FieldBlock('Parking', slot),
      _FieldBlock('Time in', timeIn),
      if (contact.isNotEmpty) _FieldBlock('Contact', contact),
      if (data.customerName?.trim().isNotEmpty == true)
        _FieldBlock('Guest', data.customerName!.trim()),
      if (driver.isNotEmpty) _FieldBlock('Valet driver', driver),
      if (belongings.isNotEmpty) _FieldBlock('Belongings', belongings),
      if (damage.isNotEmpty) _FieldBlock('Damage', damage),
      if (data.specialRequest?.trim().isNotEmpty == true)
        _FieldBlock('Notes', data.specialRequest!.trim()),
      _FieldBlock(
        'Signature',
        data.hasSignature ? 'Signed' : 'Pending',
      ),
    ];

    final qrPayload = (data.qrCode ?? ticketId).trim();
    if (includeQr && qrPayload.isNotEmpty) {
      blocks.addAll([
        const _GapBlock(8),
        _QrBlock(qrPayload),
        const _GapBlock(4),
        const _TextBlock('Scan at check-out', center: true, small: true),
      ]);
    }

    blocks.addAll([
      const _GapBlock(6),
      const _TextBlock(
        'This is not an Official Receipt (OR).',
        center: true,
        small: true,
      ),
    ]);
    return blocks;
  }

  List<_Block> _keyTagBlocks(CheckInReceiptData data) {
    final ticketId = data.ticket.id.trim();
    final plate = data.ticket.plateNumber.trim();
    final slot = _slotLine(data);
    return [
      _KeyTagBlock(
        ticketId: ticketId,
        plate: plate,
        slot: slot,
      ),
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

  List<String> wrapText(String text, img.BitmapFont font) {
    final safe = math.max(48, _textWidthPx);
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

  void paintQr(img.Image out, String data, int topY) {
    final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final maxQr = _textWidthPx - 20;
    final targetPx = math.min(maxQr, paperSize == PaperSize.mm58 ? 110 : 140);
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
    return DateFormat('MMM d, yyyy - h:mm a').format(ph);
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

class _TextBlock extends _Block {
  const _TextBlock(
    this.text, {
    this.center = false,
    this.bold = false,
    this.small = false,
  });

  final String text;
  final bool center;
  final bool bold;
  final bool small;

  img.BitmapFont _font(ReceiptRasterBuilder b) => img.arial_14;

  int _lineH() => small ? 15 : 17;

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
    } else {
      b.paintTextRows(out, rows, x, y, font, lineHeight: lh);
    }
    return measure(b);
  }
}

class _HeaderBlock extends _Block {
  const _HeaderBlock(this.text);
  final String text;

  @override
  int measure(ReceiptRasterBuilder b) => b.textBlockHeight(text, img.arial_24, lineHeight: 26) + 4;

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final rows = b.wrapText(text, img.arial_24);
    b.paintCenteredRows(out, rows, y, img.arial_24, lineHeight: 26);
    return measure(b);
  }
}

class _SectionTitleBlock extends _Block {
  const _SectionTitleBlock(this.text);
  final String text;

  @override
  int measure(ReceiptRasterBuilder b) => 24;

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    const h = 22;
    final left = b._marginH;
    final right = b._widthPx - b._marginH;
    img.fillRect(out, left, y, right, y + h, ReceiptRasterBuilder._black);
    final row = b.wrapText(text, img.arial_14).first;
    img.drawStringCentered(
      out,
      img.arial_14,
      row,
      y: y + 5,
      color: ReceiptRasterBuilder._white,
    );
    return measure(b);
  }
}

class _FieldBlock extends _Block {
  const _FieldBlock(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  static const _labelIndent = 4;

  @override
  int measure(ReceiptRasterBuilder b) {
    final labelH = b.textBlockHeight(label.toUpperCase(), img.arial_14, lineHeight: 15);
    final valueFont = highlight ? img.arial_24 : img.arial_14;
    final valueH = b.textBlockHeight(value, valueFont, lineHeight: highlight ? 22 : 17);
    return labelH + valueH + 6;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final x = b._marginH + b._padH;
    final labelRows = b.wrapText(label.toUpperCase(), img.arial_14);
    b.paintTextRows(out, labelRows, x, y, img.arial_14, lineHeight: 15);

    var yy = y + labelRows.length * 15 + 2;
    final valueFont = highlight ? img.arial_24 : img.arial_14;
    final valueRows = b.wrapText(value, valueFont);
    final valueLh = highlight ? 22 : 17;
    b.paintTextRows(
      out,
      valueRows,
      x + _labelIndent,
      yy,
      valueFont,
      lineHeight: valueLh,
    );
    return measure(b);
  }
}

class _QrBlock extends _Block {
  const _QrBlock(this.data);
  final String data;

  @override
  int measure(ReceiptRasterBuilder b) {
    final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
    final qrImage = QrImage(qrCode);
    final maxQr = b._textWidthPx - 20;
    final targetPx = math.min(maxQr, b.paperSize == PaperSize.mm58 ? 110 : 140);
    final module = math.max(1, targetPx ~/ qrImage.moduleCount);
    return qrImage.moduleCount * module + 8;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    b.paintQr(out, data, y);
    return measure(b);
  }
}

class _KeyTagBlock extends _Block {
  const _KeyTagBlock({
    required this.ticketId,
    required this.plate,
    required this.slot,
  });

  final String ticketId;
  final String plate;
  final String slot;

  @override
  int measure(ReceiptRasterBuilder b) {
    var h = 12 + b.textBlockHeight('KEY TAG', img.arial_14, lineHeight: 16);
    h += 6 + b.textBlockHeight(ticketId, img.arial_24, lineHeight: 26);
    if (plate.isNotEmpty) {
      h += 4 + b.textBlockHeight(plate, img.arial_14, lineHeight: 17);
    }
    if (slot.isNotEmpty) {
      h += 2 + b.textBlockHeight(slot, img.arial_14, lineHeight: 17);
    }
    return h + 12;
  }

  @override
  int paint(ReceiptRasterBuilder b, img.Image out, int y) {
    final left = b._marginH;
    final right = b._widthPx - b._marginH;
    final totalH = measure(b);

    img.drawLine(out, left, y, right, y, ReceiptRasterBuilder._black);
    img.drawLine(out, left, y + totalH, right, y + totalH, ReceiptRasterBuilder._black);
    img.drawLine(out, left, y, left, y + totalH, ReceiptRasterBuilder._black);
    img.drawLine(out, right, y, right, y + totalH, ReceiptRasterBuilder._black);

    var yy = y + 10;
    b.paintCenteredRows(
      out,
      b.wrapText('KEY TAG', img.arial_14),
      yy,
      img.arial_14,
      lineHeight: 16,
    );
    yy += 22;
    b.paintCenteredRows(
      out,
      b.wrapText(ticketId, img.arial_24),
      yy,
      img.arial_24,
      lineHeight: 26,
    );
    yy += 28;
    if (plate.isNotEmpty) {
      b.paintCenteredRows(
        out,
        b.wrapText(plate, img.arial_14),
        yy,
        img.arial_14,
      );
      yy += 18;
    }
    if (slot.isNotEmpty) {
      b.paintCenteredRows(
        out,
        b.wrapText(slot, img.arial_14),
        yy,
        img.arial_14,
      );
    }
    return totalH;
  }
}
