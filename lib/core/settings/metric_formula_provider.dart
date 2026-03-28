import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
import 'package:exam_ace/core/settings/startup_prefs.dart';

class MetricFormulaNotifier extends Notifier<MetricFormulaMode> {
  @override
  MetricFormulaMode build() {
    return ref.read(startupPrefsProvider).metricFormula;
  }

  Future<void> setMode(MetricFormulaMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.metricFormulaMode, mode.name);
    } on PlatformException {
      // In-memory mode still applies for this session.
    }
  }
}

final metricFormulaProvider =
    NotifierProvider<MetricFormulaNotifier, MetricFormulaMode>(
  MetricFormulaNotifier.new,
);
