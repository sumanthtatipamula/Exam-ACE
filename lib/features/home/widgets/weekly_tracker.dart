import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/features/home/providers/tasks_provider.dart';

/// Always-visible streak; pops when it increases, shakes + flashes when it drops.
class _StreakBadge extends StatefulWidget {
  final int streak;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _StreakBadge({
    required this.streak,
    required this.colorScheme,
    required this.theme,
  });

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge>
    with TickerProviderStateMixin {
  late AnimationController _increaseController;
  late Animation<double> _increaseScale;
  late AnimationController _brokenController;

  @override
  void initState() {
    super.initState();
    _increaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _increaseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 68,
      ),
    ]).animate(_increaseController);

    _brokenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
  }

  @override
  void didUpdateWidget(covariant _StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak > oldWidget.streak) {
      _increaseController.forward(from: 0);
      HapticFeedback.lightImpact();
    }
    if (widget.streak < oldWidget.streak && oldWidget.streak > 0) {
      _brokenController.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _increaseController.dispose();
    _brokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final textTheme = widget.theme.textTheme;
    final dark = widget.theme.brightness == Brightness.dark;
    final s = widget.streak;

    return AnimatedBuilder(
      animation: Listenable.merge([_increaseController, _brokenController]),
      builder: (context, child) {
        final br = _brokenController.value;
        final shake = math.sin(br * math.pi * 7) * 4.2 * (1 - br);
        final errorPulse = br > 0 ? 0.55 * math.sin(br * math.pi) : 0.0;
        final scale = _increaseScale.value;

        final active = s > 0;
        final streakFill = dark
            ? Color.alphaBlend(
                AppColors.streakOrange.withValues(alpha: 0.32),
                cs.surfaceContainerHigh,
              )
            : AppColors.streakOrangeContainer;
        final bg = Color.lerp(
          active ? streakFill : cs.surfaceContainerHighest,
          cs.errorContainer,
          errorPulse,
        )!;
        final borderCol = Color.lerp(
          active
              ? AppColors.streakOrange.withValues(alpha: dark ? 0.5 : 0.4)
              : cs.outlineVariant.withValues(alpha: 0.5),
          cs.error,
          errorPulse * 0.85,
        )!;
        final iconCol = Color.lerp(
          active
              ? AppColors.streakOrange
              : cs.onSurfaceVariant.withValues(alpha: 0.45),
          cs.error,
          errorPulse * 0.75,
        )!;
        final numCol = Color.lerp(
          active
              ? (dark
                  ? const Color(0xFFFFFBEB)
                  : AppColors.onStreakOrangeContainer)
              : cs.onSurfaceVariant,
          cs.onErrorContainer,
          errorPulse * 0.6,
        )!;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol),
                boxShadow: s > 0 &&
                        _increaseController.value > 0.02 &&
                        _increaseController.value < 0.98
                    ? [
                        BoxShadow(
                          color: AppColors.streakOrange.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    br > 0.12 && br < 0.88
                        ? Icons.heart_broken_rounded
                        : Icons.local_fire_department_rounded,
                    size: 18,
                    color: iconCol,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$s',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: numCol,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    s == 1 ? 'day' : 'days',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: numCol.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Week **summary ribbon** (replaces tide) + **surf** bars. Tap a weekday to select
/// that day (see [onDaySelected]).
class WeeklyTracker extends StatelessWidget {
  final Map<String, double> completions;
  final WeeklySurfData surfData;
  final WeekOverWeekStats weekOverWeek;
  final int streak;

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  const WeeklyTracker({
    super.key,
    required this.completions,
    required this.surfData,
    required this.weekOverWeek,
    required this.streak,
    required this.selectedDate,
    required this.today,
    required this.onDaySelected,
  });

  static double _weekAverage(Map<String, double> completions, DateTime today) {
    final wd = today.weekday;
    final monday =
        DateTime(today.year, today.month, today.day).subtract(Duration(days: wd - 1));
    double sum = 0;
    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = dateKey(date);
      sum += (completions[key] ?? 0.0).clamp(0.0, 1.0);
    }
    return sum / 7.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wd = today.weekday;
    final monday =
        DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: wd - 1));

    final days = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final key = dateKey(date);
      final completion = completions[key] ?? 0.0;
      final isToday = DateUtils.isSameDay(date, today);
      final isPast = date.isBefore(today) && !isToday;
      return _DayData(
        label: _shortDay(i),
        date: date.day,
        fullDate: DateTime(date.year, date.month, date.day),
        isToday: isToday,
        isPast: isPast,
        completion: completion,
      );
    });

    var selectedIndex = -1;
    for (var i = 0; i < 7; i++) {
      if (DateUtils.isSameDay(days[i].fullDate, selectedDate)) {
        selectedIndex = i;
        break;
      }
    }
    if (selectedIndex < 0) {
      selectedIndex = today.weekday - 1;
    }

    final values = surfData.heights.length == 7
        ? surfData.heights.map((v) => v.clamp(0.0, 1.0)).toList()
        : days.map((d) => d.completion.clamp(0.0, 1.0)).toList();
    final taskTotals = surfData.taskTotalsPerDay.length == 7
        ? surfData.taskTotalsPerDay
        : List<int>.filled(7, 0);
    final completedPerDay = surfData.completedPerDay.length == 7
        ? surfData.completedPerDay
        : List<int>.filled(7, 0);
    final avgFill = _weekAverage(completions, today);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'This Week',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            _StreakBadge(
              streak: streak,
              colorScheme: colorScheme,
              theme: theme,
            ),
            const Spacer(),
            IconButton(
              onPressed: () => context.push('/calendar'),
              icon: Icon(
                Icons.calendar_month_rounded,
                color: colorScheme.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              tooltip: 'View calendar',
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            const surfHeight = 112.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WeekSummaryRibbon(
                  avgRatio: avgFill.clamp(0.0, 1.0),
                  completed: surfData.weekCompletedTotal,
                  total: surfData.weekTaskTotal,
                  weekOverWeek: weekOverWeek,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 10),
                _AnimatedSurfChart(
                  width: w,
                  height: surfHeight,
                  values: values,
                  taskTotalsPerDay: taskTotals,
                  completedPerDay: completedPerDay,
                  todayIndex:
                      days.indexWhere((d) => d.isToday).clamp(0, 6),
                  selectedIndex: selectedIndex,
                  primary: colorScheme.primary,
                  sand: colorScheme.surfaceContainerHigh,
                  borderColor: colorScheme.outlineVariant,
                  barFill: colorScheme.primary.withValues(alpha: 0.42),
                  barToday: colorScheme.primary.withValues(alpha: 0.72),
                  barSelected: colorScheme.primary.withValues(alpha: 0.92),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: List.generate(7, (i) {
                      final d = days[i];
                      final isSelected = selectedIndex == i;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onDaySelected(d.fullDate),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                            .withValues(alpha: 0.35)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.03 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: Column(
                                    children: [
                                      Text(
                                        d.label,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : (d.isToday
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.75)
                                                  : (!d.isPast
                                                      ? colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                              alpha: 0.45)
                                                      : colorScheme
                                                          .onSurfaceVariant)),
                                          fontWeight: isSelected || d.isToday
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${d.date}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : (d.isToday
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.85)
                                                  : (!d.isPast
                                                      ? colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.38)
                                                      : colorScheme
                                                          .onSurface)),
                                        ),
                                      ),
                                      if (isSelected)
                                        AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 220),
                                          margin: const EdgeInsets.only(
                                              top: 4),
                                          height: 3,
                                          width: 22,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        )
                                      else if (d.isToday)
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 4),
                                          height: 2,
                                          width: 16,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.45),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avgFill < 0.02
                      ? 'Add tasks this week — surf bars will grow'
                      : 'Ribbon = week average & totals · surf = relative effort per day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _shortDay(int index) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[index];
  }
}

