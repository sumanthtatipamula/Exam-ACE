import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/utils/safe_error_message.dart';
import 'package:exam_ace/core/utils/snackbar_helpers.dart';
import 'package:exam_ace/features/exam_score/models/exam_score.dart';
import 'package:exam_ace/features/exam_score/providers/exam_score_provider.dart';
import 'package:exam_ace/features/exam_score/widgets/add_exam_score_sheet.dart';
import 'package:exam_ace/shared/widgets/confirm_delete_dialog.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rowsAsync = ref.watch(examsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: rowsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No exams yet. Tap + to add one.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _ExamTile(
                    row: row,
                    onEdit: () => _showEdit(context, row),
                    onDelete: () async {
                      final confirmed = await showConfirmDeleteDialog(
                        context,
                        itemType: 'Exam',
                        itemName:
                            row.examName.isNotEmpty ? row.examName : 'Exam',
                      );
                      if (!confirmed) return;
                      try {
                        await ref.read(examRepositoryProvider).delete(row.id);
                      } on Object catch (e) {
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            userFacingError(
                              e,
                              debugPrefix: 'Delete exam',
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

  void _showEdit(BuildContext context, Exam row) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExamSheet(existing: row),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final String label;
  final Color fg;
  final Color bg;
  final FontWeight? fontWeight;

  const _MetaChip({
    this.icon,
    this.iconSize = 14,
    required this.label,
    required this.fg,
    required this.bg,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg.withValues(alpha: 0.92)),
            const SizedBox(width: 5),
          ],
          Text(
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
        ],
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  final Exam row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamTile({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = row.percentage;
    final hasPct = pct != null;
    final p = pct ?? 0.0;

    final scoreColor = colorScheme.primary;

    Widget leading;
    if (hasPct) {
      final pctRounded = p.round();
      leading = Container(
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
                value: p / 100,
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
      );
    } else {
      leading = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer.withValues(alpha: 0.45),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          row.status == ExamAttemptStatus.yetToTake
              ? Icons.calendar_month_rounded
              : Icons.assignment_outlined,
          color: colorScheme.primary,
          size: 26,
        ),
      );
    }

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
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.examName.isNotEmpty ? row.examName : 'Exam',
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
                        if (hasPct &&
                            row.marksObtained != null &&
                            row.totalMarks != null)
                          _MetaChip(
                            icon: Icons.grading_rounded,
                            iconSize: 14,
                            label:
                                '${row.marksObtained} / ${row.totalMarks}',
                            fg: colorScheme.onSurfaceVariant,
                            bg: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                          ),
                        _MetaChip(
                          icon: Icons.event_rounded,
                          iconSize: 13,
                          label: DateFormat.yMMMd().format(row.date),
                          fg: colorScheme.onSurfaceVariant,
                          bg: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                        ),
                        if (row.status == ExamAttemptStatus.yetToTake)
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            iconSize: 13,
                            label: 'Yet to take',
                            fg: colorScheme.onPrimaryContainer,
                            bg: colorScheme.primaryContainer
                                .withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          )
                        else if (!hasPct)
                          _MetaChip(
                            icon: Icons.edit_note_rounded,
                            iconSize: 13,
                            label: 'Taken',
                            fg: colorScheme.onSurfaceVariant,
                            bg: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
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
