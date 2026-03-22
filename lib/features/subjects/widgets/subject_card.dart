import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:exam_ace/core/widgets/subject_completion_ring.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final int completion;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.completion,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 0.5,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            final idealImageH = maxW * 9 / 16;
            // Ring size: width-based so we don’t depend on hero height from [Expanded].
            final ringSize = maxW < 172 ? 54.0 : 62.0;

            Widget heroImage({required double imageH}) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_radius),
                ),
                child: SizedBox(
                  height: imageH,
                  width: maxW,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      subject.imageUrl != null
                          ? Image.network(
                              subject.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _iconPlaceholder(colorScheme),
                            )
                          : _iconPlaceholder(colorScheme),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: (imageH * 0.45).clamp(36.0, 52.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color.alphaBlend(
                                  colorScheme.primary.withValues(alpha: 0.18),
                                  colorScheme.shadow.withValues(alpha: 0.28),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final bottomBlock = Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _RoundIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit subject',
                        onTap: onEdit,
                      ),
                      _RoundIconButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete',
                        onTap: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            subject.date != null
                                ? DateFormat.yMMMd().format(subject.date!)
                                : 'No target date',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SubjectCompletionRing(
                        progress: completion.toDouble(),
                        size: ringSize,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Progress',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            // Fill the grid cell: hero expands so there’s no dead band under the footer.
            if (maxH.isFinite) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, heroConstraints) {
                        return heroImage(imageH: heroConstraints.maxHeight);
                      },
                    ),
                  ),
                  bottomBlock,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                heroImage(imageH: idealImageH),
                bottomBlock,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _iconPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.28),
              colorScheme.surfaceContainerHighest,
            ),
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.surfaceContainerHigh,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 36,
          color: colorScheme.primary.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.all(6),
          minimumSize: const Size(32, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
