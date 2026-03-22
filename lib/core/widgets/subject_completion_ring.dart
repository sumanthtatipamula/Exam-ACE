import 'package:flutter/material.dart';

/// Circular completion gauge for subjects — reads clearly at **0%** (tinted track,
/// full accent arc) and matches the app’s mock-test score style without a thin grey bar.
class SubjectCompletionRing extends StatelessWidget {
  /// 0–100
  final double progress;

  final double size;

  const SubjectCompletionRing({
    super.key,
    required this.progress,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final v = (progress / 100).clamp(0.0, 1.0);
    final done = progress >= 99.5;
    final accent = done ? scheme.tertiary : scheme.primary;

    final track = Color.alphaBlend(
      accent.withValues(alpha: 0.22),
      scheme.surfaceContainerHighest,
    );

    final stroke = size >= 52 ? 4.5 : 5.0;
    final pad = size * 0.08;
    final fontSize = size >= 56 ? 13.0 : (size >= 48 ? 11.0 : 10.0);

    return Tooltip(
      message: '${progress.round()}% complete',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.35),
              scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(pad),
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                backgroundColor: track,
                color: accent,
                strokeCap: StrokeCap.round,
              ),
            ),
            Center(
              child: Text(
                '${progress.round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: -0.4,
                  color: accent,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
