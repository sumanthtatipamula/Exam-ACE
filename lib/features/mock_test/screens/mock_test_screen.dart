import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/mock_test/models/mock_test.dart';
import 'package:exam_ace/features/mock_test/utils/mock_test_score_style.dart';
import 'package:exam_ace/features/mock_test/providers/mock_test_provider.dart';
import 'package:exam_ace/features/mock_test/widgets/add_mock_test_sheet.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';
import 'package:exam_ace/shared/widgets/confirm_delete_dialog.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  const MockTestScreen({super.key});

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  /// `null` = all subjects
  String? _filterSubjectId;

  /// `null` = all chapters (within selected subject)
  String? _filterChapterId;

  /// When true, filter dropdowns are hidden (compact summary bar).
  bool _filterCollapsed = true;

  bool get _hasActiveFilters =>
      _filterSubjectId != null || _filterChapterId != null;

  void _onSubjectChanged(String? id) {
    setState(() {
      _filterSubjectId = id;
      _filterChapterId = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _filterSubjectId = null;
      _filterChapterId = null;
      _filterCollapsed = true;
    });
  }

  List<MockTest> _applyFilters(List<MockTest> tests) {
    return tests.where((t) {
      if (_filterSubjectId != null) {
        if (t.linkedSubjectId != _filterSubjectId) return false;
      }
      if (_filterChapterId != null) {
        if (t.linkedChapterId != _filterChapterId) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final testsAsync = ref.watch(mockTestsStreamProvider);
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

    List<Chapter> chaptersForFilter = [];
    if (_filterSubjectId != null) {
      chaptersForFilter =
          ref.watch(chaptersStreamProvider(_filterSubjectId!)).valueOrNull ??
              [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _filterCollapsed
              ? _CompactFilterBar(
                  subjects: subjects,
                  chapters: chaptersForFilter,
                  selectedSubjectId: _filterSubjectId,
                  selectedChapterId: _filterChapterId,
                  hasActiveFilters: _hasActiveFilters,
                  onExpand: () => setState(() => _filterCollapsed = false),
                  onClear: _hasActiveFilters ? _clearFilters : null,
                )
              : _FilterBar(
                  subjects: subjects,
                  chapters: chaptersForFilter,
                  selectedSubjectId: _filterSubjectId,
                  selectedChapterId: _filterChapterId,
                  onSubjectChanged: _onSubjectChanged,
                  onChapterChanged: (id) =>
                      setState(() => _filterChapterId = id),
                  onClear: _hasActiveFilters ? _clearFilters : null,
                  onMinimize: () => setState(() => _filterCollapsed = true),
                ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: testsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (tests) {
              final filtered = _applyFilters(tests);

              if (tests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No mock tests yet. Tap + to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No tests match the current filters.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all_rounded),
                          label: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final test = filtered[index];
                  return _MockTestTile(
                    test: test,
                    onEdit: () => _showEditSheet(context, test),
                    onDelete: () async {
                      final confirmed = await showConfirmDeleteDialog(context,
                          itemType: 'Mock Test',
                          itemName: test.title.isNotEmpty
                              ? test.title
                              : 'Mock Test');
                      if (!confirmed) return;
                      try {
                        await ref
                            .read(mockTestRepositoryProvider)
                            .delete(test.id);
                      } on Object catch (e) {
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            userFacingError(
                              e,
                              debugPrefix: 'Delete mock test',
                              releaseMessage:
                                  'Could not delete. Please try again.',
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, MockTest test) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddMockTestSheet(existing: test),
    );
  }
}

class _CompactFilterBar extends StatelessWidget {
  final List<Subject> subjects;
  final List<Chapter> chapters;
  final String? selectedSubjectId;
  final String? selectedChapterId;
  final bool hasActiveFilters;
  final VoidCallback onExpand;
  final VoidCallback? onClear;

  const _CompactFilterBar({
    required this.subjects,
    required this.chapters,
    required this.selectedSubjectId,
    required this.selectedChapterId,
    required this.hasActiveFilters,
    required this.onExpand,
    this.onClear,
  });

  String _summary() {
    Subject? sub;
    for (final s in subjects) {
      if (s.id == selectedSubjectId) {
        sub = s;
        break;
      }
    }
    final subName = sub?.name ?? 'Subject';
    if (selectedChapterId == null) {
      return subName;
    }
    Chapter? ch;
    for (final c in chapters) {
      if (c.id == selectedChapterId) {
        ch = c;
        break;
      }
    }
    final chName = ch?.name ?? 'Chapter';
    return '$subName · $chName';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.filter_alt_rounded,
                size: 22, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasActiveFilters ? 'Filters applied' : 'Filters hidden',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasActiveFilters ? _summary() : 'Showing all mock tests',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onExpand,
              tooltip: 'Show filters',
              icon: const Icon(Icons.expand_more_rounded, size: 22),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(10),
              ),
            ),
            if (onClear != null)
              IconButton.filledTonal(
                onPressed: onClear,
                tooltip: 'Clear filters',
                icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<Subject> subjects;
  final List<Chapter> chapters;
  final String? selectedSubjectId;
  final String? selectedChapterId;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onChapterChanged;
  final VoidCallback? onClear;
  final VoidCallback? onMinimize;

  const _FilterBar({
    required this.subjects,
    required this.chapters,
    required this.selectedSubjectId,
    required this.selectedChapterId,
    required this.onSubjectChanged,
    required this.onChapterChanged,
    this.onClear,
    this.onMinimize,
  });

  /// Keep selection valid if a linked subject/chapter was removed from Firestore.
  String? _safeSubjectValue() {
    if (selectedSubjectId == null) return null;
    return subjects.any((s) => s.id == selectedSubjectId)
        ? selectedSubjectId
        : null;
  }

  String? _safeChapterValue() {
    if (selectedChapterId == null) return null;
    return chapters.any((c) => c.id == selectedChapterId)
        ? selectedChapterId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasFilters = onClear != null;
    final chapterEnabled = selectedSubjectId != null;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.65),
      ),
    );

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Narrow results',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show tests linked to a subject or chapter',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFilters)
                  IconButton.filledTonal(
                    onPressed: onClear,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                    tooltip: 'Clear filters',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Subject',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _safeSubjectValue(),
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                labelText: 'Scope',
                hintText: 'All subjects',
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All subjects'),
                ),
                ...subjects.map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: onSubjectChanged,
            ),
            const SizedBox(height: 16),
            Text(
              'Chapter',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: chapterEnabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: chapterEnabled ? _safeChapterValue() : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: chapterEnabled ? 0.45 : 0.22,
                ),
                labelText: 'Refine',
                hintText: chapterEnabled
                    ? 'All chapters'
                    : 'Pick a subject first',
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: chapterEnabled
                  ? [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All chapters'),
                      ),
                      ...chapters.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child:
                              Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ]
                  : [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Pick a subject first',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
              onChanged: chapterEnabled ? onChapterChanged : null,
            ),
            if (selectedSubjectId != null && chapters.isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This subject has no chapters yet. Chapter filtering only applies to tests linked to a chapter.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onMinimize != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onMinimize,
                  icon: const Icon(Icons.expand_less_rounded, size: 20),
                  label: const Text('Hide filters'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single-line pill for marks, date, tier (Strong / Developing / Needs improvement), or link.
class _MetaChip extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final Widget? leading;
  final String label;
  final Color fg;
  final Color bg;
  final Color? borderColor;
  final FontWeight? fontWeight;
  final double maxLabelWidth;

  const _MetaChip({
    this.icon,
    this.iconSize = 14,
    this.leading,
    required this.label,
    required this.fg,
    required this.bg,
    this.borderColor,
    this.fontWeight,
    this.maxLabelWidth = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg.withValues(alpha: 0.92)),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: fontWeight ?? FontWeight.w600,
                fontSize: 12.5,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTestTile extends StatelessWidget {
  final MockTest test;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MockTestTile({
    required this.test,
    required this.onEdit,
    required this.onDelete,
  });

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = test.percentage;
    final pctRounded = pct.round();

    final scoreColor = MockTestScoreStyle.accent(colorScheme, pct);
    final tierChip = MockTestScoreStyle.tierChipColors(colorScheme, pct);

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    scoreColor.withValues(alpha: 0.1),
                    colorScheme.surfaceContainerLow,
                  ),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 3.5,
                        backgroundColor: Color.alphaBlend(
                          scoreColor.withValues(alpha: 0.14),
                          colorScheme.surfaceContainerHighest,
                        ),
                        color: scoreColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$pctRounded%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: scoreColor,
                          letterSpacing: -0.3,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      test.title.isNotEmpty ? test.title : 'Mock Test',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaChip(
                          icon: Icons.grading_rounded,
                          iconSize: 14,
                          label: '${test.marksObtained} / ${test.totalMarks}',
                          fg: colorScheme.onSurfaceVariant,
                          bg: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                        ),
                        _MetaChip(
                          icon: Icons.event_rounded,
                          iconSize: 13,
                          label: DateFormat.yMMMd().format(test.date),
                          fg: colorScheme.onSurfaceVariant,
                          bg: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                        ),
                        _MetaChip(
                          icon: MockTestScoreStyle.tierIcon(pct),
                          iconSize: 13,
                          label: MockTestScoreStyle.tierLabel(pct),
                          fg: tierChip.fg,
                          bg: tierChip.bg,
                          fontWeight: FontWeight.w700,
                        ),
                        if (test.linkedName != null &&
                            test.linkedName!.isNotEmpty)
                          _MetaChip(
                            leading: _LinkBadge(linkType: test.linkType),
                            label: test.linkedName!,
                            fg: colorScheme.primary,
                            bg: colorScheme.primaryContainer
                                .withValues(alpha: 0.55),
                            borderColor:
                                colorScheme.primary.withValues(alpha: 0.22),
                            maxLabelWidth: 160,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  final LinkType linkType;

  const _LinkBadge({required this.linkType});

  @override
  Widget build(BuildContext context) {
    if (linkType == LinkType.none) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final (String label, Color bg, Color fg) = switch (linkType) {
      LinkType.topic => (
          'T',
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer
        ),
      LinkType.chapter => (
          'C',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer
        ),
      LinkType.subject => (
          'S',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer
        ),
      LinkType.none => ('', Colors.transparent, Colors.transparent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
