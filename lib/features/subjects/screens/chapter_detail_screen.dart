import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/subjects/widgets/add_topic_sheet.dart';
import 'package:exam_ace/core/utils/markdown_plain_preview.dart';
import 'package:exam_ace/features/subjects/screens/notes_editor_screen.dart';
import 'package:exam_ace/shared/widgets/confirm_delete_dialog.dart';

void _openChapterProgressSheet(
  BuildContext context,
  SubjectsRepository repo,
  Chapter chapter,
  String subjectId,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _SliderProgressSheet(
        title: chapter.name,
        initialProgress: chapter.progress,
        onSave: (value) {
          repo.updateChapter(
            subjectId,
            chapter.copyWith(progress: value),
          );
          Navigator.of(ctx).pop();
        },
      ),
    ),
  );
}

class ChapterDetailScreen extends ConsumerWidget {
  final String subjectId;
  final String chapterId;

  const ChapterDetailScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.read(subjectsRepositoryProvider);
    final chaptersAsync = ref.watch(chaptersStreamProvider(subjectId));
    final topicsAsync = ref.watch(topicsStreamProvider(
        (subjectId: subjectId, chapterId: chapterId)));

    final chapter = chaptersAsync.valueOrNull
        ?.where((c) => c.id == chapterId)
        .firstOrNull;
    final topics = topicsAsync.valueOrNull ?? [];

    final completion =
        chapter != null ? chapterCompletion(chapter, topics) : 0;
    final canEditChapterProgress = chapter != null && topics.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(chapter?.name ?? 'Chapter')),
      body: CustomScrollView(
        slivers: [
          // --- Completion bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completion',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        if (canEditChapterProgress)
                          Text(
                            'No topics yet — set progress manually',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text('$completion%',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: completion >= 100
                              ? colorScheme.tertiary
                              : colorScheme.primary)),
                  if (canEditChapterProgress)
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Set completion',
                      onPressed: () => _openChapterProgressSheet(
                        context,
                        repo,
                        chapter,
                        subjectId,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: canEditChapterProgress
                  ? InkWell(
                      onTap: () => _openChapterProgressSheet(
                        context,
                        repo,
                        chapter,
                        subjectId,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Tooltip(
                        message: 'Tap to set chapter completion',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completion / 100,
                            minHeight: 6,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: completion >= 100
                                ? colorScheme.tertiary
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        minHeight: 6,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                        color: completion >= 100
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                      ),
                    ),
            ),
          ),

          // --- Notes tile ---
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NotesTile(
                label: 'Chapter Notes',
                preview: chapter?.summaryNotes ?? '',
                onTap: () {
                  if (chapter == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotesEditorScreen(
                        title: '${chapter.name} — Notes',
                        initialContent: chapter.summaryNotes,
                        onSave: (content) {
                          repo.updateChapter(
                            subjectId,
                            chapter.copyWith(summaryNotes: content),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- Topics header ---
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Topics',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showAddTopic(context, repo),
                    icon: Icon(Icons.add_rounded,
                        color: colorScheme.primary),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent),
                    tooltip: 'Add topic',
                  ),
                ],
              ),
            ),
          ),

          // --- Topics list ---
          if (topics.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No topics yet. Tap + to add one.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
                ),
              ),
            )
          else
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList.separated(
                itemCount: topics.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (ctx, index) {
                  final topic = topics[index];
                  return _TopicTile(
                    topic: topic,
                    subjectId: subjectId,
                    onUpdateProgress: (progress) {
                      repo.updateTopic(subjectId, chapterId,
                          topic.copyWith(progress: progress));
                    },
                    onUpdateNotes: (notes) {
                      repo.updateTopic(
                          subjectId, chapterId, topic.copyWith(notes: notes));
                    },
                    onEdit: () => _showEditTopic(context, repo, topic),
                    onDelete: () async {
                      final confirmed = await showConfirmDeleteDialog(
                          context,
                          itemType: 'Topic',
                          itemName: topic.name);
                      if (!confirmed) return;
                      try {
                        await repo.deleteTopic(
                            subjectId, chapterId, topic.id);
                      } on Exception catch (e) {
                        if (context.mounted) {
                          showErrorSnackBar(
                              context, 'Failed to delete: $e');
                        }
                      }
                    },
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _showAddTopic(BuildContext context, SubjectsRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTopicSheet(
        onSave: (name, date, progress) {
          repo.addTopic(
            subjectId,
            chapterId,
            Topic(
              id: '',
              chapterId: chapterId,
              name: name,
              date: date,
              progress: progress,
            ),
          );
        },
      ),
    );
  }

  void _showEditTopic(
    BuildContext context,
    SubjectsRepository repo,
    Topic topic,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTopicSheet(
        existing: topic,
        onSave: (name, date, progress) {
          repo.updateTopic(
            subjectId,
            chapterId,
            topic.copyWith(
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

// --- Notes tile ---

class _NotesTile extends StatelessWidget {
  final String label;
  final String preview;
  final VoidCallback onTap;

  const _NotesTile({
    required this.label,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasContent = preview.trim().isNotEmpty;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note_rounded,
                    color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      hasContent
                          ? plainPreviewFromMarkdown(preview)
                          : 'Tap to add notes...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasContent
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                        fontStyle:
                            hasContent ? null : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Topic tile ---

class _TopicTile extends StatelessWidget {
  final Topic topic;
  final String subjectId;
  final ValueChanged<int> onUpdateProgress;
  final ValueChanged<String> onUpdateNotes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicTile({
    required this.topic,
    required this.subjectId,
    required this.onUpdateProgress,
    required this.onUpdateNotes,
    required this.onEdit,
    required this.onDelete,
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
        onTap: () => _showProgressSheet(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: SizedBox(
          width: 28,
          height: 28,
          child: topic.isComplete
              ? Icon(Icons.check_circle_rounded,
                  color: colorScheme.tertiary, size: 26)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: topic.progress / 100,
                      strokeWidth: 3,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                    Center(
                      child: Text('${topic.progress}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
        ),
        title: Text(topic.name,
            style: theme.textTheme.bodyLarge?.copyWith(
                decoration:
                    topic.isComplete ? TextDecoration.lineThrough : null,
                color: topic.isComplete
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface)),
        subtitle: topic.date != null
            ? Text(DateFormat.yMMMd().format(topic.date!),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _openNotes(context),
              child: Icon(
                topic.notes.trim().isNotEmpty
                    ? Icons.description_rounded
                    : Icons.note_add_outlined,
                size: 20,
                color: topic.notes.trim().isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEdit,
              child: Icon(Icons.edit_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.delete_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotesEditorScreen(
          title: '${topic.name} — Notes',
          initialContent: topic.notes,
          onSave: onUpdateNotes,
        ),
      ),
    );
  }

  void _showProgressSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return _SliderProgressSheet(
          title: topic.name,
          initialProgress: topic.progress,
          onSave: (value) {
            onUpdateProgress(value);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }
}

// --- Progress sheet (topics + chapter with no topics) ---

class _SliderProgressSheet extends StatefulWidget {
  final String title;
  final int initialProgress;
  final ValueChanged<int> onSave;

  const _SliderProgressSheet({
    required this.title,
    required this.initialProgress,
    required this.onSave,
  });

  @override
  State<_SliderProgressSheet> createState() => _SliderProgressSheetState();
}

class _SliderProgressSheetState extends State<_SliderProgressSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialProgress.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = _value.round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _value / 100,
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
                      : Text('$percent%',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _value,
            min: 0,
            max: 100,
            divisions: 20,
            label: '$percent%',
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onSave(_value.round()),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
