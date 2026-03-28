/// How chapters (per subject) and topics (per chapter) are ordered in lists.
enum SyllabusSortMode {
  /// `createdAt` when present; legacy rows by name (same as original app behavior).
  creation,

  /// Soonest [Chapter.date] / [Topic.date] first; undated entries last, then by name.
  targetDate,

  /// Alphabetical A→Z, then by id.
  nameAZ,

  /// Highest completion first (useful to see what’s almost done).
  progressHigh,

  /// Lowest completion first (what needs work first).
  progressLow,
}

extension SyllabusSortModeLabels on SyllabusSortMode {
  String get title => switch (this) {
        SyllabusSortMode.creation => 'Creation order',
        SyllabusSortMode.targetDate => 'Target date',
        SyllabusSortMode.nameAZ => 'Name (A–Z)',
        SyllabusSortMode.progressHigh => 'Progress (high first)',
        SyllabusSortMode.progressLow => 'Progress (low first)',
      };

  String get subtitle => switch (this) {
        SyllabusSortMode.creation => 'Oldest added first when dates are stored',
        SyllabusSortMode.targetDate => 'Soonest exam / target date at the top',
        SyllabusSortMode.nameAZ => 'Alphabetical by title',
        SyllabusSortMode.progressHigh => 'Most complete at the top',
        SyllabusSortMode.progressLow => 'Least complete at the top',
      };
}
