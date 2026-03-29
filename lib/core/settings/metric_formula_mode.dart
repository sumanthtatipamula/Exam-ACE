/// How **weekly progress %** (ribbon, week-over-week) is derived from task progress.
///
/// Surf bar **heights** use completed-task counts within the week; only the headline % and WoW use this.
enum MetricFormulaMode {
  /// Harmonic mean — penalizes inconsistency, rewards balance.
  balanced,

  /// Recent days matter more — builds on your momentum.
  momentum,

  /// Rewards steady daily performance with consistency bonus.
  consistent,
}

extension MetricFormulaModeLabels on MetricFormulaMode {
  /// One short word on the chip (fits in one row).
  String get title => switch (this) {
        MetricFormulaMode.balanced => 'Balanced',
        MetricFormulaMode.momentum => 'Momentum',
        MetricFormulaMode.consistent => 'Consistent',
      };

  /// One line under the setting title — plain language only.
  String get subtitle => switch (this) {
        MetricFormulaMode.balanced =>
          'Penalizes extremes — rewards working evenly across all tasks.',
        MetricFormulaMode.momentum =>
          'Recent days count more — finishing strong boosts your week score.',
        MetricFormulaMode.consistent =>
          'Rewards steady daily work — consistency bonus for regular progress.',
      };

  /// Extra help on long-press / tooltip.
  String get detailHint => switch (this) {
        MetricFormulaMode.balanced =>
          'Uses harmonic mean — having one task at 10% and another at 90% scores lower than both at 50%.',
        MetricFormulaMode.momentum =>
          'Days closer to today get more weight — building momentum through the week matters.',
        MetricFormulaMode.consistent =>
          'Calculates daily variance — lower variance (more consistent) adds a bonus to your score.',
      };

  /// Shown under the % on Home — plain words, not the chip label alone.
  String get ribbonShort => switch (this) {
        MetricFormulaMode.balanced => 'Penalizes extremes',
        MetricFormulaMode.momentum => 'Recent days matter more',
        MetricFormulaMode.consistent => 'Rewards consistency',
      };
}
