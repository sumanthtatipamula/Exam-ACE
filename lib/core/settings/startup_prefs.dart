import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
import 'package:exam_ace/core/theme/app_color_preset.dart';

/// Keys shared with [ThemeModeNotifier], [MetricFormulaNotifier], [AppColorPresetNotifier].
abstract final class PrefsKeys {
  static const themeMode = 'theme_mode';
  static const metricFormulaMode = 'metric_formula_mode';
  static const appColorPreset = 'app_color_preset';
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
        metricFormula: MetricFormulaMode.math,
        colorPreset: AppColorPreset.sky,
      );

  /// Load from disk; migrates legacy preset name when needed.
  static Future<StartupPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPreset = prefs.getString(PrefsKeys.appColorPreset);
    if (rawPreset == 'forestSpirit') {
      await prefs.setString(PrefsKeys.appColorPreset, AppColorPreset.forest.name);
    }
    return fromPrefs(prefs);
  }

  static StartupPrefs fromPrefs(SharedPreferences prefs) {
    var themeMode = ThemeMode.system;
    final rawTheme = prefs.getString(PrefsKeys.themeMode);
    if (rawTheme != null) {
      for (final m in ThemeMode.values) {
        if (m.name == rawTheme) {
          themeMode = m;
          break;
        }
      }
    }

    var metricFormula = MetricFormulaMode.math;
    final rawFormula = prefs.getString(PrefsKeys.metricFormulaMode);
    if (rawFormula != null) {
      for (final m in MetricFormulaMode.values) {
        if (m.name == rawFormula) {
          metricFormula = m;
          break;
        }
      }
    }

    var colorPreset = AppColorPreset.sky;
    final rawColor = prefs.getString(PrefsKeys.appColorPreset);
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