class _DayData {
  final String label;
  final int date;
  final DateTime fullDate;
  final bool isToday;
  final bool isPast;
  final double completion;

  const _DayData({
    required this.label,
    required this.date,
    required this.fullDate,
    required this.isToday,
    required this.isPast,
    required this.completion,
  });
}

/// Replaces the old “tide” pool: one row of **numbers** (avg % + tasks done / scheduled).
class _WeekSummaryRibbon extends StatelessWidget {
  final double avgRatio;
  final int completed;
  final int total;
  final WeekOverWeekStats weekOverWeek;
  final ColorScheme colorScheme;

  const _WeekSummaryRibbon({
    required this.avgRatio,
    required this.completed,
    required this.total,
    required this.weekOverWeek,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (avgRatio * 100).round();
    final rounded = weekOverWeek.deltaPctPoints.round();
    final sameWeek =
        weekOverWeek.canCompareLastWeek && rounded.abs() < 1;
    final growthColor = theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.insights_rounded,
            size: 22,
            color: colorScheme.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week average',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pct% complete',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (!weekOverWeek.canCompareLastWeek)
                  Text(
                    'No tasks last week to compare',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  )
                else if (sameWeek)
                  Row(
                    children: [
                      Icon(
                        Icons.trending_flat_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Same as last week',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        rounded > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: rounded > 0
                            ? growthColor
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rounded > 0
                              ? '+$rounded% vs last week'
                              : '$rounded% vs last week',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: rounded > 0
                                ? growthColor
                                : colorScheme.error,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tasks',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$completed / $total done',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grows surf bars / fades dots in when data changes or on first layout.
class _AnimatedSurfChart extends StatefulWidget {
  final double width;
  final double height;
  final List<double> values;
  final List<int> taskTotalsPerDay;
  final List<int> completedPerDay;
  final int todayIndex;
  final int selectedIndex;
  final Color primary;
  final Color sand;
  final Color borderColor;
  final Color barFill;
  final Color barToday;
  final Color barSelected;

  const _AnimatedSurfChart({
    required this.width,
    required this.height,
    required this.values,
    required this.taskTotalsPerDay,
    required this.completedPerDay,
    required this.todayIndex,
    required this.selectedIndex,
    required this.primary,
    required this.sand,
    required this.borderColor,
    required this.barFill,
    required this.barToday,
    required this.barSelected,
  });

  @override
  State<_AnimatedSurfChart> createState() => _AnimatedSurfChartState();
}

class _AnimatedSurfChartState extends State<_AnimatedSurfChart>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  /// Drones + sweep lights above the “city” (continuous motion).
  late AnimationController _birdMotionController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..forward();
    _birdMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _AnimatedSurfChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.values, oldWidget.values) ||
        !listEquals(widget.taskTotalsPerDay, oldWidget.taskTotalsPerDay) ||
        !listEquals(widget.completedPerDay, oldWidget.completedPerDay)) {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _birdMotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _birdMotionController,
      ]),
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entranceController.value);
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _SurfPainter(
              values: widget.values,
              taskTotalsPerDay: widget.taskTotalsPerDay,
              completedPerDay: widget.completedPerDay,
              todayIndex: widget.todayIndex,
              selectedIndex: widget.selectedIndex,
              primary: widget.primary,
              sand: widget.sand,
              borderColor: widget.borderColor,
              barFill: widget.barFill,
              barToday: widget.barToday,
              barSelected: widget.barSelected,
              heightFactor: t,
              birdTime: _birdMotionController.value,
            ),
          ),
        );
      },
    );
  }
}

