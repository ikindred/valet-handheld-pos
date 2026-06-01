import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../domain/reports_format.dart';
import '../../domain/reports_models.dart';

/// Reports typography and colors — Figma Transactions (node 76-2680).
abstract final class ReportsStyles {
  /// Shared height for search, dropdowns, and date field (Figma filter row).
  static const double filterControlHeight = 40;

  static const Color infoBlue = Color(0xFF2980B9);
  static const Color longStayOrange = Color(0xFFF59E0B);
  static const Color rowDivider = Color(0x1F000000);

  static TextStyle tabActive() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: DashboardStyles.orange,
        height: 1.2,
      );

  static TextStyle cardSectionTitle() => DashboardStyles.sectionTitle();

  static TextStyle filterHint() => DashboardStyles.statHint();

  static TextStyle filterValue() => DashboardStyles.transactionLine();

  static TextStyle ticketId() => DashboardStyles.transactionLinePrimary().copyWith(
        color: DashboardStyles.orange,
        fontSize: 11,
      );

  static TextStyle tableHeader() => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        color: AppColors.textSecondary,
        height: 1.2,
      );

  static TextStyle tableCell() => DashboardStyles.transactionLine();

  static TextStyle durationNormal() =>
      DashboardStyles.transactionLine().copyWith(color: DashboardStyles.green);

  static TextStyle durationWarning() =>
      DashboardStyles.transactionLine().copyWith(color: longStayOrange);

  static BoxDecoration filterBoxDecoration({Color? fill}) {
    return BoxDecoration(
      color: fill ?? Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black.withValues(alpha: 0.13)),
    );
  }

  static const _noBorder = InputBorder.none;
}

/// Fixed 40px shell — border on the container, not [InputDecorator] (avoids uneven heights).
class _FilterControlShell extends StatelessWidget {
  const _FilterControlShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = ReportsStyles.filterControlHeight;
    return SizedBox(
      height: h,
      child: DecoratedBox(
        decoration: ReportsStyles.filterBoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Active “TRANSACTIONS” tab strip (Figma sub-nav; single tab after Today/Cash removed).
class ReportsTransactionsTabStrip extends StatelessWidget {
  const ReportsTransactionsTabStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.13)),
        ),
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text('TRANSACTIONS', style: ReportsStyles.tabActive()),
            ),
            Container(height: 3, color: DashboardStyles.orange),
          ],
        ),
      ),
    );
  }
}

/// Search, status, date range — sits above the table card (Figma 76-2680).
class ReportsTransactionsFilterBar extends StatelessWidget {
  const ReportsTransactionsFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    this.dateRangeLabel,
    this.onStatusFilterChanged,
    this.onDateRangeTap,
    this.onDateRangeClear,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final String? dateRangeLabel;
  final ValueChanged<String>? onStatusFilterChanged;
  final VoidCallback? onDateRangeTap;
  final VoidCallback? onDateRangeClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 640;
        final search = _FilterControlShell(
          child: TextField(
            controller: searchController,
            style: ReportsStyles.filterValue(),
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: ReportsStyles.filterHint(),
              isDense: true,
              isCollapsed: true,
              border: ReportsStyles._noBorder,
              enabledBorder: ReportsStyles._noBorder,
              focusedBorder: ReportsStyles._noBorder,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 8),
              _FilterDropdown(
                value: statusFilter,
                items: const ['All Status', 'Parked', 'Long Stay', 'Checked Out'],
                onChanged: onStatusFilterChanged,
              ),
              const SizedBox(height: 8),
              _DateRangeField(
                label: dateRangeLabel,
                onTap: onDateRangeTap,
                onClear: onDateRangeClear,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _FilterDropdown(
                value: statusFilter,
                items: const ['All Status', 'Parked', 'Long Stay', 'Checked Out'],
                onChanged: onStatusFilterChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _DateRangeField(
                label: dateRangeLabel,
                onTap: onDateRangeTap,
                onClear: onDateRangeClear,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ReportsTransactionsTableCard extends StatelessWidget {
  const ReportsTransactionsTableCard({
    super.key,
    required this.rowCount,
    required this.rows,
    this.onRowTap,
  });

  final int rowCount;
  final List<ReportsTicketRow> rows;
  final void Function(ReportsTicketRow row)? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: DashboardStyles.cardDecorationOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'TRANSACTIONS ($rowCount)'.toUpperCase(),
              style: ReportsStyles.cardSectionTitle(),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Text(
                'No tickets to show.',
                textAlign: TextAlign.center,
                style: ReportsStyles.filterHint(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, thickness: 1, color: ReportsStyles.rowDivider),
            ),
          if (rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _ReportsTransactionsTable(rows: rows, onRowTap: onRowTap),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterControlShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: ReportsStyles.filterValue(),
          icon: Icon(Icons.expand_more, color: DashboardStyles.grey500, size: 20),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? value),
        ),
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({this.label, this.onTap, this.onClear});

  final String? label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.trim().isNotEmpty;
    return _FilterControlShell(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  hasLabel ? label!.trim() : 'mm/dd/yyyy - mm/dd/yyyy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasLabel
                      ? ReportsStyles.filterValue().copyWith(fontSize: 11)
                      : ReportsStyles.filterHint().copyWith(fontSize: 11),
                ),
              ),
            ),
          ),
          if (hasLabel && onClear != null)
            Tooltip(
              message: 'Clear dates',
              child: InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: DashboardStyles.grey500,
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: DashboardStyles.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsTransactionsTable extends StatelessWidget {
  const _ReportsTransactionsTable({
    required this.rows,
    this.onRowTap,
  });

  final List<ReportsTicketRow> rows;
  final void Function(ReportsTicketRow row)? onRowTap;

  static const _headers = [
    'Ticket',
    'Plate',
    'Vehicle',
    'Time In',
    'Duration',
    'Slot',
    'Status',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: _FixedTable(rows: rows, onRowTap: onRowTap),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(),
            ...List.generate(rows.length, (i) {
              return Column(
                children: [
                  _DataRow(row: rows[i], onTap: onRowTap),
                  if (i < rows.length - 1)
                    const Divider(height: 1, thickness: 1, color: ReportsStyles.rowDivider),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < _ReportsTransactionsTable._headers.length; i++)
            Expanded(
              flex: _flexForColumn(i),
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
                child: Text(
                  _ReportsTransactionsTable._headers[i],
                  style: ReportsStyles.tableHeader(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.row, this.onTap});

  final ReportsTicketRow row;
  final void Function(ReportsTicketRow row)? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _flexForColumn(0),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                row.ticketId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ReportsStyles.ticketId(),
              ),
            ),
          ),
          Expanded(
            flex: _flexForColumn(1),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PlateBadge(plate: row.plate),
              ),
            ),
          ),
          Expanded(
            flex: _flexForColumn(2),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                row.vehicle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReportsStyles.tableCell(),
              ),
            ),
          ),
          Expanded(
            flex: _flexForColumn(3),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                row.timeInLabel,
                style: ReportsStyles.tableCell(),
              ),
            ),
          ),
          Expanded(
            flex: _flexForColumn(4),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _DurationCell(row: row),
            ),
          ),
          Expanded(
            flex: _flexForColumn(5),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(row.slot, style: ReportsStyles.tableCell()),
            ),
          ),
          Expanded(
            flex: _flexForColumn(6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPaymentCell(row: row),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap!(row),
        borderRadius: BorderRadius.circular(6),
        child: content,
      ),
    );
  }
}

