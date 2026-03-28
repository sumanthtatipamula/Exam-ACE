import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/core/widgets/subject_completion_ring.dart';
import 'package:exam_ace/core/widgets/themed_completion_bar.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/mock_test/providers/mock_test_provider.dart';
import 'package:exam_ace/features/mock_test/widgets/linked_mock_test_views.dart';
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
    final subjectMockTests =
        ref.watch(mockTestsForSubjectProvider(subjectId));

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
                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _SubjectOverallCompletionCard(
                  completion: overallCompletion,
                  chapterCompletions: completions,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              SubjectMockTestsChartSection(
                tests: subjectMockTests,
                subjectTitle: subject?.name ?? 'Subject',
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
                            number: index + 1,
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
              createdAt: DateTime.now(),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectOverallCompletionCard extends StatelessWidget {
  final int completion;
  final List<int> chapterCompletions;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SubjectOverallCompletionCard({
    required this.completion,
    required this.chapterCompletions,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final n = chapterCompletions.length;
    final done =
        chapterCompletions.where((c) => c >= 100).length;
    final accent = completion >= 100 ? colorScheme.tertiary : colorScheme.primary;
    final border = Color.alphaBlend(
      accent.withValues(alpha: 0.22),
      colorScheme.outlineVariant.withValues(alpha: 0.45),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: 0.10),
              colorScheme.surfaceContainerLow,
            ),
            colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SubjectCompletionRing(
                  progress: completion.toDouble(),
                  size: 76,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            size: 20,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Overall completion',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n == 0
                            ? 'Add chapters below to start tracking'
                            : n == 1
                                ? (done >= 1
                                    ? 'Your chapter is complete'
                                    : 'Finish your chapter to reach 100%')
                                : '$done of $n chapters fully complete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ThemedCompletionBar(
              progress: completion.toDouble(),
              height: 12,
              borderRadius: 999,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  /// 1-based position in the subject’s chapter list (creation order).
  final int number;
  final Chapter chapter;
  final int completion;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ChapterTile({
    required this.number,
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
        title: Text(
            '$number. ${chapter.name}',
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
