import 'package:flutter/material.dart';

/// Score bands and colors — mock test tiles, subject bar charts, exams.
///
/// Bands use **fixed hue families** (red / blue / green) so they stay distinguishable
/// on warm themes (e.g. Fire) where [ColorScheme.primary] and [ColorScheme.error] can
/// both read as orange-red.
///
/// - **Green** — ≥ [strongMinInclusive]
/// - **Red** — &lt; [needsImprovementMaxExclusive] (strictly below 30%)
/// - **Blue** — between those bands (Developing)
abstract final class MockTestScoreStyle {
  /// Inclusive: **≥ this** → green.
  static const double strongMinInclusive = 70;

  /// Exclusive: scores **strictly below** this → red (Needs improvement).
  static const double needsImprovementMaxExclusive = 30;

  /// Strong band — same green on all themes.
  static Color _greenAccent(Brightness b) {
    return b == Brightness.dark
        ? const Color(0xFF81C784)
        : const Color(0xFF2E7D32);
  }

  /// Cool red — distinct from orange [ColorScheme.primary] on Fire.
  static Color _needsImprovementAccent(Brightness b) {
    return b == Brightness.dark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB71C1C);
  }

  /// Cool blue — never clashes with orange primary / warm error.
  static Color _developingAccent(Brightness b) {
    return b == Brightness.dark
        ? const Color(0xFF64B5F6)
        : const Color(0xFF1565C0);
  }

  static Color accent(ColorScheme cs, double percentage) {
    final p = percentage.clamp(0.0, 100.0);
    final b = cs.brightness;
    if (p < needsImprovementMaxExclusive) {
      return _needsImprovementAccent(b);
    }
    if (p >= strongMinInclusive) {
      return _greenAccent(b);
    }
    return _developingAccent(b);
  }

  static String tierLabel(double percentage) {
    final p = percentage.clamp(0.0, 100.0);
    if (p >= strongMinInclusive) return 'Strong';
    if (p < needsImprovementMaxExclusive) return 'Needs improvement';
    return 'Developing';
  }

  static IconData tierIcon(double percentage) {
    final p = percentage.clamp(0.0, 100.0);
    if (p >= strongMinInclusive) return Icons.emoji_events_rounded;
    if (p < needsImprovementMaxExclusive) return Icons.flag_outlined;
    return Icons.trending_up_rounded;
  }

  static ({Color fg, Color bg}) tierChipColors(
    ColorScheme cs,
    double percentage,
  ) {
    final p = percentage.clamp(0.0, 100.0);
    final isDark = cs.brightness == Brightness.dark;

    if (p >= strongMinInclusive) {
      final base =
          isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
      final fg =
          isDark ? const Color(0xFFE8F5E9) : const Color(0xFF1B5E20);
      return (fg: fg, bg: base.withValues(alpha: 0.22));
    }
    if (p < needsImprovementMaxExclusive) {
      if (isDark) {
        return (
          fg: const Color(0xFFFFCDD2),
          bg: const Color(0xFFB71C1C).withValues(alpha: 0.45),
        );
      }
      return (
        fg: const Color(0xFF7F1D1D),
        bg: const Color(0xFFFFEBEE).withValues(alpha: 0.95),
      );
    }
    return (
      fg: isDark ? const Color(0xFFE3F2FD) : const Color(0xFF0D47A1),
      bg: isDark
          ? const Color(0xFF1565C0).withValues(alpha: 0.45)
          : const Color(0xFFE3F2FD).withValues(alpha: 0.95),
    );
  }
}
