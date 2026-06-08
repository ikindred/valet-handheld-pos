import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/open_transaction.dart';
import 'open_transactions_data_table.dart';

/// Shown after opening a shift when unpaid tickets from a prior shift need adopting.
class InheritedTransactionsModal extends StatelessWidget {
  const InheritedTransactionsModal({
    super.key,
    required this.inheritedTransactions,
    required this.onAcknowledge,
    this.onCancel,
  });

  final List<OpenTransaction> inheritedTransactions;
  final VoidCallback onAcknowledge;

  /// When provided, a "Cancel" button is shown. The callback is responsible for
  /// voiding the shift and resetting state; the dialog is closed automatically.
  final VoidCallback? onCancel;

  static Future<void> show(
    BuildContext context, {
    required List<OpenTransaction> inheritedTransactions,
    required VoidCallback onAcknowledge,
    VoidCallback? onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InheritedTransactionsModal(
        inheritedTransactions: inheritedTransactions,
        onAcknowledge: onAcknowledge,
        onCancel: onCancel,
      ),
    );
  }

  static const _darkGrey = Color(0xFF3C3434);
  static const _orange = Color(0xFFE8831A);

  @override
  Widget build(BuildContext context) {
    final n = inheritedTransactions.length;
    final maxDialogH = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.92,
          minWidth: 520,
          maxHeight: maxDialogH,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
              Expanded(
                child: OpenTransactionsDataTable(
                  transactions: inheritedTransactions,
                  durationColumnLabel: 'Parked For',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel!();
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAcknowledge();
                    },
                    child: const Text('Acknowledge & Continue'),
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
