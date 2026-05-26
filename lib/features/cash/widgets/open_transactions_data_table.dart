import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/open_transaction.dart';

/// Scrollable ticket table for cash shift modals.
class OpenTransactionsDataTable extends StatelessWidget {
  const OpenTransactionsDataTable({
    super.key,
    required this.transactions,
    this.durationColumnLabel = 'Waiting',
  });

  final List<OpenTransaction> transactions;
  final String durationColumnLabel;

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const _cellStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.jm();
    final dateFmt = DateFormat.MMMd();
    final now = DateTime.now();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scrollbar(
          thumbVisibility: transactions.length > 4,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F9F9)),
                headingTextStyle: _headerStyle,
                dataTextStyle: _cellStyle,
                dataRowMinHeight: 44,
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text('Ticket #', style: _headerStyle)),
                  DataColumn(label: Text('Plate No.', style: _headerStyle)),
                  DataColumn(label: Text('Vehicle', style: _headerStyle)),
                  DataColumn(label: Text('Time In', style: _headerStyle)),
                  DataColumn(
                    label: Text(durationColumnLabel, style: _headerStyle),
                  ),
                ],
                rows: [
                  for (var i = 0; i < transactions.length; i++)
                    DataRow(
                      color: WidgetStateProperty.all(
                        i.isEven ? const Color(0xFFF9F9F9) : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Text(transactions[i].ticketNumber, style: _cellStyle),
                        ),
                        DataCell(
                          Text(transactions[i].plateNumber, style: _cellStyle),
                        ),
                        DataCell(
                          Text(transactions[i].vehicleLabel, style: _cellStyle),
                        ),
                        DataCell(
                          Text(
                            '${dateFmt.format(transactions[i].timeIn.toLocal())} '
                            '${timeFmt.format(transactions[i].timeIn.toLocal())}',
                            style: _cellStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            OpenTransaction.formatDurationSince(
                              transactions[i].timeIn.toLocal(),
                              now,
                            ),
                            style: _cellStyle,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
