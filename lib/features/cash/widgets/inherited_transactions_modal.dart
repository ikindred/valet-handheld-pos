import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/open_transaction.dart';

/// Shown after opening a shift when unpaid tickets from a prior shift need adopting.
class InheritedTransactionsModal extends StatelessWidget {
  const InheritedTransactionsModal({
    super.key,
    required this.inheritedTransactions,
    required this.onAcknowledge,
  });

  final List<OpenTransaction> inheritedTransactions;
  final VoidCallback onAcknowledge;

  static Future<void> show(
    BuildContext context, {
    required List<OpenTransaction> inheritedTransactions,
    required VoidCallback onAcknowledge,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InheritedTransactionsModal(
        inheritedTransactions: inheritedTransactions,
        onAcknowledge: onAcknowledge,
      ),
    );
  }

  static const _darkGrey = Color(0xFF3C3434);
  static const _orange = Color(0xFFE8831A);

  @override
  Widget build(BuildContext context) {
    final n = inheritedTransactions.length;
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
                  const Icon(LucideIcons.clipboardList, color: _darkGrey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions From Previous Shift',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are $n vehicle(s) still checked in from the previous cashier\'s shift. '
                          'These will be assigned to your shift. You will be responsible for their checkout.',
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
                      DataColumn(label: Text('Waiting')),
                    ],
                    rows: [
                      for (var i = 0; i < inheritedTransactions.length; i++)
                        DataRow(
                          color: WidgetStateProperty.all(
                            i.isEven
                                ? const Color(0xFFF9F9F9)
                                : Colors.white,
                          ),
                          cells: [
                            DataCell(Text(inheritedTransactions[i].ticketNumber)),
                            DataCell(Text(inheritedTransactions[i].plateNumber)),
                            DataCell(Text(inheritedTransactions[i].vehicleLabel)),
                            DataCell(Text(
                              '${dateFmt.format(inheritedTransactions[i].timeIn.toLocal())} '
                              '${timeFmt.format(inheritedTransactions[i].timeIn.toLocal())}',
                            )),
                            DataCell(Text(
                              OpenTransaction.formatDurationSince(
                                inheritedTransactions[i].timeIn.toLocal(),
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
                'Once you confirm, these transactions will appear in your active ticket list.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onAcknowledge,
                  child: const Text('Acknowledge & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