/// Original **surf** wave shape + **building** facades; **surveillance drones** in the sky.
class _SurfPainter extends CustomPainter {
  final List<double> values;
  final List<int> taskTotalsPerDay;
  final List<int> completedPerDay;
  final int todayIndex;
  final int selectedIndex;
  final Color primary;
  final Color sand;
  final Color borderColor;
  final Color barFill;
  final Color barToday;
  final Color barSelected;
  final double heightFactor;
  final double birdTime;

  _SurfPainter({
    required this.values,
    required this.taskTotalsPerDay,
    required this.completedPerDay,
    required this.todayIndex,
    required this.selectedIndex,
    required this.primary,
    required this.sand,
    required this.borderColor,
    required this.barFill,
    required this.barToday,
    required this.barSelected,
    this.heightFactor = 1.0,
    this.birdTime = 0.0,
  });

  static const _minBarPx = 14.0;
  /// When at least one task is done that day, keep a readable “building” silhouette
  /// (not a hairline), even if that day’s completion count is low vs the rest of the week.
  static const _minBuildingWhenCompletePx = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(rr, Paint()..color = sand);

    const pad = 12.0;
    final inner = Rect.fromLTWH(
      pad,
      pad,
      size.width - 2 * pad,
      size.height - 2 * pad,
    );

