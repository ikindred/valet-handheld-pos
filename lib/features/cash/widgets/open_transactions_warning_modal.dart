import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/open_transaction.dart';
import 'open_transactions_data_table.dart';

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
    final maxDialogH = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: maxDialogH),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
              Expanded(
                child: OpenTransactionsDataTable(
                  transactions: openTransactions,
                  durationColumnLabel: 'Duration',
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
