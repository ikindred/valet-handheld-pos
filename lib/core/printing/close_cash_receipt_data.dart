import '../../features/cash/models/close_cash_shift_stats.dart';
import '../time/philippine_time.dart';
import 'receipt_print_format.dart';

/// Thermal payload for end-of-shift close cash receipt.
class CloseCashReceiptData {
  const CloseCashReceiptData({
    required this.branchName,
    required this.areaName,
    required this.cashierName,
    required this.openedAtLabel,
    required this.closedAtLabel,
    required this.checkoutCount,
    required this.vehicleTypeStats,
    required this.activeCheckInCount,
    required this.actualCashLabel,
  });

  final String branchName;
  final String areaName;
  final String cashierName;
  final String openedAtLabel;
  final String closedAtLabel;
  final int checkoutCount;
  final List<CloseCashVehicleTypeStat> vehicleTypeStats;
  final int activeCheckInCount;
  final String actualCashLabel;

  String get headerBranchLine {
    final branch = branchName.trim();
    final area = areaName.trim();
    if (branch.isEmpty && area.isEmpty) return 'Valet Master';
    if (area.isEmpty) return branch;
    if (branch.isEmpty) return area;
    return '$branch / $area';
  }

  factory CloseCashReceiptData.fromClose({
    required String branch,
    required String area,
    required String cashierName,
    required String openedAtIso,
    required String closedAtIso,
    required CloseCashShiftStats stats,
    required int activeCheckInCount,
    required double actualCash,
  }) {
    final opened = PhilippineTime.fromApiIso(openedAtIso);
    final closed = PhilippineTime.fromApiIso(closedAtIso);
    return CloseCashReceiptData(
      branchName: branch.trim(),
      areaName: area.trim(),
      cashierName: cashierName.trim().isEmpty ? '—' : cashierName.trim(),
      openedAtLabel: ReceiptPrintFormat.dateTimeLabel(opened),
      closedAtLabel: ReceiptPrintFormat.dateTimeLabel(closed),
      checkoutCount: stats.checkoutCount,
      vehicleTypeStats: stats.vehicleTypes,
      activeCheckInCount: activeCheckInCount,
      actualCashLabel: ReceiptPrintFormat.pesoAmount(actualCash),
    );
  }
}
