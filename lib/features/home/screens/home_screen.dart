import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/core/settings/metric_formula_provider.dart';
import 'package:exam_ace/core/settings/home_streak_badge_provider.dart';
import 'package:exam_ace/core/settings/home_week_stats_provider.dart';
import 'package:exam_ace/features/home/providers/tasks_provider.dart';
import 'package:exam_ace/features/home/services/notification_sync.dart';
import 'package:exam_ace/features/home/widgets/daily_tasks.dart';
import 'package:exam_ace/features/home/widgets/weekly_tracker.dart';

/// Home: weekly tracker + tasks for the **selected day** (tap a weekday below chart).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _selectedDate;
  late DateTime _visibleWeekMonday;

  /// Ribbon + surf + footer; weekday strip stays visible.
  /// Default closed so the task list gets priority; use Week stats chip to expand.
  bool _metricsExpanded = false;

  /// 0 = Today tasks, 1 = Spill over (see [buildHomeDailyTaskSlivers]).
  int _todaySegment = 0;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedDate = DateUtils.dateOnly(DateTime(n.year, n.month, n.day));
    _visibleWeekMonday = mondayOfWeekContaining(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncNotificationSchedule(ref);
      ref.read(homeSelectedDateProvider.notifier).state = _selectedDate;
    });
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _shiftWeek(int delta) {
    final bounds = ref.read(homeWeekNavBoundsProvider);
    final next = DateUtils.dateOnly(
      _visibleWeekMonday.add(Duration(days: 7 * delta)),
    );
    final e = DateUtils.dateOnly(bounds.earliestMonday);
    final l = DateUtils.dateOnly(bounds.latestMonday);
    if (next.isBefore(e) || next.isAfter(l)) return;
    setState(() {
      _visibleWeekMonday = next;
      final m = DateUtils.dateOnly(next);
      _selectedDate = m.add(Duration(days: _selectedDate.weekday - 1));
    });
    ref.read(homeSelectedDateProvider.notifier).state = _selectedDate;
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateUtils.dateOnly(_today);
      _visibleWeekMonday = mondayOfWeekContaining(_today);
    });
    ref.read(homeSelectedDateProvider.notifier).state = _selectedDate;
  }

  double _weekTrackerHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    // WeeklyTracker's header (nav + streak + hint) is non-flex; needs enough
    // room below it for Expanded + scroll body or Column overflows (~18px).
    if (_metricsExpanded) {
      return (h * 0.46).clamp(404.0, 584.0) + 24.0;
    }
    return (h * 0.26).clamp(200.0, 320.0);
  }

  /// Calendar date aligned to [visibleWeekMonday] (same weekday as [_selectedDate]).
  static DateTime _selectedDateInWeek(DateTime visibleWeekMonday, DateTime selected) {
    final m = DateUtils.dateOnly(visibleWeekMonday);
    return m.add(Duration(days: selected.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationSettingsProvider, (_, __) {
      syncNotificationSchedule(ref);
    });
    ref.listen(todayCombinedTasksProvider, (_, __) {
      syncNotificationSchedule(ref);
    });
    ref.listen(homeWeekNavBoundsProvider, (prev, next) {
      final e = DateUtils.dateOnly(next.earliestMonday);
      final l = DateUtils.dateOnly(next.latestMonday);
      final vm = DateUtils.dateOnly(_visibleWeekMonday);
      if (vm.isBefore(e) || vm.isAfter(l)) {
        setState(() {
          _visibleWeekMonday = vm.isBefore(e) ? e : l;
          _selectedDate =
              _selectedDateInWeek(_visibleWeekMonday, _selectedDate);
        });
        ref.read(homeSelectedDateProvider.notifier).state = _selectedDate;
      }
    });

    final today = _today;
    final weekMonday = _visibleWeekMonday;
    final selectedInVisibleWeek =
        _selectedDateInWeek(weekMonday, _selectedDate);
    final selectedKey = dateKey(selectedInVisibleWeek);
    final tasks = ref.watch(homeTasksForDateProvider(selectedKey));
    final streak = ref.watch(currentStreakProvider);
    final navBounds = ref.watch(homeWeekNavBoundsProvider);
    final showStreakBadge = ref.watch(homeStreakBadgeProvider);
    final showWeekStats = ref.watch(homeWeekStatsProvider);

    final todayKey = dateKey(today);

    final vm = DateUtils.dateOnly(_visibleWeekMonday);
    final e = DateUtils.dateOnly(navBounds.earliestMonday);
    final l = DateUtils.dateOnly(navBounds.latestMonday);
    final canGoPrev = vm.isAfter(e);
    final canGoNext = vm.isBefore(l);

    final metricFormula = ref.watch(metricFormulaProvider);
    final completions =
        ref.watch(weeklyCompletionsForWeekProvider(weekMonday));
    final surfData = ref.watch(weeklySurfDataForWeekProvider(weekMonday));
    final weekOverWeek =
        ref.watch(weekOverWeekForWeekProvider(weekMonday));

    final topPad = MediaQuery.paddingOf(context).top + 16;

    final weekTracker = WeeklyTracker(
      key: ValueKey<String>(dateKey(DateUtils.dateOnly(weekMonday))),
      weekMonday: weekMonday,
      completions: completions,
      surfData: surfData,
      weekOverWeek: weekOverWeek,
      streak: streak,
      metricFormula: metricFormula,
      selectedDate: selectedInVisibleWeek,
      today: today,
      onDaySelected: (day) {
        setState(() {
          _selectedDate =
              DateUtils.dateOnly(DateTime(day.year, day.month, day.day));
        });
        ref.read(homeSelectedDateProvider.notifier).state = _selectedDate;
      },
      onWeekBefore: () => _shiftWeek(-1),
      onWeekAfter: () => _shiftWeek(1),
      canGoWeekBefore: canGoPrev,
      canGoWeekAfter: canGoNext,
      showWeekNavArrows: true,
      showSurfWorkers: true,
      showStreakBadge: showStreakBadge,
      showWeekStatsRow: showWeekStats,
      metricsExpanded: _metricsExpanded,
      onMetricsToggle: (expanded) {
        setState(() => _metricsExpanded = expanded);
      },
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _metricsExpanded
                ? SizedBox(
                    height: _weekTrackerHeight(context),
                    child: weekTracker,
                  )
                : weekTracker,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: _metricsExpanded ? 20 : 12),
        ),
        ...buildHomeDailyTaskSlivers(
          context: context,
          ref: ref,
          selectedDate: selectedInVisibleWeek,
          today: today,
          tasks: DateUtils.isSameDay(selectedInVisibleWeek, today)
              ? ref.watch(homeTasksForDateProvider(todayKey))
              : tasks,
          carriedTasks: DateUtils.isSameDay(selectedInVisibleWeek, today)
              ? ref.watch(carriedTasksForTodayProvider)
              : const [],
          carrySpillDayCounts:
              ref.watch(carrySpillDayCountsProvider).valueOrNull ??
                  const <String, int>{},
          spilloverTasks: DateUtils.isSameDay(selectedInVisibleWeek, today)
              ? ref.watch(spilloverTasksProvider)
              : const [],
          todaySegment: _todaySegment,
          onTodaySegmentChanged: (v) => setState(() => _todaySegment = v),
          onGoToToday:
              DateUtils.isSameDay(selectedInVisibleWeek, today)
                  ? null
                  : _goToToday,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
