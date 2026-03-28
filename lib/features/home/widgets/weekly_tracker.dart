import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/settings/metric_formula_mode.dart';
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

/// Week **summary ribbon** + **surf** chart (wave bars + cityscape). Tap a weekday to select
/// that day (see [onDaySelected]).
class WeeklyTracker extends StatelessWidget {
  /// Monday 00:00 of the week shown.
  final DateTime weekMonday;

  final Map<String, double> completions;
  final WeeklySurfData surfData;
  final WeekOverWeekStats weekOverWeek;
  final int streak;

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  final VoidCallback? onWeekBefore;
  final VoidCallback? onWeekAfter;
  final bool canGoWeekBefore;
  final bool canGoWeekAfter;

  /// When [onMetricsToggle] is non-null, ribbon + chart + footer can collapse to save space.
  final bool metricsExpanded;
  final ValueChanged<bool>? onMetricsToggle;

  /// Which formula drives [surfData.weekMetricRatio] (ribbon headline %).
  final MetricFormulaMode metricFormula;

  const WeeklyTracker({
    super.key,
    required this.weekMonday,
    required this.completions,
    required this.surfData,
    required this.weekOverWeek,
    required this.streak,
    required this.selectedDate,
    required this.today,
    required this.onDaySelected,
    required this.metricFormula,
    this.onWeekBefore,
    this.onWeekAfter,
    this.canGoWeekBefore = false,
    this.canGoWeekAfter = false,
    this.metricsExpanded = true,
    this.onMetricsToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monday = DateUtils.dateOnly(weekMonday);

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

    var todayColumnIndex = -1;
    final todayOnly = DateUtils.dateOnly(today);
    for (var i = 0; i < 7; i++) {
      if (DateUtils.isSameDay(monday.add(Duration(days: i)), todayOnly)) {
        todayColumnIndex = i;
        break;
      }
    }

    final sel = DateUtils.dateOnly(selectedDate);
    var selectedIndex = -1;
    for (var i = 0; i < 7; i++) {
      if (DateUtils.isSameDay(days[i].fullDate, sel)) {
        selectedIndex = i;
        break;
      }
    }
    // If the selected calendar date isn’t in this Mon–Sun strip (shouldn’t
    // happen when Home passes a normalized date), align to the same weekday
    // column instead of defaulting to Monday (index 0).
    if (selectedIndex < 0) {
      selectedIndex = (sel.weekday - 1).clamp(0, 6);
    }

    final values = surfData.heights.length == 7
        ? surfData.heights.map((v) => v.clamp(0.0, 1.0)).toList()
        : days.map((d) => d.completion.clamp(0.0, 1.0)).toList();
    final taskTotals = surfData.taskTotalsPerDay.length == 7
        ? surfData.taskTotalsPerDay
        : List<int>.filled(7, 0);
    final completedCountPerDay = surfData.completedCountPerDay.length == 7
        ? surfData.completedCountPerDay
        : List<int>.filled(7, 0);
    final progressSumPerDay = surfData.progressSumPerDay.length == 7
        ? surfData.progressSumPerDay
        : List<int>.filled(7, 0);
    final ribbonProgressRatio = surfData.weekMetricRatio;
    final colorScheme = theme.colorScheme;
    final currentWeekMonday = DateUtils.dateOnly(
      today.subtract(Duration(days: today.weekday - 1)),
    );
    final isCurrentCalendarWeek =
        DateUtils.isSameDay(monday, currentWeekMonday);
    final weekSunday = monday.add(const Duration(days: 6));

    final hasWeekNav = onWeekBefore != null || onWeekAfter != null;

    final titleText = isCurrentCalendarWeek
        ? 'This week'
        : '${monday.month}/${monday.day}–${weekSunday.month}/${weekSunday.day}';

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final showMetrics = onMetricsToggle == null ? true : metricsExpanded;

    final Widget? metricsToggle = onMetricsToggle == null
        ? null
        : Semantics(
            button: true,
            label: 'Week stats',
            hint: metricsExpanded
                ? 'Hides the weekly progress summary and surf chart'
                : 'Shows the weekly progress summary and surf chart',
            child: Tooltip(
              message: metricsExpanded
                  ? 'Hide weekly progress & surf chart'
                  : 'Show weekly progress & surf chart',
              child: FilterChip(
                avatar: Icon(
                  Icons.insights_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  'Week stats',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: metricsExpanded,
                onSelected: (on) => onMetricsToggle!(on),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              ),
            ),
          );

    final streakAndCalendar = Row(
      children: [
        _StreakBadge(
          streak: streak,
          colorScheme: colorScheme,
          theme: theme,
        ),
        const Spacer(),
        if (metricsToggle != null) metricsToggle,
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasWeekNav) ...[
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: onWeekBefore != null && canGoWeekBefore
                    ? IconButton(
                        onPressed: onWeekBefore,
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: colorScheme.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        tooltip: 'Previous week',
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  titleText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: onWeekAfter != null && canGoWeekAfter
                    ? IconButton(
                        onPressed: onWeekAfter,
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        tooltip: 'Next week',
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          streakAndCalendar,
        ] else
          Row(
            children: [
              Text(
                titleText,
                style: titleStyle,
              ),
              const SizedBox(width: 10),
              _StreakBadge(
                streak: streak,
                colorScheme: colorScheme,
                theme: theme,
              ),
              const Spacer(),
              if (metricsToggle != null) metricsToggle,
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
        if (!showMetrics && onMetricsToggle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Tap Week stats above to see your weekly progress and chart.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            const surfHeight = 112.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showMetrics) ...[
                  _WeekSummaryRibbon(
                    avgRatio: ribbonProgressRatio.clamp(0.0, 1.0),
                    progressSum: surfData.weekProgressSum,
                    progressCap: surfData.weekProgressCap,
                    weekOverWeek: weekOverWeek,
                    colorScheme: colorScheme,
                    metricFormula: metricFormula,
                  ),
                  const SizedBox(height: 10),
                _AnimatedSurfChart(
                  width: w,
                  height: surfHeight,
                  values: values,
                  taskTotalsPerDay: taskTotals,
                  completedCountPerDay: completedCountPerDay,
                  progressSumPerDay: progressSumPerDay,
                  weekMonday: monday,
                  today: DateUtils.dateOnly(today),
                  todayIndex: todayColumnIndex,
                  selectedIndex: selectedIndex,
                  primary: colorScheme.primary,
                  sand: colorScheme.surfaceContainerHigh,
                  borderColor: colorScheme.outlineVariant,
                  barFill: colorScheme.primary.withValues(alpha: 1),
                  barToday: colorScheme.primary.withValues(alpha: 1),
                  barSelected: colorScheme.primary.withValues(alpha: 1),
                ),
                ],
                Padding(
                  padding: EdgeInsets.only(top: showMetrics ? 8 : 0),
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
                if (showMetrics) ...[
                  const SizedBox(height: 8),
                  Text(
                    ribbonProgressRatio < 0.02
                        ? 'Add tasks this week — surf bars will grow'
                        : 'Ribbon = weekly progress · surf = load vs week (done = solid, broken = unfinished)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
  final int progressSum;
  final int progressCap;
  final WeekOverWeekStats weekOverWeek;
  final ColorScheme colorScheme;
  final MetricFormulaMode metricFormula;

  const _WeekSummaryRibbon({
    required this.avgRatio,
    required this.progressSum,
    required this.progressCap,
    required this.weekOverWeek,
    required this.colorScheme,
    required this.metricFormula,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctOneDecimal = (avgRatio * 100).toStringAsFixed(1);
    final rounded = weekOverWeek.deltaPctPoints.round();
    final sameWeek =
        weekOverWeek.canShowWeekOverWeekComparison && rounded.abs() < 1;
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
                  'Week progress',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pctOneDecimal% complete',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metricFormula.ribbonShort,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                if (!weekOverWeek.canShowWeekOverWeekComparison)
                  Text(
                    weekOverWeek.thisWeekTaskTotal == 0
                        ? 'Nothing scheduled this week'
                        : 'No tasks last week to compare',
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
                'Progress',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                progressCap == 0
                    ? '—'
                    : '$progressSum / $progressCap',
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

class _AnimatedSurfChart extends StatefulWidget {
  final double width;
  final double height;
  final List<double> values;
  final List<int> taskTotalsPerDay;
  final List<int> completedCountPerDay;
  /// Per-day sum of task progress (0–100 each); used to treat “100%” like all done.
  final List<int> progressSumPerDay;
  /// Monday 00:00 of the visible week (date-only).
  final DateTime weekMonday;
  /// Calendar “today” for past vs current day (date-only).
  final DateTime today;
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
    required this.completedCountPerDay,
    required this.progressSumPerDay,
    required this.weekMonday,
    required this.today,
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
  /// Roof workers: beam lift + sway (faster loop than drones so it reads as “building”).
  late AnimationController _constructionController;
  /// Rooftop sentinels: patrol back-and-forth along the building crest.
  late AnimationController _sentinelPatrolController;

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
    _constructionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _sentinelPatrolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _AnimatedSurfChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.values, oldWidget.values) ||
        !listEquals(widget.taskTotalsPerDay, oldWidget.taskTotalsPerDay) ||
        !listEquals(
            widget.completedCountPerDay, oldWidget.completedCountPerDay) ||
        !listEquals(
            widget.progressSumPerDay, oldWidget.progressSumPerDay) ||
        widget.weekMonday != oldWidget.weekMonday ||
        widget.today != oldWidget.today) {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _birdMotionController.dispose();
    _constructionController.dispose();
    _sentinelPatrolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _birdMotionController,
        _constructionController,
        _sentinelPatrolController,
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
              completedCountPerDay: widget.completedCountPerDay,
              progressSumPerDay: widget.progressSumPerDay,
              weekMonday: widget.weekMonday,
              today: widget.today,
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
              constructPhase: _constructionController.value,
              patrolPhase: _sentinelPatrolController.value,
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
  final List<int> completedCountPerDay;
  final List<int> progressSumPerDay;
  final DateTime weekMonday;
  final DateTime today;
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
  /// \[0,1) — repeating construction cycle (beam lift, sway); independent of [birdTime].
  final double constructPhase;
  /// \[0,1) — rooftop sentinel patrol along crest (one full out-and-back per loop).
  final double patrolPhase;

  _SurfPainter({
    required this.values,
    required this.taskTotalsPerDay,
    required this.completedCountPerDay,
    required this.progressSumPerDay,
    required this.weekMonday,
    required this.today,
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
    required this.constructPhase,
    required this.patrolPhase,
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

    _paintGroundSkyline(canvas, surfRect);

    final n = 7;
    final gap = 4.0;
    final cellW = (surfRect.width - gap * (n - 1)) / n;

    for (var i = 0; i < n; i++) {
      final left = surfRect.left + i * (cellW + gap);
      final cell = Rect.fromLTWH(left, surfRect.top, cellW, surfRect.height);
      final v = values[i].clamp(0.0, 1.0);
      final isSelected = i == selectedIndex;
      final isToday = todayIndex >= 0 && i == todayIndex;
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
      final completedOnDay =
          i < completedCountPerDay.length ? completedCountPerDay[i] : 0;
      final sumDay =
          i < progressSumPerDay.length ? progressSumPerDay[i] : 0;
      final allTasksDone = tasksOnDay > 0 &&
          (completedOnDay >= tasksOnDay || sumDay >= tasksOnDay * 100);
      final buildingInProgress = tasksOnDay > 0 && !allTasksDone;
      final isTodayColumn = todayIndex >= 0 && i == todayIndex;
      final incompleteOnDay = tasksOnDay - completedOnDay;
      final weekStart = DateUtils.dateOnly(weekMonday);
      final todayOnly = DateUtils.dateOnly(today);
      final columnDate = weekStart.add(Duration(days: i));
      // Damage (x vs y) only for **past** calendar days — today/future still “in progress”.
      final isPastCalendarDay = columnDate.isBefore(todayOnly);
      var devastated = false;
      var crackIntensity = 0.0;
      if (isPastCalendarDay && tasksOnDay > 0) {
        devastated = (completedOnDay == 0 && tasksOnDay > 0) ||
            (completedOnDay > 0 && completedOnDay <= incompleteOnDay);
        crackIntensity = devastated
            ? 0.0
            : (completedOnDay > 0 && completedOnDay > incompleteOnDay)
                ? (incompleteOnDay / tasksOnDay).clamp(0.0, 1.0)
                : 0.0;
      }

      if (fillH > 0 && fillH < minScaled) {
        fillH = minScaled;
      }
      if ((completedOnDay >= 1 || sumDay >= tasksOnDay * 100) && !devastated) {
        fillH = math.max(
          fillH,
          _minBuildingWhenCompletePx * heightFactor,
        );
      }

      // No completed tasks yet → no building stack (today/future use completion-only heights).
      if (fillH <= 0) {
        if (!devastated && isTodayColumn && buildingInProgress) {
          _paintRoofConstructors(canvas, Path(), cell, i);
        }
        continue;
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
        devastated: devastated,
        crackIntensity: crackIntensity,
        dayIndex: i,
      );
      if (!devastated) {
        if (isTodayColumn && buildingInProgress) {
          _paintRoofConstructors(canvas, path, cell, i);
        } else if (allTasksDone && tasksOnDay > 0) {
          // Soldiers only when every task for that day is done (past or future included).
          _paintRoofSentinels(canvas, path, cell, i);
        }
      }
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
    canvas.save();
    try {
      tp.paint(canvas, Offset(surfRect.left + 4, surfRect.top + 2));
    } finally {
      canvas.restore();
    }
  }

  /// Distant buildings + horizon along the bottom of the surf (drawn behind columns).
  void _paintGroundSkyline(Canvas canvas, Rect surfRect) {
    if (surfRect.height < 8 || surfRect.width < 8) return;
    final dark = sand.computeLuminance() < 0.45;
    final bandH = math.min(14.0, surfRect.height * 0.22).clamp(5.0, 16.0);
    final baseY = surfRect.bottom - 1;
    final lineCol = Color.lerp(sand, primary, dark ? 0.24 : 0.15)!
        .withValues(alpha: 1);
    final horizon = Paint()
      ..color = lineCol
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(surfRect.left, baseY),
      Offset(surfRect.right, baseY),
      horizon,
    );

    final sil = Color.lerp(sand, primary, dark ? 0.38 : 0.22)!
        .withValues(alpha: 1);
    var x = surfRect.left;
    while (x < surfRect.right - 1) {
      final t = x * 0.173 + surfRect.width * 0.07;
      final h = 2.5 + (math.sin(t) * 0.5 + 0.5) * (bandH - 3);
      final w = 1.4 + (math.cos(t * 1.63) * 0.5 + 0.5) * 3.2;
      canvas.drawRect(
        Rect.fromLTWH(x, baseY - h, w, h),
        Paint()..color = sil,
      );
      x += w + 0.65 + (math.sin(x * 0.29 + 0.9) * 0.5 + 0.5) * 2.2;
    }

    final haze = Color.lerp(sand, primary, dark ? 0.12 : 0.08)!
        .withValues(alpha: 1);
    canvas.drawLine(
      Offset(surfRect.left, baseY - bandH * 0.55),
      Offset(surfRect.right, baseY - bandH * 0.55),
      Paint()
        ..color = haze
        ..strokeWidth = 0.65,
    );
  }

  void _paintBuildingSurfColumn(
    Canvas canvas,
    Rect cell,
    Path surfPath,
    Color accent,
    bool isSelected,
    bool isToday, {
    required bool devastated,
    required double crackIntensity,
    required int dayIndex,
  }) {
    final mix = isSelected ? 0.58 : (isToday ? 0.58 : 0.34);
    var facade = Color.lerp(sand, accent, mix)!;
    var roof = Color.lerp(
      facade,
      primary,
      isSelected ? 0.22 : (isToday ? 0.2 : 0.14),
    )!;
    if (devastated) {
      facade = Color.lerp(facade, const Color(0xFF6B6966), 0.38)!;
      roof = Color.lerp(roof, const Color(0xFF4A4845), 0.45)!;
    }
    final sill = Color.lerp(primary, sand, 0.55)!.withValues(alpha: 1);

    canvas.save();
    try {
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
            Color.lerp(facade, sand, isToday ? 0.07 : 0.12)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(cell),
    );

    final bounds = surfPath.getBounds();

    if (devastated) {
      _paintCollapseDustAndShadow(canvas, bounds);
    }

    final winW = 3.2;
    final winH = 6.0;
    final gapX = 4.0;
    final gapY = 7.0;
    final winFill = Color.lerp(primary, sand, 0.72)!
        .withValues(alpha: devastated ? 0.12 : 1);
    final winGlow = primary.withValues(
      alpha: devastated ? 0.12 : 1,
    );
    var y = bounds.top + 5;
    var row = 0;
    while (y + winH < bounds.bottom - 6) {
      var x = bounds.left + 4;
      var col = 0;
      while (x + winW < bounds.right - 4) {
        final skip = devastated &&
            ((dayIndex + row + col) % 7 == 0 || (dayIndex + row * 3 + col) % 11 == 0);
        if (!skip) {
          if (devastated) {
            _paintCollapsedWindowShard(canvas, x, y, winW, winH, row, col);
          } else {
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
          }
        }
        x += winW + gapX;
        col++;
      }
      y += winH + gapY;
      row++;
    }

    if (devastated) {
      _paintCollapsedRoofSlab(canvas, bounds, dayIndex);
      _paintRubblePile(canvas, bounds, dayIndex);
      _paintCollapseFractures(canvas, bounds, dayIndex);
    } else if (crackIntensity > 0.02) {
      _paintFacadeCracks(canvas, bounds, crackIntensity, dayIndex);
    }

    // Ground-level bands so the base reads like a street / foundation, not a flat fill.
    if (!devastated && bounds.height > 14) {
      final g = Color.lerp(facade, primary, 0.06)!
          .withValues(alpha: 1);
      final groundLine = Paint()
        ..color = g
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round;
      final yBase = bounds.bottom - 1.8;
      final yMid = bounds.bottom - 4.2;
      canvas.drawLine(
        Offset(bounds.left + 1.4, yBase),
        Offset(bounds.right - 1.4, yBase),
        groundLine,
      );
      if (bounds.width > 16) {
        canvas.drawLine(
          Offset(bounds.left + 1.4, yMid),
          Offset(bounds.right - 1.4, yMid),
          Paint()
            ..color = g
            ..strokeWidth = 0.45
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Subtle vertical edge lines for masonry / corner depth.
    final edge = Paint()
      ..color = sill.withValues(alpha: devastated ? 0.22 : 1)
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
    } finally {
      canvas.restore();
    }

    final strokeA = devastated
        ? (isSelected ? 0.62 : (isToday ? 0.58 : 0.22))
        : 1.0;
    final strokeCol = devastated
        ? Color.lerp(primary, const Color(0xFF3E2723), 0.55)!
        : primary;
    canvas.drawPath(
      surfPath,
      Paint()
        ..color = strokeCol.withValues(alpha: strokeA.clamp(0.15, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = devastated
            ? (isSelected ? 1.4 : 1.0)
            : (isSelected ? 1.65 : (isToday ? 1.2 : 0.8)),
    );
  }

  /// Settled dust + deep shadow at the base (collapse aftermath).
  void _paintCollapseDustAndShadow(Canvas canvas, Rect bounds) {
    final h = bounds.height;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF8C857E).withValues(alpha: 0.12),
            const Color(0xFF5C5650).withValues(alpha: 0.28),
          ],
          stops: const [0.35, 0.72, 1.0],
        ).createShader(bounds),
    );
    // clamp(lower, upper) requires lower <= upper; short buildings have h*0.5 < 12.
    final maxDust = h * 0.5;
    final minDust = math.min(12.0, maxDust);
    final dustH = (h * 0.38).clamp(minDust, maxDust);
    final dustRect = Rect.fromLTWH(
      bounds.left,
      bounds.bottom - dustH,
      bounds.width,
      dustH,
    );
    canvas.drawOval(
      dustRect.inflate(2),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.bottomCenter,
          radius: 1.05,
          colors: [
            const Color(0xFFB0AAA3).withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ).createShader(dustRect.inflate(4)),
    );
  }

  /// Hanging / blown-out openings instead of neat X’s.
  void _paintCollapsedWindowShard(
    Canvas canvas,
    double x,
    double y,
    double winW,
    double winH,
    int row,
    int col,
  ) {
    final voidPaint = const Color(0xFF1E1C1A);
    final jaggedTop = y + (col % 3) * 0.4;
    final path = Path()
      ..moveTo(x, jaggedTop + 1.2)
      ..lineTo(x + winW * 0.35, y)
      ..lineTo(x + winW * 0.72, y + 0.8)
      ..lineTo(x + winW, jaggedTop + 0.4)
      ..lineTo(x + winW, y + winH - 1)
      ..lineTo(x + winW * 0.55, y + winH)
      ..lineTo(x + winW * 0.2, y + winH - 0.6)
      ..lineTo(x, y + winH - 1.2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            voidPaint.withValues(alpha: 0.88),
            const Color(0xFF3D3835).withValues(alpha: 0.92),
          ],
        ).createShader(Rect.fromLTWH(x, y, winW, winH)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0A0908).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    if ((row + col) % 4 != 0) {
      canvas.drawLine(
        Offset(x + 1, y + winH * 0.55),
        Offset(x + winW - 0.5, y + winH * 0.4),
        Paint()
          ..color = const Color(0xFF6D6560).withValues(alpha: 0.35)
          ..strokeWidth = 0.45,
      );
    }
  }

  /// Missing / pancaked top slab — jagged silhouette (broken roofline).
  void _paintCollapsedRoofSlab(Canvas canvas, Rect bounds, int dayIndex) {
    final top = bounds.top;
    final w = bounds.width;
    final slab = Path()..moveTo(bounds.left, top + 2);
    const seg = 8;
    for (var s = 0; s <= seg; s++) {
      final t = s / seg;
      final x = bounds.left + t * w;
      final dip = math.sin(t * math.pi * 4 + dayIndex) * 2.8 +
          math.sin(dayIndex * 1.2 + s * 0.85) * 1.2;
      slab.lineTo(x, top + 2 + dip.abs().clamp(0.0, 7.0));
    }
    slab
      ..lineTo(bounds.right, top + 12)
      ..lineTo(bounds.right, top + 14)
      ..lineTo(bounds.left, top + 14)
      ..close();
    final roofRect = Rect.fromLTWH(bounds.left, top, w, 16);
    canvas.drawPath(
      slab,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A2826),
            const Color(0xFF4E4A47).withValues(alpha: 0.88),
          ],
        ).createShader(roofRect),
    );
    canvas.drawPath(
      slab,
      Paint()
        ..color = const Color(0xFF1A1816).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55,
    );
  }

  /// Concrete chunks and grit at the footprint.
  void _paintRubblePile(Canvas canvas, Rect bounds, int dayIndex) {
    final seed = dayIndex * 97;
    final baseY = bounds.bottom - 2;
    final n = 11 + (dayIndex % 4);
    for (var i = 0; i < n; i++) {
      final r = 1.1 + ((i * 17 + seed) % 5) * 0.35;
      final span = math.max(4.0, bounds.width - 2 * r - 4);
      final px = (bounds.left + r + 2 + (i * 19.0 + seed * 0.3) % span)
          .clamp(bounds.left + r, bounds.right - r);
      final py = baseY - r * 0.4 - (i % 3) * 0.8;
      final grey = Color.lerp(
        const Color(0xFF9A9590),
        const Color(0xFF6F6B67),
        ((i + seed) % 7) / 7.0,
      )!;
      canvas.drawOval(
        Rect.fromCircle(center: Offset(px, py), radius: r),
        Paint()..color = grey.withValues(alpha: 0.88),
      );
      canvas.drawOval(
        Rect.fromCircle(center: Offset(px - 0.2, py - 0.15), radius: r * 0.85),
        Paint()
          ..color = const Color(0xFF3A3836).withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4,
      );
    }
  }

  /// Vertical shear + staggered floor breaks (structural failure read).
  void _paintCollapseFractures(Canvas canvas, Rect bounds, int dayIndex) {
    final seed = dayIndex * 41 + 13;
    final cx = bounds.left + bounds.width * (0.32 + 0.06 * math.sin(seed * 0.2));

    final main = Path()..moveTo(cx, bounds.top + 5);
    var yy = bounds.top + 5.0;
    while (yy < bounds.bottom - 6) {
      yy += 3.6;
      final shear = math.sin(yy * 0.28 + seed) * 1.8 +
          math.sin(seed * 0.5 + yy * 0.08) * 1.2;
      main.lineTo(cx + shear, yy);
    }
    canvas.drawPath(
      main,
      Paint()
        ..color = const Color(0xFF0F0E0D).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..strokeCap = StrokeCap.round,
    );

    for (var f = 0; f < 3; f++) {
      final fy = bounds.top + bounds.height * (0.28 + f * 0.22);
      final wobble = math.sin(seed + f * 2.1) * 3.5;
      final fp = Path()
        ..moveTo(bounds.left + 4 + wobble, fy)
        ..quadraticBezierTo(
          bounds.left + bounds.width * 0.5,
          fy + 1.2,
          bounds.right - 4 + wobble * 0.5,
          fy - 0.8,
        );
      canvas.drawPath(
        fp,
        Paint()
          ..color = const Color(0xFF1C1A18).withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round,
      );
    }

    final rebarY = bounds.top + bounds.height * 0.44;
    canvas.drawLine(
      Offset(bounds.left + 5, rebarY),
      Offset(bounds.right - 5, rebarY + 0.6),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.35)
        ..strokeWidth = 0.35,
    );
  }

  /// **x > y** (ahead on tasks): structural stress — warm/primary hairlines + floor splits.
  /// Distinct from **collapse** (black rubble, dust, vertical shear) on devastated days.
  void _paintFacadeCracks(Canvas canvas, Rect bounds, double intensity, int dayIndex) {
    final seed = dayIndex * 29;
    final stress = Color.lerp(primary, const Color(0xFF6D4C41), 0.28)!;
    final nVert = (2 + intensity * 3).round().clamp(2, 6);
    final w = bounds.width - 8;
    for (var k = 0; k < nVert; k++) {
      final path = Path();
      final x0 = bounds.left + 4 + ((k + 0.5) / nVert) * w;
      path.moveTo(x0, bounds.top + 5);
      var yy = bounds.top + 5.0;
      while (yy < bounds.bottom - 4) {
        yy += 3.8;
        final j = math.sin(yy * 0.32 + seed + k * 1.4) * 1.05;
        path.lineTo(x0 + j, yy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = stress.withValues(alpha: 0.5 + 0.28 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.72 + intensity * 0.45
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var h = 0; h < 3; h++) {
      final fy = bounds.top + bounds.height * (0.2 + h * 0.27);
      final path = Path()..moveTo(bounds.left + 3, fy);
      for (var s = 0; s <= 14; s++) {
        final t = s / 14;
        final x = bounds.left + 3 + t * (bounds.width - 6);
        path.lineTo(x, fy + math.sin(t * math.pi * 5 + seed + h * 2.1) * 1.35);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = stress.withValues(alpha: 0.38 + 0.22 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55 + intensity * 0.3,
      );
    }
  }

  /// Roof ridge Y at [worldX]; must stay in sync with `_paintSurf` top edge (`curl = sin(t*pi)*2.15`).
  double _roofRidgeYAt(Rect columnBounds, double worldX) {
    final w = columnBounds.width;
    if (w <= 0) return columnBounds.top;
    final t = ((worldX - columnBounds.left) / w).clamp(0.0, 1.0);
    return columnBounds.top + math.sin(t * math.pi) * 2.15;
  }

  /// Pelvis origin Y so foot bottoms sit on the roof ridge (local feet at +0.42*scale).
  double _hipYOnRoofRidge(Rect columnBounds, double worldX, double scale) {
    return _roofRidgeYAt(columnBounds, worldX) - 0.42 * scale;
  }

  /// Stylized rooftop figures (game-style silhouettes) on building crests.
  void _paintRoofSentinels(
    Canvas canvas,
    Path buildingPath,
    Rect cell,
    int dayIndex,
  ) {
    // Match constructor visibility during the entrance animation (was 0.08 — soldiers
    // stayed hidden after the work-in-progress → all-done transition).
    if (heightFactor < 0.02) return;
    final bounds = buildingPath.getBounds();
    if (bounds.height < 18 || bounds.width < 10) return;

    final visFactor = math.max(heightFactor, 0.52);
    final scale = (cell.width * 0.086 * visFactor).clamp(4.8, 9.8);
    final n = bounds.width > 36 ? 2 : 1;
    final margin = scale * 0.48;
    final walkL = bounds.left + margin;
    final walkR = bounds.right - margin;
    final span = math.max(4.0, walkR - walkL);

    double tri01(double p) {
      final x = p - p.floorToDouble();
      return x < 0.5 ? 2 * x : 2 - 2 * x;
    }

    /// First half of [0,1) phase: position moves left→right along span.
    bool walkingRightHalf(double p) {
      final x = p - p.floorToDouble();
      return x < 0.5;
    }

    for (var g = 0; g < n; g++) {
      final tri = tri01(patrolPhase);
      // Left figure: walk right then back left. Right figure: opposite phase (starts toward −x).
      final frac = g == 0 ? tri : 1.0 - tri;
      final cx = walkL + frac * span;
      final faceRight = g == 0 ? walkingRightHalf(patrolPhase) : !walkingRightHalf(patrolPhase);
      // Slower leg cycle (~1.5 strides per patrol lap) + gentle bounce on weight shifts.
      final stridePhase =
          patrolPhase * 2 * math.pi * 1.5 + g * 0.85 + dayIndex * 0.12;
      final bob = 0.038 * scale * (0.5 + 0.5 * math.sin(stridePhase * 2));
      final footY = _hipYOnRoofRidge(bounds, cx, scale) + bob;
      final aimSway =
          0.2 * math.sin(birdTime * math.pi * 2 * 0.55 + dayIndex * 0.7 + g * 1.1);
      _drawRoofSentinel(
        canvas,
        Offset(cx, footY),
        faceRight: faceRight,
        scale: scale,
        aimSway: aimSway,
        stridePhase: stridePhase,
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
    required double stridePhase,
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

    final ls = math.sin(stridePhase);
    final rs = math.sin(stridePhase + math.pi);
    final hipSway = 0.018 * scale * math.sin(stridePhase);

    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.translate(hipSway, 0);
    canvas.scale(faceRight ? 1.0 : -1.0, 1.0);

    // Legs: hip → knee → foot (alternating stride; rs = −ls for natural opposition).
    void leg(
      double hipX,
      double hipY,
      double footX,
      double footY,
      double kneeInward,
    ) {
      final hip = Offset(hipX * scale, hipY * scale);
      final foot = Offset(footX * scale, footY * scale);
      final mx = (hip.dx + foot.dx) / 2 + kneeInward * scale;
      final my = (hip.dy + foot.dy) / 2 - 0.045 * scale;
      final knee = Offset(mx, my);
      canvas.drawLine(hip, knee, stroke);
      canvas.drawLine(knee, foot, stroke);
    }

    leg(-0.22, 0, -0.32 + 0.12 * ls, 0.42, 0.07);
    leg(0.22, 0, 0.32 + 0.12 * rs, 0.42, -0.07);
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

  /// Rooftop worker — same proportions as sentinels for clarity; hammer swing only.
  void _paintRoofConstructors(
    Canvas canvas,
    Path buildingPath,
    Rect cell,
    int dayIndex,
  ) {
    // Entrance animation scales bars; use a floor so figures stay visible (sentinels
    // still wait until ~8% to avoid clutter during the very first frames).
    if (heightFactor < 0.02) return;
    var bounds = buildingPath.getBounds();
    final useGroundFallback = bounds.height < 18 || bounds.width < 10;
    if (useGroundFallback) {
      bounds = Rect.fromLTWH(
        cell.left,
        cell.bottom - 4,
        math.max(10.0, cell.width),
        4,
      );
    }

    final visFactor = math.max(heightFactor, 0.52);
    final scale = (cell.width * 0.092 * visFactor).clamp(5.2, 11.0);
    // One worker per column at 20% along the padded roof span (feet stay inside ridge).
    final edgePad = (scale * 0.42).clamp(2.0, bounds.width * 0.22);
    final walkW = math.max(4.0, bounds.width - 2 * edgePad);
    final cx = bounds.left + edgePad + walkW * 0.2;
    final footY = useGroundFallback
        ? cell.bottom - 8
        : _hipYOnRoofRidge(bounds, cx, scale);
    final faceRight = dayIndex.isEven;
    _drawRoofConstructor(
      canvas,
      Offset(cx, footY),
      faceRight: faceRight,
      scale: scale,
      constructPhase: constructPhase,
      workerIndex: 0,
      dayIndex: dayIndex,
    );
  }

  void _drawRoofConstructor(
    Canvas canvas,
    Offset feet, {
    required bool faceRight,
    required double scale,
    required double constructPhase,
    required int workerIndex,
    required int dayIndex,
  }) {
    final sil = _sentinelSilhouetteBase();
    final hatFill = Color.lerp(const Color(0xFFF59E0B), const Color(0xFFD97706), 0.35)!
        .withValues(alpha: sil.opacity);
    final stroke = Paint()
      ..color = sil
      ..strokeWidth = math.max(1.05, scale * 0.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final handleStroke = Paint()
      ..color = sil
      ..strokeWidth = math.max(0.95, scale * 0.17)
      ..strokeCap = StrokeCap.round;
    final headFill = Paint()..color = sil;
    final hammerHeadFill = Paint()..color = sil;

    final stagger = workerIndex * 0.18 + dayIndex * 0.06;
    var p = (constructPhase + stagger) % 1.0;
    if (p < 0) p += 1.0;

    // One loop: hammer overhead → strike toward ground → lift back overhead.
    // Handle points +y at θ=0 (down). Interpolate hammerAngle from negative (overhead) to
    // positive (strike down-forward). At the shoulder use rotate(hammerTwist*angle): the
    // −(twist*angle) form swept the long way behind the head; same angles with twist*angle
    // sweep in front of the torso (overhead → forward).
    const overheadAngle = -2.35;
    const strikeAngle = 0.42;
    final hammerTwist = workerIndex == 0 ? -1.0 : 1.0;
    const tHold = 0.07;
    const tStrikeEnd = 0.36;
    final double hammerAngle;
    if (p < tHold) {
      hammerAngle = overheadAngle;
    } else if (p < tStrikeEnd) {
      final u = (p - tHold) / (tStrikeEnd - tHold);
      final e = Curves.easeIn.transform(u);
      hammerAngle = overheadAngle + e * (strikeAngle - overheadAngle);
    } else {
      final u = (p - tStrikeEnd) / (1.0 - tStrikeEnd);
      final e = Curves.easeOut.transform(u);
      hammerAngle = strikeAngle + e * (overheadAngle - strikeAngle);
    }

    // Forward lean at the hips (Flutter +rotate is CW; for spine (0,−y) that pulls the
    // head backward — use negative rotation so the bend reads toward the strike).
    double leanPhase;
    if (p < tHold) {
      leanPhase = 0.2;
    } else if (p < tStrikeEnd) {
      final u = (p - tHold) / (tStrikeEnd - tHold);
      leanPhase = 0.2 + 0.8 * Curves.easeIn.transform(u);
    } else {
      final u = (p - tStrikeEnd) / (1.0 - tStrikeEnd);
      leanPhase = 0.2 + 0.8 * (1.0 - Curves.easeOut.transform(u));
    }

    final t = constructPhase * math.pi * 2;
    final sway = 0.03 * math.sin(t * 0.5 + stagger * 10);
    final bob = 0.06 * math.sin(t + stagger * 12);

    canvas.save();
    try {
      canvas.translate(feet.dx, feet.dy);
      canvas.translate(sway * scale, bob);
      canvas.scale(faceRight ? 1.0 : -1.0, 1.0);

      // Legs stay planted; upper body hinges forward at the hip so the bend reads clearly
      // (full-canvas rotate + mirror can leave the torso looking vertical at small scale).
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

      const hipHingeRad = 0.58;
      canvas.save();
      try {
        canvas.rotate(-hipHingeRad * leanPhase);

        canvas.drawLine(
          Offset(0, 0),
          Offset(0, -scale * 1.02),
          stroke,
        );
        // Free arm (same family as sentinel “rear arm”)
        canvas.drawLine(
          Offset(0, -scale * 0.82),
          Offset(-scale * 0.36, -scale * 0.62),
          stroke,
        );
        // Head — aligned with sentinel
        canvas.drawCircle(
          Offset(0, -scale * 1.18),
          scale * 0.24,
          headFill,
        );
        final hc = Offset(0, -scale * 1.18);
        final hatBrim = hc.dy - scale * 0.1;
        final hatTop = hc.dy - scale * 0.24;
        final hatPath = Path()
          ..moveTo(-scale * 0.24, hatBrim)
          ..quadraticBezierTo(0, hatTop, scale * 0.24, hatBrim)
          ..lineTo(scale * 0.2, hatBrim + scale * 0.045)
          ..lineTo(-scale * 0.2, hatBrim + scale * 0.045)
          ..close();
        canvas.drawPath(hatPath, Paint()..color = hatFill);
        canvas.drawPath(
          hatPath,
          Paint()
            ..color = sil
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, scale * 0.13),
        );

        final sh = Offset(scale * 0.28, -scale * 0.78);
        canvas.save();
        try {
          canvas.translate(sh.dx, sh.dy);
          canvas.rotate(hammerTwist * hammerAngle);
          final handleLen = scale * 0.38;
          canvas.drawLine(Offset.zero, Offset(0, handleLen), handleStroke);
          final hh = scale * 0.085;
          final hw = scale * 0.2;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, handleLen + hh * 0.35),
                width: hw,
                height: hh,
              ),
              Radius.circular(scale * 0.02),
            ),
            hammerHeadFill,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, handleLen + hh * 0.35),
                width: hw,
                height: hh,
              ),
              Radius.circular(scale * 0.02),
            ),
            Paint()
              ..color = sil
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(0.65, scale * 0.11),
          );
        } finally {
          canvas.restore();
        }
      } finally {
        canvas.restore();
      }

      // Sparks at end of down-stroke (impact), not during lift.
      if (p >= tHold && p <= tStrikeEnd) {
        final u = (p - tHold) / (tStrikeEnd - tHold);
        if (u > 0.82) {
          final hit = ((u - 0.82) / 0.18).clamp(0.0, 1.0);
          final sp = Paint()
            ..color = sil.withValues(alpha: 0.45 * hit)
            ..style = PaintingStyle.fill;
          // Impact toward column center (±x by worker); same +y toward ground.
          final towardCenter = workerIndex == 0 ? 1.0 : -1.0;
          final ax = towardCenter * scale * 0.34;
          final ay = scale * 0.48;
          canvas.drawCircle(Offset(ax, ay), scale * 0.045 * hit, sp);
          canvas.drawCircle(
            Offset(ax + towardCenter * scale * 0.08, ay - scale * 0.05),
            scale * 0.034 * hit,
            sp,
          );
        }
      }
    } finally {
      canvas.restore();
    }
  }

  void _paintBirds(Canvas canvas, Rect surfRect) {
    // One drone per day that has tasks and **all** of them finished (no partial days).
    var n = 0;
    for (var i = 0; i < 7 && i < completedCountPerDay.length; i++) {
      if (i >= taskTotalsPerDay.length) continue;
      final tasks = taskTotalsPerDay[i];
      final done = completedCountPerDay[i];
      if (tasks == 0) continue;
      final sum = i < progressSumPerDay.length ? progressSumPerDay[i] : 0;
      final allDone = done >= tasks || sum >= tasks * 100;
      if (!allDone) continue;
      n++;
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
    try {
      canvas.translate(center.dx, center.dy);
      canvas.scale(facingRight ? 1.0 : -1.0, 1.0);

      final s = size;
      final hull = Color.lerp(const Color(0xFF2C2C2C), primary, 0.12)!;
      final beamTint = Color.lerp(primary, sand, 0.12)!;

      // 1) Searchlight — wide ambient + main wash + bright core (large ground coverage).
      canvas.save();
      try {
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
      } finally {
        canvas.restore();
      }

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
    } finally {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SurfPainter oldDelegate) =>
      values != oldDelegate.values ||
      taskTotalsPerDay != oldDelegate.taskTotalsPerDay ||
      completedCountPerDay != oldDelegate.completedCountPerDay ||
      progressSumPerDay != oldDelegate.progressSumPerDay ||
      weekMonday != oldDelegate.weekMonday ||
      today != oldDelegate.today ||
      todayIndex != oldDelegate.todayIndex ||
      selectedIndex != oldDelegate.selectedIndex ||
      primary != oldDelegate.primary ||
      sand != oldDelegate.sand ||
      heightFactor != oldDelegate.heightFactor ||
      birdTime != oldDelegate.birdTime ||
      constructPhase != oldDelegate.constructPhase ||
      patrolPhase != oldDelegate.patrolPhase;
}
