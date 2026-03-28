import 'dart:math' as math;

import 'package:exam_ace/core/settings/metric_formula_mode.dart';

/// Linear weekly metric: Σp / (n·100). Matches classic “average progress”.
double mathWeeklyRatio(List<int> progressPerTask) {
  if (progressPerTask.isEmpty) return 0.0;
  var sum = 0;
  for (final p in progressPerTask) {
    sum += p.clamp(0, 100);
  }
  return sum / (progressPerTask.length * 100.0);
}

/// **Cubic mean** of normalized progress: ( mean( (p/100)³ ) )^(1/3).
/// Pulls toward high completion more than a straight average (same as linear only when all tasks match).
double physicsWeeklyRatio(List<int> progressPerTask) {
  if (progressPerTask.isEmpty) return 0.0;
  var sumCube = 0.0;
  for (final p in progressPerTask) {
    final x = p.clamp(0, 100) / 100.0;
    sumCube += x * x * x;
  }
  return math.pow(sumCube / progressPerTask.length, 1.0 / 3.0).toDouble();
}

/// **Minimum** daily average among days that have at least one task (limiting day / “bottleneck”).
/// Empty week → 0.
double chemistryWeeklyRatio(
  List<double> dailyAverageRatios,
  List<int> taskCountPerDay,
) {
  assert(dailyAverageRatios.length == taskCountPerDay.length);
  var best = 1.0;
  var any = false;
  for (var i = 0; i < dailyAverageRatios.length; i++) {
    if (taskCountPerDay[i] > 0) {
      any = true;
      final v = dailyAverageRatios[i].clamp(0.0, 1.0);
      if (v < best) best = v;
    }
  }
  if (!any) return 0.0;
  return best;
}

double weeklyRatioForMode({
  required MetricFormulaMode mode,
  required List<int> progressPerTask,
  required List<double> dailyAverageRatios,
  required List<int> taskCountPerDay,
}) {
  return switch (mode) {
    MetricFormulaMode.math => mathWeeklyRatio(progressPerTask),
    MetricFormulaMode.physics => physicsWeeklyRatio(progressPerTask),
    MetricFormulaMode.chemistry =>
      chemistryWeeklyRatio(dailyAverageRatios, taskCountPerDay),
  };
}
