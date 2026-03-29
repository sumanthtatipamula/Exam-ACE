import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, HomeTaskSource, homeTaskEntityKey;
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/widgets/home_task_progress_sheet.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';

enum _KanbanColumn { todo, inProgress, done }

class HomeKanbanBoard extends ConsumerWidget {
  final List<HomeTask> tasks;

  const HomeKanbanBoard({super.key, required this.tasks});

  static _KanbanColumn _columnFor(HomeTask t) {
    if (t.isComplete) return _KanbanColumn.done;
    if (t.progress > 0) return _KanbanColumn.inProgress;
    return _KanbanColumn.todo;
  }

  static Map<_KanbanColumn, List<HomeTask>> _split(List<HomeTask> tasks) {
    final map = {
      _KanbanColumn.todo: <HomeTask>[],
      _KanbanColumn.inProgress: <HomeTask>[],
      _KanbanColumn.done: <HomeTask>[],
    };
    for (final t in tasks) {
      map[_columnFor(t)]!.add(t);
    }
    return map;
  }

  static int _progressForTarget(HomeTask task, _KanbanColumn target) {
    switch (target) {
      case _KanbanColumn.todo:
        return 0;
      case _KanbanColumn.inProgress:
        if (task.progress >= 100) return 50;
        if (task.progress == 0) return 50;
        return task.progress.clamp(1, 99);
      case _KanbanColumn.done:
        return 100;
    }
  }

  Future<void> _applyMove(
    BuildContext context,
    WidgetRef ref,
    HomeTask task,
    _KanbanColumn target,
  ) async {
    if (_columnFor(task) == target) return;

    final next = _progressForTarget(task, target);
    if (task.progress == next) return;

    try {
      final repo = ref.read(tasksRepositoryProvider);
      switch (task.source) {
        case HomeTaskSource.standalone:
          await repo.updateProgress(task.id, next);
          break;
        case HomeTaskSource.topic:
          await ref.read(subjectsRepositoryProvider).updateTopicProgress(
                task.subjectId!,
                task.chapterId!,
                task.topicId!,
                next,
              );
          break;
        case HomeTaskSource.chapter:
          await ref.read(subjectsRepositoryProvider).updateChapterProgress(
                task.subjectId!,
                task.id,
                next,
              );
          break;
      }
      await repo.recordProgressForSnapshotIfScheduledToday(
        scheduledDateKey: dateKey(task.date),
        entityKey: homeTaskEntityKey(task),
        progress: next,
      );
      final carrySet =
          (ref.read(carryIdsForTodayProvider).valueOrNull ?? []).toSet();
      if (carrySet.contains(homeTaskEntityKey(task))) {
        await repo.mergeProgressIntoTodaySnapshot(
          entityKey: homeTaskEntityKey(task),
          progress: next,
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          userFacingError(
            e,
            debugPrefix: 'Update task',
            releaseMessage: 'Could not update. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final split = _split(tasks);
    final h = (MediaQuery.sizeOf(context).height * 0.38).clamp(300.0, 520.0);
    final repo = ref.read(tasksRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Long press a card to move between columns',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KanbanColumnPanel(
                  title: 'To do',
                  color: colorScheme.surfaceContainerHighest,
                  accent: colorScheme.outlineVariant,
                  tasks: split[_KanbanColumn.todo]!,
                  tasksRepo: repo,
                  onDrop: (task) =>
                      _applyMove(context, ref, task, _KanbanColumn.todo),
                  onTap: (task) =>
                      showHomeTaskProgressEditor(context, ref, task),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KanbanColumnPanel(
                  title: 'Doing',
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
                  accent: colorScheme.secondary.withValues(alpha: 0.45),
                  tasks: split[_KanbanColumn.inProgress]!,
                  tasksRepo: repo,
                  onDrop: (task) =>
                      _applyMove(context, ref, task, _KanbanColumn.inProgress),
                  onTap: (task) =>
                      showHomeTaskProgressEditor(context, ref, task),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KanbanColumnPanel(
                  title: 'Done',
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                  accent: colorScheme.tertiary.withValues(alpha: 0.5),
                  tasks: split[_KanbanColumn.done]!,
                  tasksRepo: repo,
                  onDrop: (task) =>
                      _applyMove(context, ref, task, _KanbanColumn.done),
                  onTap: (task) =>
                      showHomeTaskProgressEditor(context, ref, task),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KanbanColumnPanel extends StatelessWidget {
  final String title;
  final Color color;
  final Color accent;
  final List<HomeTask> tasks;
  final TasksRepository tasksRepo;
  final Future<void> Function(HomeTask task) onDrop;
  final void Function(HomeTask task) onTap;

  const _KanbanColumnPanel({
    required this.title,
    required this.color,
    required this.accent,
    required this.tasks,
    required this.tasksRepo,
    required this.onDrop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DragTarget<HomeTask>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejected) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight ? colorScheme.primary : accent,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Drop here',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final card = _KanbanMiniCard(
                            task: task,
                            onTap: () => onTap(task),
                            onDelete: task.isStandalone
                                ? () => tasksRepo.delete(task.id)
                                : null,
                          );
                          return LongPressDraggable<HomeTask>(
                            data: task,
                            hapticFeedbackOnStart: true,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 200,
                                child: _KanbanMiniCard(
                                  task: task,
                                  onTap: () {},
                                  onDelete: null,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: card,
                            ),
                            child: card,
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
}

class _KanbanMiniCard extends StatelessWidget {
  final HomeTask task;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _KanbanMiniCard({
    required this.task,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: task.isComplete
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.tertiary,
                        size: 20,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: task.progress / 100,
                            strokeWidth: 2.5,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: colorScheme.primary,
                          ),
                          Center(
                            child: Text(
                              '${task.progress}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        decoration: task.isComplete
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isComplete
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (task.subtitle != null && task.subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: colorScheme.primary.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
