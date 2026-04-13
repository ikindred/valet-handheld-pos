import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/open_transaction.dart';

/// Shown when closing shift with vehicles still checked in under this shift.
class OpenTransactionsWarningModal extends StatelessWidget {
  const OpenTransactionsWarningModal({
    super.key,
    required this.openTransactions,
    required this.onCancel,
    required this.onConfirm,
  });

  final List<OpenTransaction> openTransactions;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required List<OpenTransaction> openTransactions,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OpenTransactionsWarningModal(
        openTransactions: openTransactions,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }

  static const _orange = Color(0xFFE8831A);

  @override
  Widget build(BuildContext context) {
    final n = openTransactions.length;
    final timeFmt = DateFormat.jm();
    final dateFmt = DateFormat.MMMd();
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertTriangle, color: _orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open tickets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3C3434),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are $n open ticket(s) in this shift. '
                          'They can be transferred when the next cashier opens shift (legacy flow).',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF9F9F9),
                    ),
                    dataRowMinHeight: 44,
                    columns: const [
                      DataColumn(label: Text('Ticket #')),
                      DataColumn(label: Text('Plate No.')),
                      DataColumn(label: Text('Vehicle')),
                      DataColumn(label: Text('Time In')),
                      DataColumn(label: Text('Duration')),
                    ],
                    rows: [
                      for (var i = 0; i < openTransactions.length; i++)
                        DataRow(
                          color: WidgetStateProperty.all(
                            i.isEven
                                ? const Color(0xFFF9F9F9)
                                : Colors.white,
                          ),
                          cells: [
                            DataCell(Text(openTransactions[i].ticketNumber)),
                            DataCell(Text(openTransactions[i].plateNumber)),
                            DataCell(Text(openTransactions[i].vehicleLabel)),
                            DataCell(Text(
                              '${dateFmt.format(openTransactions[i].timeIn.toLocal())} '
                              '${timeFmt.format(openTransactions[i].timeIn.toLocal())}',
                            )),
                            DataCell(Text(
                              OpenTransaction.formatDurationSince(
                                openTransactions[i].timeIn.toLocal(),
                                now,
                              ),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The next cashier will see these transactions when they open their shift.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onConfirm,
                    child: const Text('Yes, Close Shift'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
