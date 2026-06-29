import 'dart:convert';

import 'package:intl/intl.dart';

import '../../../core/formatting/peso_currency.dart';
import '../../../data/local/db/app_database.dart';

/// User-facing row for unsynced or failed sync queue data.
class PendingSyncItem {
  const PendingSyncItem({
    required this.id,
    required this.status,
    required this.title,
    required this.subtitle,
    this.operation,
    this.retryCount = 0,
    this.createdAt,
    this.isOrphan = false,
  });

  final String id;
  final PendingSyncItemStatus status;
  final String title;
  final String subtitle;
  /// Queue operation, e.g. `checkin`, `checkout/finalize` — used when title is hidden.
  final String? operation;
  final int retryCount;
  final DateTime? createdAt;
  final bool isOrphan;

  /// Express cashier hides check-in / check-out labels; normal cashier keeps them.
  String? displayTitle({required bool isExpressCashier}) {
    if (isExpressCashier && _isTicketFlowTitle(title)) return null;
    return title;
  }

  static bool _isTicketFlowTitle(String title) {
    return title == 'Check-in' || title == 'Check-out';
  }

  String get statusLabel {
    if (status == PendingSyncItemStatus.failed) {
      if (retryCount > 0) return 'Failed · $retryCount ${retryCount == 1 ? 'retry' : 'retries'}';
      return 'Failed';
    }
    if (isOrphan) return 'Pending · not queued';
    return 'Pending';
  }

  String? get createdLabel {
    final dt = createdAt;
    if (dt == null) return null;
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = DateFormat('h:mm a').format(dt);
    if (sameDay) return 'Today $timeStr';
    return '${DateFormat('MMM d').format(dt)} $timeStr';
  }

  static PendingSyncItem fromQueueRow(
    SyncQueueData row, {
    Ticket? ticket,
    Shift? shift,
  }) {
    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {}

    final title = _titleFor(row.queueTableName, row.operation);
    final subtitle = _subtitleFor(
      table: row.queueTableName,
      operation: row.operation,
      payload: payload,
      ticket: ticket,
      shift: shift,
      recordId: row.recordId,
    );

    return PendingSyncItem(
      id: row.id,
      status: row.syncStatus == 'failed'
          ? PendingSyncItemStatus.failed
          : PendingSyncItemStatus.pending,
      title: title,
      subtitle: subtitle,
      operation: row.operation,
      retryCount: row.retryCount,
      createdAt: _parseCreatedAt(row.createdAt),
      isOrphan: false,
    );
  }

  static PendingSyncItem fromOrphanTicket(Ticket ticket) {
    final plate = ticket.plateNumber.trim();
    final vr = ticket.vrNo?.trim() ?? '';
    final parts = <String>[
      if (plate.isNotEmpty) plate,
      if (vr.isNotEmpty) 'VR $vr',
      if (ticket.fee != null && ticket.fee! > 0) _peso0.format(ticket.fee),
    ];

    return PendingSyncItem(
      id: 'orphan:${ticket.id}',
      status: PendingSyncItemStatus.pending,
      title: ticket.isExpressCashier ? 'Express ticket' : 'Ticket',
      subtitle: parts.isEmpty ? ticket.id : parts.join(' · '),
      createdAt: _parseCreatedAt(ticket.checkInAt.isNotEmpty
          ? ticket.checkInAt
          : ticket.createdAt),
      isOrphan: true,
    );
  }

  static String _titleFor(String table, String operation) {
    if (table == 'shifts') {
      return operation == 'create' ? 'Open cash session' : 'Close cash session';
    }
    if (table == 'tickets') {
      switch (operation) {
        case 'checkin':
          return 'Check-in';
        case 'checkout/finalize':
          return 'Check-out';
        case 'void':
          return 'Void ticket';
        case 'patch/plate':
          return 'Plate update';
        case 'update':
          return 'Ticket update';
        default:
          return 'Ticket';
      }
    }
    return '$table · $operation';
  }

  static String _subtitleFor({
    required String table,
    required String operation,
    required Map<String, dynamic>? payload,
    required Ticket? ticket,
    required Shift? shift,
    required String recordId,
  }) {
    final parts = <String>[];

    if (table == 'tickets') {
      final plate = _firstNonEmpty([
        ticket?.plateNumber,
        payload?['plate_number']?.toString(),
        _vehiclePlate(payload?['vehicle']),
      ]);
      if (plate != null) parts.add(plate);

      final vr = _firstNonEmpty([
        ticket?.vrNo,
        payload?['vr_no']?.toString(),
      ]);
      if (vr != null) parts.add('VR $vr');

      final amount = ticket?.fee ?? _optionalDouble(payload?['amount']);
      if (amount != null && amount > 0) {
        parts.add(_peso0.format(amount));
      }

      if (operation == 'checkout/finalize' && parts.isEmpty) {
        parts.add('Ticket $recordId');
      }
    } else if (table == 'shifts') {
      final opening = shift?.openingFloat ??
          _optionalDouble(payload?['opening_float']);
      final closing = shift?.closingCash ??
          _optionalDouble(payload?['closing_cash']);
      if (operation == 'create' && opening != null) {
        parts.add('Float ${_peso0.format(opening)}');
      } else if (operation == 'update' && closing != null) {
        parts.add('Cash ${_peso0.format(closing)}');
      }
      if (parts.isEmpty) parts.add(recordId);
    }

    if (parts.isEmpty) return recordId;
    return parts.join(' · ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static String? _vehiclePlate(dynamic vehicle) {
    if (vehicle is! Map) return null;
    final plate = vehicle['plate_number'] ?? vehicle['plate'];
    final s = plate?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static double? _optionalDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static DateTime? _parseCreatedAt(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }
}

enum PendingSyncItemStatus { pending, failed }

final _peso0 = PesoCurrency.currency(decimalDigits: 0);
