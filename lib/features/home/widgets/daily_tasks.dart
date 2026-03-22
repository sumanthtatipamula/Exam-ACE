import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/features/home/models/task.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, HomeTaskSource, homeTaskEntityKey;
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/widgets/home_task_progress_sheet.dart';

void _openAddTaskSheet(
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

class DailyTasks extends ConsumerWidget {
  /// Tasks **scheduled** for [selectedDate] (native list — not spillover).
  final List<HomeTask> tasks;

  /// Shown only when [selectedDate] is today: tasks carried from earlier days (editable).
  final List<HomeTask> carriedTasks;

  /// Incomplete past-scheduled tasks not yet added to today (readonly + include).
  final List<HomeTask> spilloverTasks;

  final DateTime selectedDate;
  final DateTime today;

  const DailyTasks({
    super.key,
    required this.tasks,
    this.carriedTasks = const [],
    this.spilloverTasks = const [],
    required this.selectedDate,
    required this.today,
  });

  bool get _isToday => DateUtils.isSameDay(selectedDate, today);

  bool get _readonlyPast {
    final sd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final tod = DateTime(today.year, today.month, today.day);
    return sd.isBefore(tod);
  }

  String _sectionTitle() {
    if (_isToday) return "Today's tasks";
    return DateFormat.yMMMEd().format(selectedDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.read(tasksRepositoryProvider);
    final day = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (_isToday) {
      return _TodayTasksSplit(
        tasks: tasks,
        carriedTasks: carriedTasks,
        spilloverTasks: spilloverTasks,
        day: day,
      );
    }

    final readOnly = _readonlyPast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _sectionTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!readOnly)
              IconButton(
                onPressed: () => _openAddTaskSheet(context, repo, day),
                icon: Icon(Icons.add_rounded, color: colorScheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                tooltip: 'Add task',
              ),
          ],
        ),
        if (readOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Snapshot for this day — progress is frozen.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No tasks for this day.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
                task: task,
                readOnly: readOnly,
                onTap: readOnly
                    ? null
                    : () => showHomeTaskProgressEditor(context, ref, task),
                onDelete: readOnly || !task.isStandalone
                    ? null
                    : () => repo.delete(task.id),
              );
            },
          ),
      ],
    );
  }

}

/// Today view: always-visible [SegmentedButton] to switch between native tasks
/// and spillover (previously spillover was hidden when the list was empty).
class _TodayTasksSplit extends ConsumerStatefulWidget {
  final List<HomeTask> tasks;
  final List<HomeTask> carriedTasks;
  final List<HomeTask> spilloverTasks;
  final DateTime day;

  const _TodayTasksSplit({
    required this.tasks,
    required this.carriedTasks,
    required this.spilloverTasks,
    required this.day,
  });

  @override
  ConsumerState<_TodayTasksSplit> createState() => _TodayTasksSplitState();
}

class _TodayTasksSplitState extends ConsumerState<_TodayTasksSplit> {
  /// 0 = Today, 1 = Spill over
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.read(tasksRepositoryProvider);
    final day = widget.day;

    final todayNativeEmpty =
        widget.tasks.isEmpty && widget.carriedTasks.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
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
                selected: {_segment},
                onSelectionChanged: (Set<int> s) => setState(() => _segment = s.first),
              ),
            ),
            if (_segment == 0) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openAddTaskSheet(context, repo, day),
                icon: Icon(Icons.add_rounded, color: colorScheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                tooltip: 'Add task',
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_segment == 0) ...[
          if (todayNativeEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No tasks scheduled for today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.tasks.length + widget.carriedTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (index < widget.tasks.length) {
                  final task = widget.tasks[index];
                  return _TaskTile(
                    task: task,
                    onTap: () =>
                        showHomeTaskProgressEditor(context, ref, task),
                    onDelete: task.isStandalone
                        ? () => repo.delete(task.id)
                        : null,
                  );
                }
                final task = widget.carriedTasks[index - widget.tasks.length];
                return _TaskTile(
                  task: task,
                  showCarriedBadge: true,
                  onRemoveFromToday: () =>
                      repo.removeCarryFromToday(homeTaskEntityKey(task)),
                  onTap: () =>
                      showHomeTaskProgressEditor(context, ref, task),
                );
              },
            ),
        ] else ...[
          Text(
            'From earlier days. Not counted in week average, surf, streak, or ribbon totals.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.spilloverTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No spillover tasks.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.spilloverTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final task = widget.spilloverTasks[index];
                return _SpilloverTile(
                  task: task,
                  onAddToToday: () =>
                      repo.addCarryToToday(homeTaskEntityKey(task)),
                );
              },
            ),
        ],
      ],
    );
  }
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
    if (text.isEmpty) return;
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
            decoration: const InputDecoration(
              hintText: 'What do you need to do?',
            ),
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
  final VoidCallback? onRemoveFromToday;

  const _TaskTile({
    required this.task,
    this.onTap,
    this.onDelete,
    this.readOnly = false,
    this.showCarriedBadge = false,
    this.onRemoveFromToday,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Carried',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 10,
                              ),
                            ),
                          ),
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
              if (onRemoveFromToday != null)
                IconButton(
                  onPressed: onRemoveFromToday,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                  tooltip: 'Remove from today',
                )
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
