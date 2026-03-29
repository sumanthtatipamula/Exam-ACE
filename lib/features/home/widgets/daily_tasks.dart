import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/features/home/models/task.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, HomeTaskSource, homeTaskEntityKey;
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/widgets/carried_spill_badge.dart';
import 'package:exam_ace/features/home/widgets/home_task_progress_sheet.dart';

/// Matches [HomeScreen] / week tracker horizontal inset so Mon–Sun and task UI align.
const double _kHomeTaskHorizontalPadding = 20;

/// Opens the add-task sheet (used from Home FAB and elsewhere).
void showAddTaskSheet(
  BuildContext context,
  TasksRepository repo,
  DateTime initialDate,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _AddTaskSheet(
      initialDate: initialDate,
      onSave: (title, date) {
        repo.add(Task(id: '', title: title, date: date));
      },
    ),
  );
}

/// Sliver children for the home task list so the **page** scrolls (no nested list).
List<Widget> buildHomeDailyTaskSlivers({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime selectedDate,
  required DateTime today,
  required List<HomeTask> tasks,
  List<HomeTask> carriedTasks = const [],
  List<HomeTask> spilloverTasks = const [],
  Map<String, int> carrySpillDayCounts = const {},
  required int todaySegment,
  required ValueChanged<int> onTodaySegmentChanged,
  VoidCallback? onGoToToday,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final repo = ref.read(tasksRepositoryProvider);
  final day = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  final isToday = DateUtils.isSameDay(selectedDate, today);

  if (isToday) {
    final todayNativeEmpty =
        tasks.isEmpty && carriedTasks.isEmpty;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kHomeTaskHorizontalPadding),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('Today'),
                icon: Icon(Icons.wb_sunny_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Spill over'),
                icon: Icon(Icons.history_rounded, size: 18),
              ),
            ],
            selected: {todaySegment},
            onSelectionChanged: (Set<int> s) =>
                onTodaySegmentChanged(s.first),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      if (todaySegment == 0) ...[
        if (todayNativeEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kHomeTaskHorizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: Text(
                  'No tasks scheduled for today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: _kHomeTaskHorizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final total = tasks.length + carriedTasks.length;
                  final last = index == total - 1;
                  if (index < tasks.length) {
                    final task = tasks[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: last ? 0 : 4),
                      child: _TaskTile(
                        task: task,
                        onTap: () =>
                            showHomeTaskProgressEditor(context, ref, task),
                        onDelete: task.isStandalone
                            ? () => repo.delete(task.id)
                            : null,
                      ),
                    );
                  }
                  final task = carriedTasks[index - tasks.length];
                  final spillDays =
                      carrySpillDayCounts[homeTaskEntityKey(task)] ?? 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 4),
                    child: _TaskTile(
                      task: task,
                      readOnly: true,
                      showCarriedBadge: true,
                      carrySpillDays: spillDays,
                    ),
                  );
                },
                childCount: tasks.length + carriedTasks.length,
              ),
            ),
          ),
      ] else ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kHomeTaskHorizontalPadding),
            child: Text(
              'From earlier days. Not counted in week average, surf, streak, or ribbon totals.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (spilloverTasks.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kHomeTaskHorizontalPadding,
                vertical: 24,
              ),
              child: Center(
                child: Text(
                  'No spillover tasks.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: _kHomeTaskHorizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = spilloverTasks[index];
                  final last = index == spilloverTasks.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 4),
                    child: _SpilloverTile(
                      task: task,
                      onAddToToday: () =>
                          repo.addCarryToToday(homeTaskEntityKey(task)),
                    ),
                  );
                },
                childCount: spilloverTasks.length,
              ),
            ),
          ),
      ],
    ];
  }

  final readOnly = day.isBefore(
    DateTime(today.year, today.month, today.day),
  );

  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _kHomeTaskHorizontalPadding,
          0,
          _kHomeTaskHorizontalPadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    DateFormat.yMMMEd().format(selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onGoToToday != null)
                  TextButton.icon(
                    onPressed: onGoToToday,
                    icon: const Icon(Icons.today_rounded, size: 18),
                    label: const Text('Today'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            if (readOnly) ...[
              const SizedBox(height: 4),
              Text(
                'Snapshot for this day — progress is frozen.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 4)),
    if (tasks.isEmpty)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kHomeTaskHorizontalPadding,
            32,
            _kHomeTaskHorizontalPadding,
            32,
          ),
          child: Center(
            child: Text(
              'No tasks for this day.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      )
    else
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _kHomeTaskHorizontalPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = tasks[index];
              final last = index == tasks.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 4),
                child: _TaskTile(
                  task: task,
                  readOnly: readOnly,
                  onTap: readOnly
                      ? null
                      : () => showHomeTaskProgressEditor(context, ref, task),
                  onDelete: readOnly || !task.isStandalone
                      ? null
                      : () => repo.delete(task.id),
                ),
              );
            },
            childCount: tasks.length,
          ),
        ),
      ),
  ];
}

// --- Add Task Sheet ---

class _AddTaskSheet extends StatefulWidget {
  final void Function(String title, DateTime date) onSave;
  final DateTime initialDate;

  const _AddTaskSheet({
    required this.onSave,
    required this.initialDate,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  late DateTime _date;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _titleError = 'Required');
      return;
    }
    setState(() => _titleError = null);
    widget.onSave(text, _date);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New Task',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Task *',
              hintText: 'What do you need to do?',
              errorText: _titleError,
            ),
            onChanged: (_) => setState(() => _titleError = null),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(DateFormat.yMMMd().format(_date)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final HomeTask task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool readOnly;
  final bool showCarriedBadge;
  /// Distinct carry days (from [carrySpillDayCountsProvider]); defaults to 1.
  final int carrySpillDays;

  const _TaskTile({
    required this.task,
    this.onTap,
    this.onDelete,
    this.readOnly = false,
    this.showCarriedBadge = false,
    this.carrySpillDays = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        const SizedBox(width: 6),
                        _SourceBadge(source: task.source),
                        if (showCarriedBadge) ...[
                          const SizedBox(width: 6),
                          CarriedSpillBadge(spillDays: carrySpillDays),
                        ],
                      ],
                    ),
                    if (task.subtitle != null && task.subtitle!.isNotEmpty)
                      Text(
                        task.subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (showCarriedBadge)
                const SizedBox.shrink()
              else if (task.isLinked)
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5))
              else if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color:
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpilloverTile extends StatelessWidget {
  final HomeTask task;
  final VoidCallback onAddToToday;

  const _SpilloverTile({
    required this.task,
    required this.onAddToToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduled = DateFormat.MMMd().format(task.date);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary.withValues(alpha: 0.55),
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
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SourceBadge(source: task.source),
                    ],
                  ),
                  Text(
                    'Scheduled $scheduled · read-only',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (task.subtitle != null && task.subtitle!.isNotEmpty)
                    Text(
                      task.subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onAddToToday,
              child: const Text('Add to today'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final HomeTaskSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (String label, Color bg, Color fg) = switch (source) {
      HomeTaskSource.topic => (
          'T',
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer
        ),
      HomeTaskSource.chapter => (
          'C',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer
        ),
      HomeTaskSource.standalone => (
          '',
          Colors.transparent,
          Colors.transparent
        ),
    };

    if (source == HomeTaskSource.standalone) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
