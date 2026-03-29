import 'dart:math' as math;

import 'package:exam_ace/core/settings/metric_formula_mode.dart';

/// **Harmonic mean** of task progress: penalizes extremes, rewards balance.
/// Formula: n / Σ(1/p) where p is normalized progress (0-1).
/// Having tasks at 10% and 90% scores lower than both at 50%.
double balancedWeeklyRatio(List<int> progressPerTask) {
  if (progressPerTask.isEmpty) return 0.0;
  var sumReciprocals = 0.0;
  var validCount = 0;
  
  for (final p in progressPerTask) {
    final normalized = p.clamp(1, 100) / 100.0; // Clamp min to 1 to avoid division by zero
    sumReciprocals += 1.0 / normalized;
    validCount++;
  }
  
  if (validCount == 0) return 0.0;
  return validCount / sumReciprocals;
}

/// **Consistency-based** metric: average with bonus for low variance.
/// Formula: avg + (1 - variance) × 0.15 where variance is normalized std deviation.
/// Rewards steady daily performance across the week.
double consistentWeeklyRatio(
  List<double> dailyAverageRatios,
  List<int> taskCountPerDay,
) {
  assert(dailyAverageRatios.length == taskCountPerDay.length);
  
  var sum = 0.0;
  var count = 0;
  final validDays = <double>[];
  
  for (var i = 0; i < dailyAverageRatios.length; i++) {
    if (taskCountPerDay[i] > 0) {
      final v = dailyAverageRatios[i].clamp(0.0, 1.0);
      sum += v;
      count++;
      validDays.add(v);
    }
  }
  
  if (count == 0) return 0.0;
  final avg = sum / count;
  
  // Calculate variance (how spread out the daily scores are)
  if (validDays.length < 2) return avg; // Need at least 2 days for variance
  
  var varianceSum = 0.0;
  for (final day in validDays) {
    final diff = day - avg;
    varianceSum += diff * diff;
  }
  final variance = math.sqrt(varianceSum / validDays.length); // Standard deviation
  
  // Consistency bonus: lower variance = higher bonus (up to 15% boost)
  final consistencyBonus = (1.0 - variance) * 0.15;
  return (avg + consistencyBonus).clamp(0.0, 1.0);
}

/// **Momentum-based** weighted average: recent days count more.
/// Uses exponential weighting where later days in the week get progressively higher weights.
/// Formula: Σ(weight[i] × dailyAvg[i]) / Σ(weight[i]) where weight grows exponentially.
double momentumWeeklyRatio(
  List<double> dailyAverageRatios,
  List<int> taskCountPerDay,
) {
  assert(dailyAverageRatios.length == taskCountPerDay.length);
  var weightedSum = 0.0;
  var totalWeight = 0.0;
  
  for (var i = 0; i < dailyAverageRatios.length; i++) {
    if (taskCountPerDay[i] > 0) {
      // Exponential weight: day 0 gets 1.0, day 6 gets ~2.7 (e^1)
      // This creates a smooth gradient favoring recent days
      final weight = math.exp(i / (dailyAverageRatios.length - 1));
      final dayAvg = dailyAverageRatios[i].clamp(0.0, 1.0);
      weightedSum += weight * dayAvg;
      totalWeight += weight;
    }
  }
  
  if (totalWeight == 0) return 0.0;
  return weightedSum / totalWeight;
}

double weeklyRatioForMode({
  required MetricFormulaMode mode,
  required List<int> progressPerTask,
  required List<double> dailyAverageRatios,
  required List<int> taskCountPerDay,
}) {
  return switch (mode) {
    MetricFormulaMode.balanced => balancedWeeklyRatio(progressPerTask),
    MetricFormulaMode.momentum =>
      momentumWeeklyRatio(dailyAverageRatios, taskCountPerDay),
    MetricFormulaMode.consistent =>
      consistentWeeklyRatio(dailyAverageRatios, taskCountPerDay),
  };
}
