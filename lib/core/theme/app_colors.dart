import 'package:flutter/material.dart';

/// Central accent colors. [ColorScheme.fromSeed] builds light/dark themes from [seedColor].
///
/// ---
/// ## Pick a look (copy `seedColor` + `liquidToday` + `liquidPast` together)
///
/// **1. Ocean blue** — clear, familiar, good contrast. Safe default.
/// ```dart
/// seedColor: Color(0xFF2563EB); liquidToday: Color(0xFF60A5FA); liquidPast: Color(0xFF3B82F6);
/// ```
///
/// **2. Warm slate** — minimal, neutral; almost no “brand color” feel.
/// ```dart
/// seedColor: Color(0xFF475569); liquidToday: Color(0xFF94A3B8); liquidPast: Color(0xFF64748B);
/// ```
///
/// **3. Forest green** — calm, “progress / growth”, easy on the eyes.
/// ```dart
/// seedColor: Color(0xFF059669); liquidToday: Color(0xFF34D399); liquidPast: Color(0xFF10B981);
/// ```
///
/// **4. Coral / rose** — warm, friendly pink; lighter soft variant in comments above history.
/// ```dart
/// seedColor: Color(0xFFEC4899); liquidToday: Color(0xFFF9A8D4); liquidPast: Color(0xFFF472B6);
/// ```
///
/// **5. Deep amber / gold** — energetic, study-app energy without purple/teal.
/// ```dart
/// seedColor: Color(0xFFD97706); liquidToday: Color(0xFFFBBF24); liquidPast: Color(0xFFF59E0B);
/// ```
///
/// **6. Indigo / blue-violet** — purple-leaning accent; strong but still app-like.
/// ```dart
/// seedColor: Color(0xFF4F46E5); liquidToday: Color(0xFF818CF8); liquidPast: Color(0xFF6366F1);
/// ```
///
/// **7. Sky blue (current)** — same soft / light feel as the pink pass; pleasant, not harsh.
/// ```dart
/// seedColor: Color(0xFF0EA5E9); liquidToday: Color(0xFF7DD3FC); liquidPast: Color(0xFF38BDF8);
/// ```
///
/// *Alternate (deeper cyan):* `seedColor: Color(0xFF0891B2); liquidToday: Color(0xFF22D3EE); liquidPast: Color(0xFF06B6D4);`
class AppColors {
  AppColors._();

  /// Main app background in **light** theme (cool blue-gray; clearly not flat `#FFF`).
  static const Color lightSurface = Color(0xFFDFE8F2);

  /// Cards / elevated surfaces — soft, still off-white so they read above [lightSurface].
  static const Color lightSurfaceContainerLow = Color(0xFFF0F5FA);

  /// Primary brand tone (Material 3 derives full [ColorScheme] from this).
  /// **Sky blue** — soft, light accent (same “easy on the eyes” intent as the pink palette).
  static const Color seedColor = Color(0xFF0EA5E9);

  /// Weekly tracker “today” liquid highlight.
  static const Color liquidToday = Color(0xFF7DD3FC);

  /// Weekly tracker past days (slightly muted).
  static const Color liquidPast = Color(0xFF38BDF8);

  /// Calendar / completion legend — **sky** “all done” (matches sky-blue theme).
  static const Color allDone = Color(0xFF0284C7);
  static const Color partial = Color(0xFFFFA726);
  static const Color noneDone = Color(0xFFEF5350);

  /// Material 3 seed “tertiary” is often brown — we override [ColorScheme.tertiary] to this
  /// teal so rings, bars, and “100%” states read as success, not earth-tone.
  static const Color completionTertiary = Color(0xFF0D9488);
  static const Color onCompletionTertiary = Color(0xFFFFFFFF);
  static const Color completionTertiaryContainer = Color(0xFFCCFBF1);
  static const Color onCompletionTertiaryContainer = Color(0xFF134E4A);

  static const Color completionTertiaryDark = Color(0xFF2DD4BF);
  static const Color onCompletionTertiaryDark = Color(0xFF042F2E);
  static const Color completionTertiaryContainerDark = Color(0xFF134E4A);
  static const Color onCompletionTertiaryContainerDark = Color(0xFFCCFBF1);

  /// Home streak badge — warm orange (distinct from sky primary + teal completion).
  static const Color streakOrange = Color(0xFFF97316);
  static const Color streakOrangeContainer = Color(0xFFFFEDD5);
  static const Color onStreakOrangeContainer = Color(0xFF9A3412);
}