int _flexForColumn(int index) => switch (index) {
      0 => 14,
      1 => 11,
      2 => 16,
      3 => 9,
      4 => 9,
      5 => 8,
      _ => 11,
    };

class _FixedTable extends StatelessWidget {
  const _FixedTable({required this.rows, this.onRowTap});

  final List<ReportsTicketRow> rows;
  final void Function(ReportsTicketRow row)? onRowTap;

  @override
  Widget build(BuildContext context) {
    const colW = <double>[100, 96, 128, 72, 72, 56, 100];
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        for (var i = 0; i < colW.length; i++) i: FixedColumnWidth(colW[i]),
      },
      children: [
        TableRow(
          children: _ReportsTransactionsTable._headers
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: Text(h, style: ReportsStyles.tableHeader()),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (r) => TableRow(
            children: [
              _cell(
                _maybeTap(
                  r,
                  Text(r.ticketId, style: ReportsStyles.ticketId(), maxLines: 1),
                ),
              ),
              _cell(_maybeTap(r, _PlateBadge(plate: r.plate))),
              _cell(
                _maybeTap(
                  r,
                  Text(r.vehicle, style: ReportsStyles.tableCell(), maxLines: 2),
                ),
              ),
              _cell(
                _maybeTap(
                  r,
                  Text(r.timeInLabel, style: ReportsStyles.tableCell()),
                ),
              ),
              _cell(_maybeTap(r, _DurationCell(row: r))),
              _cell(_maybeTap(r, Text(r.slot, style: ReportsStyles.tableCell()))),
              _cell(_maybeTap(r, _StatusPaymentCell(row: r))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: child,
    );
  }

  Widget _maybeTap(ReportsTicketRow r, Widget child) {
    if (onRowTap == null) return child;
    return InkWell(
      onTap: () => onRowTap!(r),
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardStyles.plateBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardStyles.plateBlue),
      ),
      child: Text(
        plate,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DashboardStyles.plateBadge().copyWith(fontSize: 11),
      ),
    );
  }
}

class _DurationCell extends StatelessWidget {
  const _DurationCell({required this.row});

  final ReportsTicketRow row;

  @override
  Widget build(BuildContext context) {
    final label = row.durationLabel;
    final warn = row.isLongStay;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (warn)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: ReportsStyles.longStayOrange,
            ),
          ),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: warn ? ReportsStyles.durationWarning() : ReportsStyles.durationNormal(),
          ),
        ),
      ],
    );
  }
}

class _StatusPaymentCell extends StatelessWidget {
  const _StatusPaymentCell({required this.row});

  final ReportsTicketRow row;

  @override
  Widget build(BuildContext context) => _StatusBadge(status: row.status);
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportsTicketRowStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReportsTicketRowStatus.parked => ReportsStyles.infoBlue,
      ReportsTicketRowStatus.longStay => ReportsStyles.longStayOrange,
      ReportsTicketRowStatus.checkedOut => const Color(0xFF6E7584),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
