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

/// Keeps subject cards readable on tablets (avoid 2 huge columns edge-to-edge).
const double _kSubjectsContentMaxWidth = 1280;

int _subjectGridCrossAxisCount(double width) {
  if (width >= 1100) return 4;
  if (width >= 720) return 3;
  return 2;
}

double _subjectGridChildAspectRatio(double width) {
  if (width >= 1000) return 0.72;
  if (width >= 720) return 0.68;
  return 0.64;
}

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  bool _isGrid = true;

  SubjectsRepository get _repo => ref.read(subjectsRepositoryProvider);

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
    final topPad = MediaQuery.paddingOf(context).top + 8;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, topPad, 20, 8),
          child: Row(
            children: [
              Text(
                'Subjects',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              if (_isGrid) return _buildGrid(context, subjects);
              return _buildList(context, subjects);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<Subject> subjects) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = _subjectGridCrossAxisCount(width);
    final aspect = _subjectGridChildAspectRatio(width);
    final hPad = width >= 600 ? 24.0 : 16.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kSubjectsContentMaxWidth),
        child: GridView.builder(
          padding:
              EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: aspect,
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
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Subject> subjects) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 600 ? 24.0 : 16.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          padding:
              EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
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
        ),
      ),
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
