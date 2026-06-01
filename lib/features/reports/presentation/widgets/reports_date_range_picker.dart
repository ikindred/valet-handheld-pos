import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import 'reports_widgets.dart';

/// Outcome of [showReportsDateRangePicker]. `null` means dismissed (keep current filter).
sealed class ReportsDateRangePickerResult {
  const ReportsDateRangePickerResult();
}

/// User closed without applying — do not change the active filter.
final class ReportsDateRangePickerCancelled extends ReportsDateRangePickerResult {
  const ReportsDateRangePickerCancelled();
}

/// User cleared the filter (footer Clear or equivalent).
final class ReportsDateRangePickerCleared extends ReportsDateRangePickerResult {
  const ReportsDateRangePickerCleared();
}

/// User applied an inclusive calendar range (start/end are date-only).
final class ReportsDateRangePickerApplied extends ReportsDateRangePickerResult {
  const ReportsDateRangePickerApplied(this.range);

  final DateTimeRange range;
}

/// Branded date-range picker for Reports filters (readable contrast, presets, Apply).
Future<ReportsDateRangePickerResult?> showReportsDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = firstDate ?? today.subtract(const Duration(days: 365));
  final last = lastDate ?? today;

  DateTimeRange? initial;
  if (initialRange != null) {
    final endInclusive = initialRange.end.subtract(const Duration(days: 1));
    initial = DateTimeRange(
      start: DateTime(
        initialRange.start.year,
        initialRange.start.month,
        initialRange.start.day,
      ),
      end: DateTime(endInclusive.year, endInclusive.month, endInclusive.day),
    );
  }

  return showDialog<ReportsDateRangePickerResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ReportsDateRangeDialog(
      firstDate: first,
      lastDate: last,
      initialRange: initial,
    ),
  );
}

