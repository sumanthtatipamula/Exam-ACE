/// How **weekly progress %** (ribbon, week-over-week) is derived from task progress.
///
/// Surf bar **heights** use completed-task counts within the week; only the headline % and WoW use this.
enum MetricFormulaMode {
  /// Straight average across tasks.
  math,

  /// Rewards tasks finished at high % more than many low-% tasks.
  physics,

  /// Your lowest day’s average sets the week (one bad day hurts a lot).
  chemistry,
}

extension MetricFormulaModeLabels on MetricFormulaMode {
  /// One short word on the chip (fits in one row).
  String get title => switch (this) {
        MetricFormulaMode.math => 'Simple',
        MetricFormulaMode.physics => 'Strong',
        MetricFormulaMode.chemistry => 'Strict',
      };

  /// One line under the setting title — plain language only.
  String get subtitle => switch (this) {
        MetricFormulaMode.math =>
          'Every task counts the same — like a normal average.',
        MetricFormulaMode.physics =>
          'Doing really well on tasks lifts your week more than many half-done ones.',
        MetricFormulaMode.chemistry =>
          'One slow day pulls your whole week down — not only your best day.',
      };

  /// Extra help on long-press / tooltip.
  String get detailHint => switch (this) {
        MetricFormulaMode.math =>
          'We add up all your task % and split evenly — easy to read, nothing hidden.',
        MetricFormulaMode.physics =>
          'If you finish topics at high %, that helps your week more than lots of tiny starts.',
        MetricFormulaMode.chemistry =>
          'We look at your weakest study day: if that day was low, your week score drops.',
      };

  /// Shown under the % on Home — plain words, not the chip label alone.
  String get ribbonShort => switch (this) {
        MetricFormulaMode.math => 'Normal average',
        MetricFormulaMode.physics => 'Rewards strong work',
        MetricFormulaMode.chemistry => 'Worst day counts',
      };
}
