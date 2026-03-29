import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
import 'package:exam_ace/core/theme/app_color_preset.dart';

/// Keys shared with [ThemeModeNotifier], [MetricFormulaNotifier], [AppColorPresetNotifier].
/// Prefixed to avoid collisions with other plugins / host defaults; legacy keys are still read.
abstract final class PrefsKeys {
  static const themeMode = 'ea_theme_mode';
  static const metricFormulaMode = 'ea_metric_formula_mode';
  static const appColorPreset = 'ea_app_color_preset';

  static const _legacyThemeMode = 'theme_mode';
  static const _legacyMetricFormulaMode = 'metric_formula_mode';
  static const _legacyAppColorPreset = 'app_color_preset';
}

/// Writes [value] for [key] and reloads the prefs cache so the next [StartupPrefs.load] sees it.
Future<void> persistPreferenceString(String key, String value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(key, value);
    if (!ok && kDebugMode) {
      debugPrint('SharedPreferences setString returned false for $key');
    }
    try {
      await prefs.reload();
    } on Object {
      // reload may be unsupported on some embedders
    }
  } on PlatformException catch (e) {
    if (kDebugMode) {
      debugPrint('SharedPreferences write failed for $key: $e');
    }
  } on Object catch (e) {
    if (kDebugMode) {
      debugPrint('SharedPreferences write failed for $key: $e');
    }
  }
}

/// Values read once in [main] before [runApp] so theme / formula / palette apply on first frame.
class StartupPrefs {
  const StartupPrefs({
    required this.themeMode,
    required this.metricFormula,
    required this.colorPreset,
  });

  final ThemeMode themeMode;
  final MetricFormulaMode metricFormula;
  final AppColorPreset colorPreset;

  static StartupPrefs defaults() => const StartupPrefs(
        themeMode: ThemeMode.system,
        metricFormula: MetricFormulaMode.balanced,
        colorPreset: AppColorPreset.sky,
      );

  /// Load from disk; migrates legacy preset name when needed.
  static Future<StartupPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } on Object {
      // Some platforms may not support reload; continue with cached prefs.
    }
    final rawPreset = prefs.getString(PrefsKeys.appColorPreset) ??
        prefs.getString(PrefsKeys._legacyAppColorPreset);
    if (rawPreset == 'forestSpirit') {
      await prefs.setString(PrefsKeys.appColorPreset, AppColorPreset.forest.name);
    }
    return fromPrefs(prefs);
  }

  static StartupPrefs fromPrefs(SharedPreferences prefs) {
    var themeMode = ThemeMode.system;
    final rawTheme = prefs.getString(PrefsKeys.themeMode) ??
        prefs.getString(PrefsKeys._legacyThemeMode);
    if (rawTheme != null) {
      for (final m in ThemeMode.values) {
        if (m.name == rawTheme) {
          themeMode = m;
          break;
        }
      }
    }

    var metricFormula = MetricFormulaMode.balanced;
    final rawFormula = prefs.getString(PrefsKeys.metricFormulaMode) ??
        prefs.getString(PrefsKeys._legacyMetricFormulaMode);
    if (rawFormula != null) {
      // Migrate old enum values to new ones
      metricFormula = switch (rawFormula) {
        'math' => MetricFormulaMode.balanced,
        'physics' => MetricFormulaMode.momentum,
        'chemistry' => MetricFormulaMode.consistent,
        _ => MetricFormulaMode.values.firstWhere(
            (m) => m.name == rawFormula,
            orElse: () => MetricFormulaMode.balanced,
          ),
      };
    }

    var colorPreset = AppColorPreset.sky;
    final rawColor = prefs.getString(PrefsKeys.appColorPreset) ??
        prefs.getString(PrefsKeys._legacyAppColorPreset);
    if (rawColor != null) {
      for (final p in AppColorPreset.values) {
        if (p.name == rawColor) {
          colorPreset = p;
          break;
        }
      }
    }

    return StartupPrefs(
      themeMode: themeMode,
      metricFormula: metricFormula,
      colorPreset: colorPreset,
    );
  }
}

/// Default [StartupPrefs.defaults]; [main] overrides with [StartupPrefs.load].
final startupPrefsProvider = Provider<StartupPrefs>((ref) => StartupPrefs.defaults());
