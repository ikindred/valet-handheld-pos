import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../sync/domain/pending_sync_item.dart';
import '../../../sync/state/sync_cubit.dart';

Future<void> showPendingSyncSheet(
  BuildContext context, {
  required bool isExpressCashier,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => PendingSyncSheet(isExpressCashier: isExpressCashier),
  );
}

class PendingSyncSheet extends StatefulWidget {
  const PendingSyncSheet({super.key, required this.isExpressCashier});

  final bool isExpressCashier;

  @override
  State<PendingSyncSheet> createState() => _PendingSyncSheetState();
}

class _PendingSyncSheetState extends State<PendingSyncSheet> {
  List<PendingSyncItem>? _items;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final items = await context.read<SyncCubit>().listUnsyncedItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final items = _items;
    final failed = items?.where((i) => i.status == PendingSyncItemStatus.failed);
    final pending = items?.where((i) => i.status == PendingSyncItemStatus.pending);
    final failedCount = failed?.length ?? 0;
    final pendingCount = pending?.length ?? 0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: tc.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tc.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unsynced Data',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: tc.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _loading
                                ? 'Loading…'
                                : _summaryLine(pendingCount, failedCount),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: tc.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(LucideIcons.x, size: 20, color: tc.textSecondary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tc.divider),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : items == null || items.isEmpty
                        ? _EmptyState(onRefresh: _load)
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _PendingSyncTile(
                                item: items[index],
                                isExpressCashier: widget.isExpressCashier,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _summaryLine(int pending, int failed) {
    if (pending == 0 && failed == 0) return 'Everything is synced';
    final parts = <String>[];
    if (pending > 0) {
      parts.add('$pending pending');
    }
    if (failed > 0) {
      parts.add('$failed failed');
    }
    return parts.join(' · ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.checkCircle2,
              size: 40,
              color: DashboardStyles.green,
            ),
            const SizedBox(height: 12),
            Text(
              'All clear',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tc.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No transactions are waiting to sync.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: tc.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRefresh,
              icon: Icon(LucideIcons.refreshCw, size: 16, color: tc.textPrimary),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: tc.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSyncTile extends StatelessWidget {
  const _PendingSyncTile({
    required this.item,
    required this.isExpressCashier,
  });

  final PendingSyncItem item;
  final bool isExpressCashier;

  static const _pesoGlyphFallback = ['Noto Sans', 'Roboto'];

  static TextStyle _withPesoFallback(TextStyle base) =>
      base.copyWith(fontFamilyFallback: _pesoGlyphFallback);

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final failed = item.status == PendingSyncItemStatus.failed;
    final tone = failed
        ? (const Color(0xFFFEF2F2), const Color(0xFFDC2626))
        : (const Color(0xFFFFFBEB), const Color(0xFFD97706));
    final icon = _iconFor(item);
    final title = item.displayTitle(isExpressCashier: isExpressCashier);
    final primaryLine = title ?? item.subtitle;
    final showSubtitle = title != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.$1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: tone.$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        primaryLine,
                        style: _withPesoFallback(
                          GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tc.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    _StatusChip(
                      label: item.statusLabel,
                      failed: failed,
                    ),
                  ],
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: _withPesoFallback(
                      GoogleFonts.poppins(
                        fontSize: 12,
                        color: tc.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (item.createdLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.createdLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: tc.textSubtitleMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(PendingSyncItem item) {
    final op = item.operation?.toLowerCase() ?? '';
    if (op == 'checkin') return LucideIcons.car;
    if (op == 'checkout/finalize') return LucideIcons.logOut;

    final t = item.title.toLowerCase();
    if (t.contains('check-in') || t.contains('ticket')) {
      return LucideIcons.car;
    }
    if (t.contains('check-out')) return LucideIcons.logOut;
    if (t.contains('open cash')) return LucideIcons.wallet;
    if (t.contains('close cash')) return LucideIcons.banknote;
    return LucideIcons.cloudOff;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.failed});

  final String label;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final fg = failed ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final bg = failed ? const Color(0xFFFFF5F5) : const Color(0xFFFFFBEB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
