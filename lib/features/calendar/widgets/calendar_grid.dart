import 'package:flutter/material.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/features/calendar/models/daily_record.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;
  /// Matches [AppColorPalette.allDone] for the active accent preset.
  final Color allDoneColor;
  final ValueChanged<DateTime> onDateSelected;
  final DailyRecord? Function(DateTime date) recordForDate;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.allDoneColor,
    required this.onDateSelected,
    required this.recordForDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday;

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ..._buildWeeks(
          firstDay: firstDay,
          daysInMonth: daysInMonth,
          startWeekday: startWeekday,
          theme: theme,
          colorScheme: colorScheme,
          allDoneColor: allDoneColor,
        ),
      ],
    );
  }

  List<Widget> _buildWeeks({
    required DateTime firstDay,
    required int daysInMonth,
    required int startWeekday,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color allDoneColor,
  }) {
    final weeks = <Widget>[];
    final totalSlots = startWeekday - 1 + daysInMonth;
    final weekCount = (totalSlots / 7).ceil();

    for (var w = 0; w < weekCount; w++) {
      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final slotIndex = w * 7 + d;
        final dayNum = slotIndex - (startWeekday - 1) + 1;

        if (dayNum < 1 || dayNum > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
          continue;
        }

        final date = DateTime(month.year, month.month, dayNum);
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected =
            date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final isFuture = date.isAfter(today);

        final record = recordForDate(date);

        cells.add(
          Expanded(
            child: GestureDetector(
              onTap: isFuture ? null : () => onDateSelected(date),
              child: _DateCell(
                day: dayNum,
                isToday: isToday,
                isSelected: isSelected,
                isFuture: isFuture,
                record: record,
                theme: theme,
                colorScheme: colorScheme,
                allDoneColor: allDoneColor,
              ),
            ),
          ),
        );
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: cells),
        ),
      );
    }
    return weeks;
  }
}

class _DateCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final DailyRecord? record;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Color allDoneColor;

  const _DateCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.record,
    required this.theme,
    required this.colorScheme,
    required this.allDoneColor,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = colorScheme.onSurface;

    if (isSelected) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isToday) {
      bgColor = colorScheme.primary.withValues(alpha: 0.12);
    }

    if (isFuture) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.3);
    }

    Color? dotColor;
    if (!isFuture && record != null && record!.totalTasks > 0) {
      if (record!.allComplete) {
        dotColor = allDoneColor;
      } else if (record!.hasPartial) {
        dotColor = AppColors.partial;
      } else {
        dotColor = AppColors.noneDone;
      }
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight:
                  (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (dotColor != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onPrimary.withValues(alpha: 0.8)
                    : dotColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
