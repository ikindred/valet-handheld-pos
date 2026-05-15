import 'dart:convert';

import 'package:flutter_esc_pos_utils_image_3/flutter_esc_pos_utils_image_3.dart';
import 'package:intl/intl.dart';

import 'check_in_receipt_data.dart';

class EscPosReceiptBuilder {
  EscPosReceiptBuilder(this.profile, {this.paperSize = PaperSize.mm58});

  final CapabilityProfile profile;
  final PaperSize paperSize;

  Generator _generator() => Generator(paperSize, profile);

  List<int> buildTestReceipt({
    required String branchName,
    required String staffLabel,
  }) {
    final gen = _generator();

    final bytes = <int>[];
    bytes.addAll(gen.reset());
    bytes.addAll(
      gen.text(
        branchName,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      gen.text('Valet Master', styles: const PosStyles(align: PosAlign.center)),
    );
    bytes.addAll(gen.hr());
    bytes.addAll(gen.text(staffLabel));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  /// Check-in ticket: attendant copy, customer QR stub, key tag.
  List<int> buildCheckInReceipt(CheckInReceiptData data) {
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
    bytes.addAll(_header(gen, data.branchName));

    bytes.addAll(
      _section(
        gen,
        title: 'ATTENDANT COPY',
        ticketId: ticketId,
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
      ),
    );

    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.hr(ch: '-'));

    bytes.addAll(
      _section(
        gen,
        title: 'CUSTOMER COPY',
        ticketId: ticketId,
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
        includeQr: true,
      ),
    );

    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.hr(ch: '-'));

    bytes.addAll(_keyTag(gen, ticketId: ticketId, plate: plate, slotLine: slotLine));

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  List<int> _header(Generator gen, String branchName) {
    return [
      ...gen.text(
        branchName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      ...gen.text(
        'VALET MASTER',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...gen.hr(),
    ];
  }

  List<int> _section(
    Generator gen, {
    required String title,
    required String ticketId,
    required String plate,
    required String vehicleLine,
    required String slotLine,
    required String timeIn,
    required String contact,
    required String driver,
    required String belongings,
    required String damage,
    required bool signatureSigned,
    String? customerName,
    String? valetType,
    String? special,
    bool includeQr = false,
  }) {
    final out = <int>[
      ...gen.text(
        title,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      ...gen.feed(1),
      ..._row(gen, 'Ticket', ticketId),
      ..._row(gen, 'Plate', plate.isEmpty ? '—' : plate),
      if (vehicleLine.isNotEmpty) ..._row(gen, 'Vehicle', vehicleLine),
      if (valetType != null && valetType.trim().isNotEmpty)
        ..._row(gen, 'Type', valetType.trim()),
      if (slotLine.isNotEmpty) ..._row(gen, 'Slot', slotLine),
      ..._row(gen, 'Time in', timeIn),
      if (contact.isNotEmpty) ..._row(gen, 'Contact', contact),
      if (customerName != null && customerName.trim().isNotEmpty)
        ..._row(gen, 'Guest', customerName.trim()),
      if (driver.isNotEmpty) ..._row(gen, 'Valet', driver),
      if (belongings.isNotEmpty) ..._row(gen, 'Belongings', belongings),
      if (damage.isNotEmpty) ..._row(gen, 'Damage', damage),
      if (special != null && special.trim().isNotEmpty)
        ..._row(gen, 'Notes', special.trim()),
      ..._row(
        gen,
        'Signature',
        signatureSigned ? 'Signed' : '—',
      ),
    ];

    if (includeQr && ticketId.isNotEmpty) {
      out.addAll(gen.feed(1));
      out.addAll(gen.qrcode(ticketId, size: QRSize.Size6));
      out.addAll(
        gen.text(
          'Scan at check-out',
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }

    out.addAll(
      gen.text(
        'NOTE: This is not an Official Receipt (OR).',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return out;
  }

  List<int> _keyTag(
    Generator gen, {
    required String ticketId,
    required String plate,
    required String slotLine,
  }) {
    return [
      ...gen.text(
        'KEY TAG',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      ...gen.feed(1),
      ...gen.text(
        ticketId,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      if (plate.isNotEmpty)
        ...gen.text(plate, styles: const PosStyles(align: PosAlign.center)),
      if (slotLine.isNotEmpty)
        ...gen.text(slotLine, styles: const PosStyles(align: PosAlign.center)),
    ];
  }

  List<int> _row(Generator gen, String label, String value) {
    return gen.text(
      '$label: $value',
      styles: const PosStyles(),
    );
  }

  static String _vehicleLine(CheckInReceiptData data) {
    final parts = <String>[
      data.ticket.vehicleBrand.trim(),
      data.ticket.vehicleColor.trim(),
      if (data.ticket.vehicleType.trim().isNotEmpty)
        data.ticket.vehicleType.trim(),
    ]..removeWhere((s) => s.isEmpty);
    return parts.join(' · ');
  }

  static String _slotLine(CheckInReceiptData data) {
    final a = data.parkingLevel?.trim() ?? '';
    final b = data.parkingSlot?.trim() ?? '';
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a · $b';
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
        parts.add(zone.isEmpty ? type : '$type · $zone');
      }
      return parts.join('; ');
    } catch (_) {
      return '';
    }
  }

  static String _formatCheckIn(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }
}
