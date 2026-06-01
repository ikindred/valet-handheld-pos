import 'package:intl/intl.dart';

/// Display helpers for Reports (Figma Today / Transactions tables).
abstract final class ReportsFormat {
  static String durationLabel(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes < 1) return '<1m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String timeInLabel(DateTime time) => DateFormat.jm().format(time);

  static String slotCode({String? slot, String? parkingJson}) {
    var s = slot?.trim() ?? '';
    if (s.isEmpty && parkingJson != null && parkingJson.trim().isNotEmpty) {
      try {
        final decoded = parkingJson.trim();
        if (decoded.startsWith('{')) {
          final match = RegExp(r'"slot"\s*:\s*"([^"]+)"').firstMatch(decoded);
          s = match?.group(1)?.trim() ?? '';
        }
      } catch (_) {}
    }
    return s.isEmpty ? '—' : s;
  }
}

enum ReportsTicketRowStatus { parked, longStay, checkedOut }

extension ReportsTicketRowStatusX on ReportsTicketRowStatus {
  String get label => switch (this) {
        ReportsTicketRowStatus.parked => 'Parked',
        ReportsTicketRowStatus.longStay => 'Long Stay',
        ReportsTicketRowStatus.checkedOut => 'Checked Out',
      };
}
