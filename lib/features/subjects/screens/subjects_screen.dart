import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/features/subjects/widgets/add_subject_sheet.dart';
import 'package:exam_ace/features/subjects/widgets/subject_card.dart';
import 'package:exam_ace/features/subjects/widgets/subject_list_tile.dart';
import 'package:exam_ace/shared/widgets/confirm_delete_dialog.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  bool _isGrid = true;

  SubjectsRepository get _repo => ref.read(subjectsRepositoryProvider);

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSubjectSheet(
        onSave: (name, imageUrl, date) {
          _repo.addSubject(Subject(
            id: '',
            name: name,
            imageUrl: imageUrl,
            date: date,
            createdAt: DateTime.now(),
          ));
        },
      ),
    );
  }

  Future<void> _confirmDeleteSubject(Subject subject) async {
    final confirmed = await showConfirmDeleteDialog(context,
        itemType: 'Subject', itemName: subject.name);
    if (!confirmed) return;
    try {
      await _repo.deleteSubject(subject.id);
    } on Object catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          userFacingError(
            e,
            debugPrefix: 'Delete subject',
            releaseMessage: 'Could not delete. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> _editSubject(Subject subject) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSubjectSheet(
        existing: subject,
        onSave: (name, imageUrl, date) {
          final clearedCover =
              subject.imageUrl != null && imageUrl == null;
          _repo.updateSubject(
            subject.copyWith(
              name: name,
              imageUrl: imageUrl,
              clearImageUrl: clearedCover,
              date: date,
            ),
            clearImageUrl: clearedCover,
            previousImageUrlForStorageDelete:
                clearedCover ? subject.imageUrl : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text('My Subjects',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => _isGrid = !_isGrid),
                icon: Icon(
                    _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: colorScheme.primary),
                style:
                    IconButton.styleFrom(backgroundColor: Colors.transparent),
                tooltip: _isGrid ? 'List view' : 'Grid view',
              ),
              IconButton(
                onPressed: _showAddSheet,
                icon: Icon(Icons.add_rounded, color: colorScheme.primary),
                style:
                    IconButton.styleFrom(backgroundColor: Colors.transparent),
                tooltip: 'Add subject',
              ),
            ],
          ),
        ),
        Expanded(
          child: subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (subjects) {
              if (subjects.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No subjects yet. Tap + to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              if (_isGrid) return _buildGrid(subjects);
              return _buildList(subjects);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Subject> subjects) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        // width/height — higher = shorter cells (0.54 was ~full-screen tall cards).
        childAspectRatio: 0.64,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectCardWithCompletion(
          subject: subject,
          onTap: () => context.push('/subject/${subject.id}'),
          onDelete: () => _confirmDeleteSubject(subject),
          onEdit: () => _editSubject(subject),
        );
      },
    );
  }

  Widget _buildList(List<Subject> subjects) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectListTileWithCompletion(
          subject: subject,
          onTap: () => context.push('/subject/${subject.id}'),
          onDelete: () => _confirmDeleteSubject(subject),
          onEdit: () => _editSubject(subject),
        );
      },
    );
  }
}

class _SubjectCardWithCompletion extends ConsumerWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SubjectCardWithCompletion({
    required this.subject,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters =
        ref.watch(chaptersStreamProvider(subject.id)).valueOrNull ?? [];

    final completions = chapters.map((ch) {
      final topics = ref
              .watch(topicsStreamProvider(
                  (subjectId: subject.id, chapterId: ch.id)))
              .valueOrNull ??
          [];
      return chapterCompletion(ch, topics);
    }).toList();

    return SubjectCard(
      subject: subject,
      completion: subjectCompletion(completions),
      onTap: onTap,
      onDelete: onDelete,
      onEdit: onEdit,
    );
  }
}

class _SubjectListTileWithCompletion extends ConsumerWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SubjectListTileWithCompletion({
    required this.subject,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters =
        ref.watch(chaptersStreamProvider(subject.id)).valueOrNull ?? [];

    final completions = chapters.map((ch) {
      final topics = ref
              .watch(topicsStreamProvider(
                  (subjectId: subject.id, chapterId: ch.id)))
              .valueOrNull ??
          [];
      return chapterCompletion(ch, topics);
    }).toList();

    return SubjectListTile(
      subject: subject,
      completion: subjectCompletion(completions),
      onTap: onTap,
      onDelete: onDelete,
      onEdit: onEdit,
    );
  }
}
