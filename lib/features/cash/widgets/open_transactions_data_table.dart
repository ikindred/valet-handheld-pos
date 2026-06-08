import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/philippine_time.dart';
import '../models/open_transaction.dart';

/// Scrollable check-in table for cash shift modals (no checkout columns).
class OpenTransactionsDataTable extends StatelessWidget {
  const OpenTransactionsDataTable({
    super.key,
    required this.transactions,
    this.durationColumnLabel = 'Parked For',
  });

  final List<OpenTransaction> transactions;
  final String durationColumnLabel;

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const _cellStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const _subCellStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const _headers = [
    'Ticket #',
    'Plate No.',
    'Vehicle',
    'Type',
    'Slot',
    'Checked In',
  ];

  static int _flexForColumn(int index) => switch (index) {
        0 => 3,
        1 => 2,
        2 => 3,
        3 => 2,
        4 => 2,
        5 => 2,
        6 => 2,
        _ => 2,
      };

  @override
  Widget build(BuildContext context) {
    final now = PhilippineTime.now();
    final dateFmt = DateFormat.MMMd();
    final timeFmt = DateFormat.jm();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scrollbar(
          thumbVisibility: transactions.length > 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderRow(durationColumnLabel: durationColumnLabel),
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  _DataRow(
                    tx: transactions[i],
                    shaded: i.isEven,
                    dateFmt: dateFmt,
                    timeFmt: timeFmt,
                    now: now,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.durationColumnLabel});

  final String durationColumnLabel;

  @override
  Widget build(BuildContext context) {
    final labels = [...OpenTransactionsDataTable._headers, durationColumnLabel];
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: OpenTransactionsDataTable._flexForColumn(i),
              child: Padding(
                padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
                child: Text(
                  labels[i].toUpperCase(),
                  style: OpenTransactionsDataTable._headerStyle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.tx,
    required this.shaded,
    required this.dateFmt,
    required this.timeFmt,
    required this.now,
  });

  final OpenTransaction tx;
  final bool shaded;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final parkedFor = OpenTransaction.formatParkedDuration(tx.checkInAtRaw, now);

    return Container(
      color: shaded ? const Color(0xFFFCFCFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(0),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tx.ticketNumber,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenTransactionsDataTable._cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(1),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tx.plateNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenTransactionsDataTable._cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(2),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tx.vehicleLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenTransactionsDataTable._cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(3),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tx.vehicleTypeLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OpenTransactionsDataTable._cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(4),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                tx.slot,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenTransactionsDataTable._cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(5),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFmt.format(tx.timeIn),
                    style: OpenTransactionsDataTable._cellStyle,
                  ),
                  Text(
                    timeFmt.format(tx.timeIn),
                    style: OpenTransactionsDataTable._subCellStyle,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: OpenTransactionsDataTable._flexForColumn(6),
            child: Text(
              parkedFor,
              style: OpenTransactionsDataTable._cellStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE8831A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
