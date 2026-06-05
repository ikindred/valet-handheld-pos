import 'package:equatable/equatable.dart';

import 'reports_format.dart';

/// One row in the Currently Parked / Transactions table.
class ReportsTicketRow extends Equatable {
  const ReportsTicketRow({
    required this.ticketId,
    required this.plate,
    this.vrNo = '—',
    required this.vehicle,
    required this.timeIn,
    required this.duration,
    required this.slot,
    required this.status,
    this.serverTransactionId,
    this.timeInDisplay,
    this.durationDisplay,
    this.timeOut,
    this.fee,
    this.cashTendered,
    this.hasPendingVoid = false,
    this.isVoided = false,
  });

  /// Display ticket number (e.g. `TKT-0123`).
  final String ticketId;

  /// Server UUID for `GET /api/v1/transactions/{id}`.
  final String? serverTransactionId;

  final String plate;

  /// Valet receipt number (`vr_no`); `—` when unset.
  final String vrNo;

  final String vehicle;
  final DateTime timeIn;

  /// When set (API `time_in`), shown instead of formatting [timeIn].
  final String? timeInDisplay;

  final DateTime? timeOut;
  final Duration duration;

  /// When set (API `duration_display`), shown instead of formatting [duration].
  final String? durationDisplay;

  final String slot;
  final ReportsTicketRowStatus status;
  final double? fee;

  /// API `cash_tendered` when checkout recorded cash payment.
  final double? cashTendered;

  /// True when void-at-intake is queued locally (offline sync pending).
  final bool hasPendingVoid;

  /// True when the transaction is voided (`status: void`).
  final bool isVoided;

  /// Route / detail key: server id when available, else local ticket number.
  String get detailId {
    final sid = serverTransactionId?.trim() ?? '';
    if (sid.isNotEmpty) return sid;
    return ticketId.trim();
  }

  String get timeInLabel =>
      timeInDisplay?.trim().isNotEmpty == true
          ? timeInDisplay!.trim()
          : ReportsFormat.timeInLabel(timeIn);

  String get timeOutLabel =>
      timeOut != null ? ReportsFormat.timeInLabel(timeOut!) : '—';

  String get durationLabel =>
      durationDisplay?.trim().isNotEmpty == true
          ? durationDisplay!.trim()
          : ReportsFormat.durationLabel(duration);

  bool get isLongStay => status == ReportsTicketRowStatus.longStay;

  @override
  List<Object?> get props => [
        ticketId,
        serverTransactionId,
        plate,
        vrNo,
        vehicle,
        timeIn,
        timeInDisplay,
        timeOut,
        duration,
        durationDisplay,
        slot,
        status,
        fee,
        cashTendered,
        hasPendingVoid,
        isVoided,
      ];
}

/// Shift earnings breakdown (Cash + Today side panel).
class ReportsShiftEarnings extends Equatable {
  const ReportsShiftEarnings({
    this.flatCount = 0,
    this.flatUnit = 0,
    this.flatTotal = 0,
    this.extraHourCount = 0,
    this.extraUnit = 0,
    this.extraTotal = 0,
    this.overnightTotal = 0,
    this.lostTicketTotal = 0,
    this.total = 0,
  });

  static const empty = ReportsShiftEarnings();

  final int flatCount;
  final double flatUnit;
  final double flatTotal;
  final int extraHourCount;
  final double extraUnit;
  final double extraTotal;
  final double overnightTotal;
  final double lostTicketTotal;
  final double total;

  bool get hasOvernight => overnightTotal > 0.009;
  bool get hasLostTicket => lostTicketTotal > 0.009;

  @override
  List<Object?> get props => [
        flatCount,
        flatUnit,
        flatTotal,
        extraHourCount,
        extraUnit,
        extraTotal,
        overnightTotal,
        lostTicketTotal,
        total,
      ];
}

/// Status alert under shift earnings (success / warning).
class ReportsAlert extends Equatable {
  const ReportsAlert({
    required this.message,
    required this.isWarning,
    this.ticketId,
  });

  final String message;
  final bool isWarning;
  final String? ticketId;

  @override
  List<Object?> get props => [message, isWarning, ticketId];
}
