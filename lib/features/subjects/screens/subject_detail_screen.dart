import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/core/widgets/themed_completion_bar.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/subjects/widgets/add_chapter_sheet.dart';
import 'package:exam_ace/shared/widgets/confirm_delete_dialog.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.read(subjectsRepositoryProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final chaptersAsync = ref.watch(chaptersStreamProvider(subjectId));

    final subject = subjectsAsync.valueOrNull
        ?.where((s) => s.id == subjectId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(subject?.name ?? 'Subject')),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chapters) {
          final completions = chapters.map((ch) {
            final topics = ref
                    .watch(topicsStreamProvider(
                        (subjectId: subjectId, chapterId: ch.id)))
                    .valueOrNull ??
                [];
            return chapterCompletion(ch, topics);
          }).toList();

          final overallCompletion = subjectCompletion(completions);

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall Completion',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          ThemedCompletionBar(
                            progress: overallCompletion.toDouble(),
                            height: 9,
                            borderRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$overallCompletion%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: overallCompletion >= 100
                                ? colorScheme.tertiary
                                : colorScheme.primary)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Chapters',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddChapter(context, repo),
                      icon: Icon(Icons.add_rounded,
                          color: colorScheme.primary),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent),
                      tooltip: 'Add chapter',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: chapters.isEmpty
                    ? Center(
                        child: Text('No chapters yet. Tap + to add one.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: chapters.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 4),
                        itemBuilder: (ctx, index) {
                          final ch = chapters[index];
                          final comp = completions[index];
                          final topics = ref
                                  .watch(topicsStreamProvider((
                                subjectId: subjectId,
                                chapterId: ch.id,
                              )))
                                  .valueOrNull ??
                              [];
                          return _ChapterTile(
                            chapter: ch,
                            completion: comp,
                            onTap: () => context.push(
                                '/subject/$subjectId/chapter/${ch.id}'),
                            onDelete: () async {
                              final confirmed =
                                  await showConfirmDeleteDialog(context,
                                      itemType: 'Chapter',
                                      itemName: ch.name);
                              if (!confirmed) return;
                              try {
                                await repo.deleteChapter(subjectId, ch.id);
                              } on Exception catch (e) {
                                if (context.mounted) {
                                  showErrorSnackBar(
                                      context, 'Failed to delete: $e');
                                }
                              }
                            },
                            onEdit: () => _editChapter(
                              context,
                              repo,
                              ch,
                              hasTopics: topics.isNotEmpty,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editChapter(
    BuildContext context,
    SubjectsRepository repo,
    Chapter chapter, {
    required bool hasTopics,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddChapterSheet(
        existing: chapter,
        hasTopics: hasTopics,
        onSave: (name, date, progress) {
          repo.updateChapter(
            subjectId,
            chapter.copyWith(
              name: name,
              date: date,
              progress: progress,
            ),
          );
        },
      ),
    );
  }

  void _showAddChapter(BuildContext context, SubjectsRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddChapterSheet(
        onSave: (name, date, progress) {
          repo.addChapter(
            subjectId,
            Chapter(
              id: '',
              subjectId: subjectId,
              name: name,
              date: date,
              progress: progress,
            ),
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final int completion;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ChapterTile({
    required this.chapter,
    required this.completion,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: completion / 100,
                strokeWidth: 3,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: completion >= 100
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              Center(
                child: completion >= 100
                    ? Icon(Icons.check_rounded,
                        size: 18, color: colorScheme.tertiary)
                    : Text('$completion',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        title: Text(chapter.name,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
            chapter.date != null
                ? DateFormat.yMMMd().format(chapter.date!)
                : 'No target date',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
