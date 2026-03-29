import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
import 'package:exam_ace/core/settings/startup_prefs.dart';

class MetricFormulaNotifier extends Notifier<MetricFormulaMode> {
  @override
  MetricFormulaMode build() {
    return ref.read(startupPrefsProvider).metricFormula;
  }

  Future<void> setMode(MetricFormulaMode mode) async {
    state = mode;
    await persistPreferenceString(PrefsKeys.metricFormulaMode, mode.name);
  }
}

final metricFormulaProvider =
    NotifierProvider<MetricFormulaNotifier, MetricFormulaMode>(
  MetricFormulaNotifier.new,
);