    _paintSurf(canvas, inner);

    canvas.drawRRect(
      rr,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintSurf(Canvas canvas, Rect surfRect) {
    if (values.length != 7) return;

    final n = 7;
    final gap = 4.0;
    final cellW = (surfRect.width - gap * (n - 1)) / n;

    for (var i = 0; i < n; i++) {
      final left = surfRect.left + i * (cellW + gap);
      final cell = Rect.fromLTWH(left, surfRect.top, cellW, surfRect.height);
      final v = values[i].clamp(0.0, 1.0);
      final isSelected = i == selectedIndex;
      final isToday = i == todayIndex;
      final tasksOnDay =
          i < taskTotalsPerDay.length ? taskTotalsPerDay[i] : 0;
      if (tasksOnDay == 0) {
        final dotY = cell.bottom - 3;
        final r = (isSelected ? 3.5 : 2.0) * heightFactor;
        final a = (isSelected ? 0.45 : 0.2) * heightFactor;
        if (a > 0.01) {
          canvas.drawCircle(
            Offset(cell.center.dx, dotY),
            r.clamp(0.0, 8.0),
            Paint()..color = primary.withValues(alpha: a.clamp(0.0, 1.0)),
          );
        }
        continue;
      }

      if (heightFactor < 0.002) continue;

      var fillH = cell.height * v * 0.94 * heightFactor;
      final minScaled = _minBarPx * heightFactor;
      final doneOnDay =
          i < completedPerDay.length ? completedPerDay[i] : 0;
      if (tasksOnDay > 0 && doneOnDay == 0) {
        fillH = minScaled;
      } else if (fillH > 0 && fillH < minScaled) {
        fillH = minScaled;
      }
      if (doneOnDay >= 1) {
        fillH = math.max(
          fillH,
          _minBuildingWhenCompletePx * heightFactor,
        );
      }
      final bottom = cell.bottom - 2;
      final topBase = bottom - fillH;
      final Color fillCol =
          isSelected ? barSelected : (isToday ? barToday : barFill);

      final path = Path()..moveTo(left, bottom);
      const steps = 14;
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final x = left + t * cellW;
        final curl = math.sin(t * math.pi) * 2.15;
        final y = topBase + curl;
        if (s == 0) {
          path.lineTo(left, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.lineTo(left + cellW, bottom);
      path.close();

      _paintBuildingSurfColumn(
        canvas,
        cell,
        path,
        fillCol,
        isSelected,
        isToday,
      );
      _paintRoofSentinels(canvas, path, cell, i);
    }

    _paintBirds(canvas, surfRect);

    final tp = TextPainter(
      text: TextSpan(
        text: 'Surf',
        style: TextStyle(
          color: primary.withValues(alpha: 0.45),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(surfRect.left + 4, surfRect.top + 2));
  }

  void _paintBuildingSurfColumn(
    Canvas canvas,
    Rect cell,
    Path surfPath,
    Color accent,
    bool isSelected,
    bool isToday,
  ) {
    final mix = isSelected ? 0.58 : (isToday ? 0.48 : 0.34);
    final facade = Color.lerp(sand, accent, mix)!;
    final roof = Color.lerp(
      facade,
      primary,
      isSelected ? 0.22 : 0.14,
    )!;
    final sill = Color.lerp(primary, sand, 0.55)!.withValues(alpha: 0.9);

    canvas.save();
    canvas.clipPath(surfPath);

    canvas.drawPath(
      surfPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            roof,
            facade,
            Color.lerp(facade, sand, 0.12)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(cell),
    );

    final bounds = surfPath.getBounds();
    final winW = 3.2;
    final winH = 6.0;
    final gapX = 4.0;
    final gapY = 7.0;
    final winFill = Color.lerp(primary, sand, 0.72)!
        .withValues(alpha: 0.38);
    final winGlow = primary.withValues(alpha: 0.55);
    var y = bounds.top + 5;
    while (y + winH < bounds.bottom - 6) {
      var x = bounds.left + 4;
      while (x + winW < bounds.right - 4) {
        final win = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, winW, winH),
          const Radius.circular(0.8),
        );
        canvas.drawRRect(
          win,
          Paint()..color = winFill,
        );
        canvas.drawRRect(
          win,
          Paint()
            ..color = winGlow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.65,
        );
        x += winW + gapX;
      }
      y += winH + gapY;
    }

    // Subtle vertical edge lines for masonry / corner depth.
    final edge = Paint()
      ..color = sill.withValues(alpha: 0.35)
      ..strokeWidth = 0.85;
    canvas.drawLine(
      Offset(bounds.left + 1.2, bounds.top + 2),
      Offset(bounds.left + 1.2, bounds.bottom - 2),
      edge,
    );
    canvas.drawLine(
      Offset(bounds.right - 1.2, bounds.top + 2),
      Offset(bounds.right - 1.2, bounds.bottom - 2),
      edge,
    );
    canvas.restore();

    final strokeA = isSelected ? 0.62 : (isToday ? 0.48 : 0.3);
    canvas.drawPath(
      surfPath,
      Paint()
        ..color = primary.withValues(alpha: strokeA.clamp(0.15, 0.85))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.65 : (isToday ? 1.2 : 0.8),
    );
  }

  /// Stylized rooftop figures (game-style silhouettes) on building crests.
  void _paintRoofSentinels(
    Canvas canvas,
    Path buildingPath,
    Rect cell,
    int dayIndex,
  ) {
    if (heightFactor < 0.08) return;
    final bounds = buildingPath.getBounds();
    if (bounds.height < 18 || bounds.width < 10) return;

    final scale = (cell.width * 0.052 * heightFactor).clamp(2.8, 5.2);
    final footY = bounds.top + scale * 0.42;
    final n = bounds.width > 28 ? 2 : 1;
    final step = bounds.width / (n + 1);

    for (var g = 0; g < n; g++) {
      final cx = bounds.left + step * (g + 1);
      final faceRight = (dayIndex + g).isEven;
      final aimSway =
          0.2 * math.sin(birdTime * math.pi * 2 * 0.55 + dayIndex * 0.7 + g * 1.1);
      _drawRoofSentinel(
        canvas,
        Offset(cx, footY),
        faceRight: faceRight,
        scale: scale,
        aimSway: aimSway,
      );
    }
  }

  /// Dark silhouettes on light surf; light silhouettes on dark theme buildings.
  Color _sentinelSilhouetteBase() {
    final a = 0.9 * heightFactor.clamp(0.0, 1.0);
    final darkCanvas = sand.computeLuminance() < 0.45;
    if (darkCanvas) {
      return Color.lerp(const Color(0xFFE8EEF5), primary, 0.14)!
          .withValues(alpha: a);
    }
    return Color.lerp(const Color(0xFF121212), primary, 0.1)!
        .withValues(alpha: a);
  }

  void _drawRoofSentinel(
    Canvas canvas,
    Offset feet, {
    required bool faceRight,
    required double scale,
    required double aimSway,
  }) {
    final sil = _sentinelSilhouetteBase();
    final darkCanvas = sand.computeLuminance() < 0.45;
    final stroke = Paint()
      ..color = sil
      ..strokeWidth = math.max(1.0, scale * 0.2)
      ..strokeCap = StrokeCap.round;
    final gunStroke = Paint()
      ..color = sil
      ..strokeWidth = math.max(1.15, scale * 0.26)
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.scale(faceRight ? 1.0 : -1.0, 1.0);

    // Legs
    canvas.drawLine(
      Offset(-scale * 0.22, 0),
      Offset(-scale * 0.32, scale * 0.42),
      stroke,
    );
    canvas.drawLine(
      Offset(scale * 0.22, 0),
      Offset(scale * 0.32, scale * 0.42),
      stroke,
    );
    // Torso
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, -scale * 1.05),
      stroke,
    );
    // Head
    canvas.drawCircle(
      Offset(0, -scale * 1.22),
      scale * 0.26,
      Paint()..color = sil,
    );
    // Rear arm
    canvas.drawLine(
      Offset(0, -scale * 0.82),
      Offset(-scale * 0.38, -scale * 0.62),
      stroke,
    );
    // Rifle: stock + barrel (horizontal silhouette)
    final aimY = -scale * 0.88 + aimSway * scale;
    canvas.drawLine(
      Offset(-scale * 0.12, aimY + scale * 0.06),
      Offset(scale * 0.05, aimY),
      gunStroke,
    );
    canvas.drawLine(
      Offset(scale * 0.05, aimY),
      Offset(scale * 0.85, aimY + aimSway * scale * 0.35),
      gunStroke,
    );
    // Muzzle hint
    canvas.drawCircle(
      Offset(scale * 0.88, aimY + aimSway * scale * 0.35),
      scale * 0.12,
      Paint()
        ..color = sil.withValues(alpha: darkCanvas ? 0.88 : 0.75)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  void _paintBirds(Canvas canvas, Rect surfRect) {
    // One drone per weekday that has at least one completed task (matches "week" activity).
    var n = 0;
    for (var i = 0; i < 7 && i < completedPerDay.length; i++) {
      if (completedPerDay[i] >= 1) n++;
    }
    if (n == 0) return;

    final t = birdTime * math.pi * 2;

    for (var bi = 0; bi < n; bi++) {
      final seed = bi * 1.47;
      final speed = 0.24 + (bi % 4) * 0.06;
      final leftToRight = bi.isEven;
      final raw = birdTime * speed + seed * 0.09;
      final nx = leftToRight ? (raw % 1.0) : (1.0 - (raw % 1.0));
      final facingRight = leftToRight;

      final ny = (0.06 +
              0.22 * (0.5 + 0.5 * math.sin(t * 0.5 + seed)) +
              0.06 * math.sin(t * 1.1 + seed * 1.2) +
              (bi % 3) * 0.02)
          .clamp(0.03, 0.32);

      final cx = surfRect.left + surfRect.width * nx;
      final cy = surfRect.top + surfRect.height * ny;
      final sc = 9.2 + (bi % 3) * 1.15;
      final sweepPhase = t * 0.85 + seed * 1.9;
      _drawSurveillanceDrone(
        canvas,
        Offset(cx, cy),
        sc,
        facingRight: facingRight,
        sweepPhase: sweepPhase,
      );
    }
  }

  /// Small quadcopter + downward **searchlight** beam (slow scan).
  void _drawSurveillanceDrone(
    Canvas canvas,
    Offset center,
    double size, {
    required bool facingRight,
    required double sweepPhase,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(facingRight ? 1.0 : -1.0, 1.0);

    final s = size;
    final hull = Color.lerp(const Color(0xFF2C2C2C), primary, 0.12)!;
    final beamTint = Color.lerp(primary, sand, 0.12)!;

    // 1) Searchlight — wide ambient + main wash + bright core (large ground coverage).
    canvas.save();
    final scan = 0.28 * math.sin(sweepPhase);
    canvas.rotate(scan);
    final beamTop = s * 0.02;

    final outerPath = Path()
      ..moveTo(-s * 0.2, beamTop)
      ..lineTo(s * 0.2, beamTop)
      ..lineTo(s * 1.58, s * 2.42)
      ..lineTo(-s * 1.58, s * 2.42)
      ..close();
    final outerRect = Rect.fromLTWH(-s * 1.65, beamTop, s * 3.3, s * 2.45);
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            beamTint.withValues(alpha: 0.34),
            beamTint.withValues(alpha: 0.16),
            beamTint.withValues(alpha: 0.06),
            beamTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.32, 0.62, 1.0],
        ).createShader(outerRect),
    );

    final beamPath = Path()
      ..moveTo(-s * 0.13, beamTop)
      ..lineTo(s * 0.13, beamTop)
      ..lineTo(s * 1.12, s * 2.05)
      ..lineTo(-s * 1.12, s * 2.05)
      ..close();
    final beamBounds = Rect.fromLTWH(-s * 1.18, beamTop, s * 2.36, s * 2.08);
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            beamTint.withValues(alpha: 0.62),
            beamTint.withValues(alpha: 0.36),
            beamTint.withValues(alpha: 0.1),
            beamTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.34, 0.68, 1.0],
        ).createShader(beamBounds),
    );

    final corePath = Path()
      ..moveTo(-s * 0.055, beamTop)
      ..lineTo(s * 0.055, beamTop)
      ..lineTo(s * 0.48, s * 1.78)
      ..lineTo(-s * 0.48, s * 1.78)
      ..close();
    canvas.drawPath(
      corePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.58),
            primary.withValues(alpha: 0.22),
            primary.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(-s * 0.52, beamTop, s * 1.04, s * 1.8)),
    );
    canvas.restore();

    // 2) Hub
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -s * 0.06),
          width: s * 0.46,
          height: s * 0.17,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = hull.withValues(alpha: 0.95),
    );

    // 3) Arms + rotors (quad layout)
    final arm = s * 0.38;
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final ox = math.cos(a) * arm;
      final oy = math.sin(a) * arm * 0.52 - s * 0.06;
      canvas.drawLine(
        Offset(0, -s * 0.06),
        Offset(ox * 0.92, oy * 0.92),
        Paint()
          ..color = hull.withValues(alpha: 0.75)
          ..strokeWidth = math.max(1.2, s * 0.095)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(ox, oy),
        s * 0.092,
        Paint()..color = hull.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(ox, oy),
        s * 0.092,
        Paint()
          ..color = primary.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // 4) Gimbal / camera LED under hull
    final ledY = s * 0.05;
    canvas.drawCircle(
      Offset(0, ledY),
      s * 0.09,
      Paint()..color = primary.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      Offset(0, ledY),
      s * 0.052,
      Paint()..color = primary.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      Offset(0, ledY),
      s * 0.052,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SurfPainter oldDelegate) =>
      values != oldDelegate.values ||
      taskTotalsPerDay != oldDelegate.taskTotalsPerDay ||
      completedPerDay != oldDelegate.completedPerDay ||
      todayIndex != oldDelegate.todayIndex ||
      selectedIndex != oldDelegate.selectedIndex ||
      primary != oldDelegate.primary ||
      sand != oldDelegate.sand ||
      heightFactor != oldDelegate.heightFactor ||
      birdTime != oldDelegate.birdTime;
}
