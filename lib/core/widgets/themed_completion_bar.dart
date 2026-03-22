import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Linear completion bar that stays **on-brand**: primary-tinted track (not flat grey),
/// gradient fill, light border — reads clearly in light and dark themes.
class ThemedCompletionBar extends StatelessWidget {
  /// Completion 0–100.
  final double progress;

  final double height;

  /// Use `999` for a pill, or `4–8` for a softer bar (e.g. subject detail header).
  final double borderRadius;

  const ThemedCompletionBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = (progress / 100).clamp(0.0, 1.0);
    final complete = progress >= 99.5;

    final track = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.16),
      scheme.surfaceContainerLow,
    );

    final Color hi = complete ? scheme.tertiary : scheme.primary;
    final Color lo = complete
        ? Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.75), scheme.surface)
        : Color.alphaBlend(scheme.primary.withValues(alpha: 0.78), scheme.surface);

    final borderColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.28),
      scheme.outlineVariant.withValues(alpha: 0.5),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: hi.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            // FractionallySizedBox + childless DecoratedBox can collapse to zero height
            // in a Stack, so the gradient never paints. Use explicit width/height.
            LayoutBuilder(
              builder: (context, constraints) {
                final fillW = math.max(0.0, constraints.maxWidth * v);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: fillW,
                    height: constraints.maxHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [hi, lo],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
