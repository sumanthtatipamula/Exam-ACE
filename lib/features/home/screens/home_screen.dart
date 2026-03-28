import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/core/settings/metric_formula_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedDate = DateUtils.dateOnly(DateTime(n.year, n.month, n.day));
    _visibleWeekMonday = mondayOfWeekContaining(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) syncNotificationSchedule(ref);
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
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateUtils.dateOnly(_today);
      _visibleWeekMonday = mondayOfWeekContaining(_today);
    });
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

    final today = _today;
    final weekMonday = _visibleWeekMonday;
    final selectedInVisibleWeek =
        _selectedDateInWeek(weekMonday, _selectedDate);
    final selectedKey = dateKey(selectedInVisibleWeek);
    final tasks = ref.watch(homeTasksForDateProvider(selectedKey));
    final streak = ref.watch(currentStreakProvider);
    final navBounds = ref.watch(homeWeekNavBoundsProvider);

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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: WeeklyTracker(
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
              },
              onWeekBefore: () => _shiftWeek(-1),
              onWeekAfter: () => _shiftWeek(1),
              canGoWeekBefore: canGoPrev,
              canGoWeekAfter: canGoNext,
              metricsExpanded: _metricsExpanded,
              onMetricsToggle: (expanded) {
                setState(() => _metricsExpanded = expanded);
              },
            ),
          ),
        ),
        if (!DateUtils.isSameDay(selectedInVisibleWeek, today))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Today'),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: DateUtils.isSameDay(selectedInVisibleWeek, today)
                ? DailyTasks(
                    tasks: ref.watch(homeTasksForDateProvider(todayKey)),
                    carriedTasks:
                        ref.watch(carriedTasksForTodayProvider),
                    spilloverTasks: ref.watch(spilloverTasksProvider),
                    selectedDate: selectedInVisibleWeek,
                    today: today,
                  )
                : DailyTasks(
                    tasks: tasks,
                    selectedDate: selectedInVisibleWeek,
                    today: today,
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
