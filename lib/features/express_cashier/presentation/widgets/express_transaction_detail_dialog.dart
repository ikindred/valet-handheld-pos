import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/connectivity/internet_reachability.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../state/express_cashier_state.dart';

/// Detail + void dialog for an express cashier transaction row.
Future<void> showExpressTransactionDetailDialog({
  required BuildContext context,
  required ExpressCashierTransaction transaction,
  required String Function(String) formatPlateDisplay,
  required String Function(double) formatAmount,
  required Future<void> Function(String? reason) onVoid,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ExpressTransactionDetailDialog(
      transaction: transaction,
      formatPlateDisplay: formatPlateDisplay,
      formatAmount: formatAmount,
      onVoid: onVoid,
    ),
  );
}

class _ExpressTransactionDetailDialog extends StatefulWidget {
  const _ExpressTransactionDetailDialog({
    required this.transaction,
    required this.formatPlateDisplay,
    required this.formatAmount,
    required this.onVoid,
  });

  final ExpressCashierTransaction transaction;
  final String Function(String) formatPlateDisplay;
  final String Function(double) formatAmount;
  final Future<void> Function(String? reason) onVoid;

  @override
  State<_ExpressTransactionDetailDialog> createState() =>
      _ExpressTransactionDetailDialogState();
}

class _ExpressTransactionDetailDialogState
    extends State<_ExpressTransactionDetailDialog> {
  bool _voidLoading = false;
  bool? _isOnline;

  static final _dateFmt = DateFormat('MMM dd, yyyy · hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    final online = await InternetReachability.hasInternet();
    if (mounted) setState(() => _isOnline = online);
  }

  String _formatCheckInAt(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _dateFmt.format(parsed.toLocal());
  }

  bool get _canVoid {
    final tx = widget.transaction;
    return tx.canVoid;
  }

  String get _voidActionLabel {
    final tx = widget.transaction;
    if (!tx.hasServerId) return 'Void transaction';
    if (_isOnline == false) return 'Void transaction (offline)';
    return 'Void transaction';
  }

  Future<void> _confirmVoid() async {
    if (_voidLoading || !_canVoid) return;

    final tx = widget.transaction;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ExpressVoidConfirmDialog(
        isDeferredServerLookup: !tx.hasServerId,
        isOfflineQueued: tx.hasServerId && _isOnline == false,
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _voidLoading = true);
    try {
      await widget.onVoid(reason.isEmpty ? null : reason);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _voidLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final tc = AppThemeColors.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaction details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tc.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, size: 20, color: tc.textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DetailRow(label: 'Ticket', value: tx.ticketId),
              _DetailRow(
                label: 'Plate',
                value: widget.formatPlateDisplay(tx.plateNumber),
              ),
              _DetailRow(
                label: 'VR No.',
                value: tx.vrNo?.trim().isNotEmpty == true ? tx.vrNo!.trim() : '—',
              ),
              _DetailRow(
                label: 'Amount',
                value: widget.formatAmount(tx.amount),
                valueStyle: const TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DashboardStyles.orange,
                ),
              ),
              _DetailRow(
                label: 'Check-in',
                value: _formatCheckInAt(tx.checkInAt),
              ),
              if (tx.driverIn?.trim().isNotEmpty == true)
                _DetailRow(label: 'Driver in', value: tx.driverIn!.trim()),
              if (tx.driverOut?.trim().isNotEmpty == true)
                _DetailRow(label: 'Driver out', value: tx.driverOut!.trim()),
              _DetailRow(
                label: 'Status',
                value: tx.isVoided ? 'Voided' : 'Active',
                valueStyle: tx.isVoided
                    ? GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      )
                    : null,
              ),
              if (tx.isVoided && tx.voidReason?.trim().isNotEmpty == true)
                _DetailRow(label: 'Void reason', value: tx.voidReason!.trim()),
              _DetailRow(
                label: 'Sync',
                value: tx.isVoided
                    ? 'Voided'
                    : (tx.isSynced ? 'Synced' : 'Pending upload'),
              ),
              if (tx.hasServerId && _isOnline == false) ...[
                const SizedBox(height: 12),
                Text(
                  'Offline void applies on this device now and syncs to the server when you reconnect.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: tc.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (tx.canVoid) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _canVoid && !_voidLoading ? _confirmVoid : null,
                  icon: _voidLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          LucideIcons.ban,
                          size: 18,
                        ),
                  label: Text(
                    _voidLoading ? 'Processing…' : _voidActionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8831A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tc.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tc.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressVoidConfirmDialog extends StatefulWidget {
  const _ExpressVoidConfirmDialog({
    this.isDeferredServerLookup = false,
    this.isOfflineQueued = false,
  });

  final bool isDeferredServerLookup;
  final bool isOfflineQueued;

  @override
  State<_ExpressVoidConfirmDialog> createState() =>
      _ExpressVoidConfirmDialogState();
}

class _ExpressVoidConfirmDialogState extends State<_ExpressVoidConfirmDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.isDeferredServerLookup
        ? 'This voids the transaction on this device and syncs to the server when a matching record is found (including check-ins that saved while offline).'
        : widget.isOfflineQueued
            ? 'This voids the transaction on this device and queues it to sync when you are back online.'
            : 'This voids the transaction on the server and removes it from your shift total.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Void transaction?',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  hintText: 'Reason (optional)',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_reasonCtrl.text.trim()),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8831A),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Void'),
                    ),
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
