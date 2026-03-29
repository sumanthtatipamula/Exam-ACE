import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, HomeTaskSource, homeTaskEntityKey;
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/widgets/task_completion_celebration.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';

/// Opens the progress editor for [task] from Home / Calendar.
Future<void> showHomeTaskProgressEditor(
  BuildContext context,
  WidgetRef ref,
  HomeTask task,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _HomeProgressSheet(
          title: task.title,
          subtitle: task.subtitle,
          initialProgress: task.progress,
          showOpenChapter: task.source == HomeTaskSource.topic ||
              task.source == HomeTaskSource.chapter,
          onOpenChapter: (task.subjectId != null && task.chapterId != null)
              ? () {
                  Navigator.of(ctx).pop();
                  context.push(
                    '/subject/${task.subjectId}/chapter/${task.chapterId}',
                  );
                }
              : null,
          onSave: (value) async {
            final reachedFull =
                value >= 100 && task.progress < 100;
            try {
              final repo = ref.read(tasksRepositoryProvider);
              switch (task.source) {
                case HomeTaskSource.standalone:
                  await repo.updateProgress(task.id, value);
                  break;
                case HomeTaskSource.topic:
                  await ref.read(subjectsRepositoryProvider).updateTopicProgress(
                        task.subjectId!,
                        task.chapterId!,
                        task.topicId!,
                        value,
                      );
                  break;
                case HomeTaskSource.chapter:
                  await ref
                      .read(subjectsRepositoryProvider)
                      .updateChapterProgress(
                        task.subjectId!,
                        task.id,
                        value,
                      );
                  break;
              }
              await repo.recordProgressForSnapshotIfScheduledToday(
                scheduledDateKey: dateKey(task.date),
                entityKey: homeTaskEntityKey(task),
                progress: value,
              );
              final carrySet =
                  (ref.read(carryIdsForTodayProvider).valueOrNull ?? [])
                      .toSet();
              if (carrySet.contains(homeTaskEntityKey(task))) {
                await repo.mergeProgressIntoTodaySnapshot(
                  entityKey: homeTaskEntityKey(task),
                  progress: value,
                );
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (reachedFull && context.mounted) {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                if (context.mounted) {
                  await showTaskCompletionCelebration(context);
                }
              }
            } on Object catch (e) {
              if (context.mounted) {
                showErrorSnackBar(
                  context,
                  userFacingError(
                    e,
                    debugPrefix: 'Save progress',
                    releaseMessage: 'Could not save. Please try again.',
                  ),
                );
              }
            }
          },
        ),
      );
    },
  );
}

class _HomeProgressSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int initialProgress;
  final bool showOpenChapter;
  final VoidCallback? onOpenChapter;
  final Future<void> Function(int value) onSave;

  const _HomeProgressSheet({
    required this.title,
    this.subtitle,
    required this.initialProgress,
    required this.showOpenChapter,
    this.onOpenChapter,
    required this.onSave,
  });

  @override
  State<_HomeProgressSheet> createState() => _HomeProgressSheetState();
}

class _HomeProgressSheetState extends State<_HomeProgressSheet> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.initialProgress.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = _sliderValue.round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _sliderValue / 100,
                  strokeWidth: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: percent >= 100
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                ),
                Center(
                  child: percent >= 100
                      ? Icon(Icons.check_rounded,
                          size: 36, color: colorScheme.tertiary)
                      : Text(
                          '$percent%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _sliderValue,
            min: 0,
            max: 100,
            divisions: 20,
            label: '$percent%',
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final preset in [0, 25, 50, 75, 100])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _PresetChip(
                      label: '$preset%',
                      selected: percent == preset,
                      onTap: () =>
                          setState(() => _sliderValue = preset.toDouble()),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await widget.onSave(_sliderValue.round());
              },
              child: const Text('Save'),
            ),
          ),
          if (widget.showOpenChapter && widget.onOpenChapter != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onOpenChapter,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open in Subjects'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
