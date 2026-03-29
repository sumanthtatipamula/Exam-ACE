import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/core/theme/color_preset_provider.dart';
import 'package:exam_ace/features/calendar/models/daily_record.dart';
import 'package:exam_ace/features/calendar/widgets/calendar_grid.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, HomeTaskSource, homeTaskEntityKey;
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/widgets/carried_spill_badge.dart';
import 'package:exam_ace/features/home/widgets/home_task_progress_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _today;
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = _today;
  }

  DateTime _earliestMonth(Map<String, List<HomeTask>> allTasks) {
    DateTime? earliest;
    for (final key in allTasks.keys) {
      final parts = key.split('-');
      if (parts.length == 3) {
        final m = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        if (earliest == null || m.isBefore(earliest)) earliest = m;
      }
    }
    return earliest ?? _currentMonth;
  }

  bool _canGoBack(DateTime earliest) => _currentMonth.isAfter(earliest);

  bool get _canGoForward {
    final limit = DateTime(_today.year, _today.month);
    return _currentMonth.isBefore(limit);
  }

  void _goBack() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _goForward() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasks = ref.watch(allTaskDateKeysProvider);
    final earliest = _earliestMonth(allTasks);
    final canGoBack = _canGoBack(earliest);

    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final monthRecords = <String, DailyRecord?>{};
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = dateKey(date);
      final tasks = ref.watch(calendarDayTasksProvider(key));
      monthRecords[key] =
          tasks.isEmpty ? null : DailyRecord.fromHomeTasks(date, tasks);
    }

    final selectedKey = dateKey(_selectedDate);
    final selectedTasks = ref.watch(calendarDayTasksProvider(selectedKey));
    final selectedRecord = selectedTasks.isEmpty
        ? null
        : DailyRecord.fromHomeTasks(_selectedDate, selectedTasks);

    final selDateOnly =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final todayOnly = DateTime(_today.year, _today.month, _today.day);
    final calendarPastReadOnly = selDateOnly.isBefore(todayOnly);

    final monthName = _monthYear(_currentMonth);
    final allDoneColor = ref.watch(appColorPresetProvider).palette.allDone;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: canGoBack ? _goBack : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  monthName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _canGoForward ? _goForward : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarGrid(
              month: _currentMonth,
              selectedDate: _selectedDate,
              today: _today,
              allDoneColor: allDoneColor,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
              recordForDate: (date) => monthRecords[dateKey(date)],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _Legend(color: allDoneColor, label: 'All done'),
                const SizedBox(width: 16),
                _Legend(color: AppColors.partial, label: 'Partial'),
                const SizedBox(width: 16),
                _Legend(color: AppColors.noneDone, label: 'None'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: _TaskListForDate(
              record: selectedRecord,
              theme: theme,
              readOnly: calendarPastReadOnly,
              selectedIsToday: selDateOnly == todayOnly,
            ),
          ),
        ],
      ),
    );
  }

  static String _monthYear(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TaskListForDate extends ConsumerWidget {
  final DailyRecord? record;
  final ThemeData theme;
  final bool readOnly;
  final bool selectedIsToday;

  const _TaskListForDate({
    required this.record,
    required this.theme,
    this.readOnly = false,
    this.selectedIsToday = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = theme.colorScheme;
    final carryIds =
        ref.watch(carryIdsForTodayProvider).valueOrNull ?? const <String>[];
    final carrySpillCounts =
        ref.watch(carrySpillDayCountsProvider).valueOrNull ??
            const <String, int>{};

    if (record == null || record!.tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks for this day.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (readOnly) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: record!.tasks.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Snapshot for this day — progress is frozen; edits elsewhere won’t change it.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final task = record!.tasks[index - 1];
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: task.isComplete
                        ? Icon(Icons.check_circle_rounded,
                            color: colorScheme.tertiary, size: 26)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: task.progress / 100,
                                strokeWidth: 3,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                              ),
                              Center(
                                child: Text(
                                  '${task.progress}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: task.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isComplete
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.subtitle != null &&
                            task.subtitle!.isNotEmpty)
                          Text(
                            task.subtitle!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${task.progress}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: task.isComplete
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: record!.tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final task = record!.tasks[index];
        final entityKey = homeTaskEntityKey(task);
        final showCarriedBadge =
            selectedIsToday && carryIds.contains(entityKey);
        final carrySpillDays = carrySpillCounts[entityKey] ?? 1;
        final body = Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: task.isComplete
                      ? Icon(Icons.check_circle_rounded,
                          color: colorScheme.tertiary, size: 26)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: task.progress / 100,
                              strokeWidth: 3,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: colorScheme.primary,
                            ),
                            Center(
                              child: Text(
                                '${task.progress}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              task.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                decoration: task.isComplete
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isComplete
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.isLinked) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: task.source == HomeTaskSource.topic
                                    ? colorScheme.tertiaryContainer
                                    : colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.sourceLabel[0],
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: task.source == HomeTaskSource.topic
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                          if (showCarriedBadge) ...[
                            const SizedBox(width: 6),
                            CarriedSpillBadge(spillDays: carrySpillDays),
                          ],
                        ],
                      ),
                      if (task.subtitle != null &&
                          task.subtitle!.isNotEmpty)
                        Text(
                          task.subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${task.progress}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: task.isComplete
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: showCarriedBadge
              ? body
              : InkWell(
                  onTap: () =>
                      showHomeTaskProgressEditor(context, ref, task),
                  child: body,
                ),
        );
      },
    );
  }
}