class _ReportsDateRangeDialog extends StatefulWidget {
  const _ReportsDateRangeDialog({
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;

  @override
  State<_ReportsDateRangeDialog> createState() => _ReportsDateRangeDialogState();
}

class _ReportsDateRangeDialogState extends State<_ReportsDateRangeDialog> {
  static final _monthFmt = DateFormat('MMMM yyyy');

  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRange;
    _start = initial != null ? _dateOnly(initial.start) : null;
    _end = initial != null ? _dateOnly(initial.end) : null;
    final anchor = _end ?? _start ?? widget.lastDate;
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelectable(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(_dateOnly(widget.firstDate)) &&
        !d.isAfter(_dateOnly(widget.lastDate));
  }

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    final d = _dateOnly(day);
    final a = _start!;
    final b = _end!;
    return !d.isBefore(a) && !d.isAfter(b);
  }

  bool _isRangeStart(DateTime day) => _start != null && _sameDay(day, _start!);

  bool _isRangeEnd(DateTime day) => _end != null && _sameDay(day, _end!);

  void _onDayTap(DateTime day) {
    if (!_isSelectable(day)) return;
    final d = _dateOnly(day);
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = d;
        _end = null;
        return;
      }
      if (d.isBefore(_start!)) {
        _end = _start;
        _start = d;
      } else {
        _end = d;
      }
    });
  }

  void _applyPreset(_DatePreset preset) {
    final last = _dateOnly(widget.lastDate);
    setState(() {
      switch (preset) {
        case _DatePreset.today:
          _start = last;
          _end = last;
        case _DatePreset.last7Days:
          _start = last.subtract(const Duration(days: 6));
          _end = last;
        case _DatePreset.thisMonth:
          _start = DateTime(last.year, last.month);
          _end = last;
        case _DatePreset.clear:
          _start = null;
          _end = null;
      }
      _visibleMonth = DateTime((_end ?? _start ?? last).year, (_end ?? _start ?? last).month);
    });
  }

  void _shiftMonth(int delta) {
    if (!_canShiftMonth(delta)) return;
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool _canShiftMonth(int delta) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !target.isBefore(firstMonth) && !target.isAfter(lastMonth);
  }

  void _applyAndClose() {
    if (_start == null) return;
    final end = _end ?? _start!;
    Navigator.of(context).pop(
      ReportsDateRangePickerApplied(DateTimeRange(start: _start!, end: end)),
    );
  }

  void _clearAndClose() {
    Navigator.of(context).pop(const ReportsDateRangePickerCleared());
  }

  void _cancel() {
    Navigator.of(context).pop(const ReportsDateRangePickerCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _start != null;
    final hint = _start != null && _end == null
        ? 'Tap the end date'
        : 'Tap a start date, then an end date';

    final media = MediaQuery.of(context);
    final maxDialogHeight = media.size.height -
        media.padding.vertical -
        media.viewInsets.bottom -
        48;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: maxDialogHeight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  start: _start,
                  end: _end,
                  onClose: _cancel,
                ),
                const Divider(height: 1, color: ReportsStyles.rowDivider),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (constraints.maxHeight - 168).clamp(160, 480),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(hint, style: _hintStyle()),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: _PresetChips(onPreset: _applyPreset),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: _MonthNavigator(
                            label: _monthFmt.format(_visibleMonth),
                            canGoPrev: _canShiftMonth(-1),
                            canGoNext: _canShiftMonth(1),
                            onPrev: () => _shiftMonth(-1),
                            onNext: () => _shiftMonth(1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: _CalendarGrid(
                            visibleMonth: _visibleMonth,
                            lastDate: widget.lastDate,
                            isSelectable: _isSelectable,
                            inRange: _inRange,
                            isRangeStart: _isRangeStart,
                            isRangeEnd: _isRangeEnd,
                            onDayTap: _onDayTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: ReportsStyles.rowDivider),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _clearAndClose,
                        child: Text('Clear', style: _actionText(AppColors.textSecondary)),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text('Cancel', style: _actionText(AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: canApply ? _applyAndClose : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: DashboardStyles.orange,
                          disabledBackgroundColor: const Color(0xFFE8EAED),
                          disabledForegroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Apply', style: _actionText(Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static TextStyle _hintStyle() => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle _actionText(Color color) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

enum _DatePreset { today, last7Days, thisMonth, clear }

class _Header extends StatelessWidget {
  const _Header({
    required this.start,
    required this.end,
    required this.onClose,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    String rangeLabel;
    if (start == null) {
      rangeLabel = 'Start date – End date';
    } else if (end == null) {
      rangeLabel = '${fmt.format(start!)} – …';
    } else if (start!.year == end!.year &&
        start!.month == end!.month &&
        start!.day == end!.day) {
      rangeLabel = fmt.format(start!);
    } else {
      rangeLabel = '${fmt.format(start!)} – ${fmt.format(end!)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT DATE RANGE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rangeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({required this.onPreset});

  final void Function(_DatePreset preset) onPreset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(label: 'Today', onTap: () => onPreset(_DatePreset.today)),
        _Chip(label: 'Last 7 days', onTap: () => onPreset(_DatePreset.last7Days)),
        _Chip(label: 'This month', onTap: () => onPreset(_DatePreset.thisMonth)),
        _Chip(label: 'Clear', onTap: () => onPreset(_DatePreset.clear), outlined: true),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.white : DashboardStyles.railAccentBg,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: outlined
                  ? Colors.black.withValues(alpha: 0.15)
                  : DashboardStyles.orange.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: outlined ? AppColors.textSecondary : DashboardStyles.orange,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final disabled = AppColors.textSecondary.withValues(alpha: 0.35);
    return Row(
      children: [
        IconButton(
          onPressed: canGoPrev ? onPrev : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            color: canGoPrev ? AppColors.textPrimary : disabled,
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: canGoNext ? AppColors.textPrimary : disabled,
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.lastDate,
    required this.isSelectable,
    required this.inRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final DateTime lastDate;
  final bool Function(DateTime day) isSelectable;
  final bool Function(DateTime day) inRange;
  final bool Function(DateTime day) isRangeStart;
  final bool Function(DateTime day) isRangeEnd;
  final void Function(DateTime day) onDayTap;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final days = _monthGridDays(visibleMonth);
    final today = DateTime.now();
    final month = visibleMonth.month;

    return Column(
      children: [
        Row(
          children: _weekdays
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.15,
          ),
          itemCount: days.length,
          itemBuilder: (context, i) {
            final day = days[i];
            final inMonth = day.month == month;
            final selectable = isSelectable(day);
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            return _DayCell(
              day: day.day,
              inMonth: inMonth,
              selectable: selectable,
              inRange: inRange(day),
              isStart: isRangeStart(day),
              isEnd: isRangeEnd(day),
              isToday: isToday,
              onTap: selectable ? () => onDayTap(day) : null,
            );
          },
        ),
      ],
    );
  }

  static List<DateTime> _monthGridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.selectable,
    required this.inRange,
    required this.isStart,
    required this.isEnd,
    required this.isToday,
    this.onTap,
  });

  final int day;
  final bool inMonth;
  final bool selectable;
  final bool inRange;
  final bool isStart;
  final bool isEnd;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final endpoint = isStart || isEnd;
    Color bg = Colors.transparent;
    Color fg = AppColors.textPrimary;

    if (!inMonth || !selectable) {
      fg = AppColors.textSecondary.withValues(alpha: 0.35);
    } else if (endpoint) {
      bg = DashboardStyles.orange;
      fg = Colors.white;
    } else if (inRange) {
      bg = DashboardStyles.orange.withValues(alpha: 0.18);
      fg = AppColors.textPrimary;
    }

    Widget child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(endpoint ? 20 : 4),
        border: isToday && !endpoint
            ? Border.all(color: DashboardStyles.orange, width: 1.5)
            : null,
      ),
      child: Text(
        '$day',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: endpoint ? FontWeight.w600 : FontWeight.w500,
          color: fg,
        ),
      ),
    );

    if (onTap != null) {
      child = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: child,
        ),
      );
    }

    return child;
  }
}
