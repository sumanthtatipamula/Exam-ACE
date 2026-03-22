import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/services/notification_service.dart';
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

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedDate = DateTime(n.year, n.month, n.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) syncNotificationSchedule(ref);
    });
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
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
    final selectedKey = dateKey(_selectedDate);
    final tasks = ref.watch(homeTasksForDateProvider(selectedKey));
    final weeklyCompletions = ref.watch(weeklyCompletionsProvider);
    final surfData = ref.watch(weeklySurfDataProvider);
    final weekOverWeek = ref.watch(weekOverWeekProvider);
    final streak = ref.watch(currentStreakProvider);

    final todayKey = dateKey(today);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: WeeklyTracker(
              completions: weeklyCompletions,
              surfData: surfData,
              weekOverWeek: weekOverWeek,
              streak: streak,
              selectedDate: _selectedDate,
              today: today,
              onDaySelected: (day) {
                setState(() {
                  _selectedDate =
                      DateTime(day.year, day.month, day.day);
                });
              },
            ),
          ),
        ),
        if (!DateUtils.isSameDay(_selectedDate, today))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _selectedDate = today),
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
            child: DateUtils.isSameDay(_selectedDate, today)
                ? DailyTasks(
                    tasks: ref.watch(homeTasksForDateProvider(todayKey)),
                    carriedTasks:
                        ref.watch(carriedTasksForTodayProvider),
                    spilloverTasks: ref.watch(spilloverTasksProvider),
                    selectedDate: _selectedDate,
                    today: today,
                  )
                : DailyTasks(
                    tasks: tasks,
                    selectedDate: _selectedDate,
                    today: today,
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
