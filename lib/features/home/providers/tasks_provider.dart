import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/features/home/models/task.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, homeTaskEntityKey;
import 'package:exam_ace/core/settings/metric_formula_provider.dart';
import 'package:exam_ace/core/utils/metric_formulas.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
});

/// Home FAB / add-task uses this date (updated by [HomeScreen] when the user picks a day).
final homeSelectedDateProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateUtils.dateOnly(DateTime(n.year, n.month, n.day));
});

class TasksRepository {
  final _firestore = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _tasksCol() =>
      _firestore.collection('users').doc(_uid).collection('tasks');

  DocumentReference<Map<String, dynamic>> _daySnapshotDoc(String dateKey) =>
      _firestore.collection('users').doc(_uid).collection('daySnapshots').doc(dateKey);

  DocumentReference<Map<String, dynamic>> _carryDoc(String dateKey) =>
      _firestore.collection('users').doc(_uid).collection('carryToToday').doc(dateKey);

  /// Per-day frozen progress for calendar/history (only [scheduledDateKey] == today updates live).
  Stream<Map<String, int>> watchDaySnapshot(String dateKey) {
    return _daySnapshotDoc(dateKey).snapshots().map((s) {
      final raw = s.data()?['values'] as Map<String, dynamic>?;
      if (raw == null || raw.isEmpty) return <String, int>{};
      return raw.map((k, v) => MapEntry(k, (v as num).round()));
    });
  }

  /// Call after any progress write. Only records when the task’s scheduled day is **today**
  /// (so completing spillover work tomorrow does not rewrite yesterday’s snapshot).
  Future<void> recordProgressForSnapshotIfScheduledToday({
    required String scheduledDateKey,
    required String entityKey,
    required int progress,
  }) async {
    final todayKey = dateKey(DateTime.now());
    if (scheduledDateKey != todayKey) return;
    await mergeProgressIntoTodaySnapshot(
      entityKey: entityKey,
      progress: progress,
    );
  }

  /// Merges progress into **today’s** snapshot (e.g. carried spillover: scheduled day is in the past).
  Future<void> mergeProgressIntoTodaySnapshot({
    required String entityKey,
    required int progress,
  }) async {
    final todayKey = dateKey(DateTime.now());
    await _daySnapshotDoc(todayKey).set(
      {
        'values': {entityKey: progress},
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<String>> watchCarryIdsForDateKey(String dateKey) {
    return _carryDoc(dateKey).snapshots().map((s) {
      final raw = s.data()?['ids'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return <String>[];
    });
  }

  /// How many distinct calendar days each entity appears in [carryToToday] (spill-over count).
  Stream<Map<String, int>> watchCarrySpillDayCounts() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('carryToToday')
        .snapshots()
        .map((snap) {
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final raw = doc.data()['ids'];
        if (raw is! List) continue;
        for (final e in raw) {
          final id = e.toString();
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  Future<void> addCarryToToday(String entityKey) async {
    final k = dateKey(DateTime.now());
    await _carryDoc(k).set(
      {
        'ids': FieldValue.arrayUnion([entityKey]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeCarryFromToday(String entityKey) async {
    final k = dateKey(DateTime.now());
    await _carryDoc(k).set(
      {
        'ids': FieldValue.arrayRemove([entityKey]),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<Task>> watchAll() {
    return _tasksCol()
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Task.fromMap(d.id, d.data())).toList());
  }

  Future<void> add(Task task) => _tasksCol().add(task.toMap());

  Future<void> updateProgress(String taskId, int progress) =>
      _tasksCol().doc(taskId).update({'progress': progress});

  Future<void> delete(String taskId) => _tasksCol().doc(taskId).delete();
}

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

final allStandaloneTasksProvider = StreamProvider<List<Task>>((ref) {
  return streamWhenSignedIn(
    ref,
    <Task>[],
    () => ref.watch(tasksRepositoryProvider).watchAll(),
  );
});

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Monday 00:00 of the calendar week containing [d].
DateTime mondayOfWeekContaining(DateTime d) {
  final wd = d.weekday;
  return DateUtils.dateOnly(d.subtract(Duration(days: wd - 1)));
}

/// Mean progress in \[0, 1\] across countable tasks (partial work counts).
/// Carried spillover is excluded upstream via [homeTasksForMetricsProvider].
double dailyAverageProgressRatio(List<HomeTask> tasks) {
  if (tasks.isEmpty) return 0.0;
  var sum = 0;
  for (final t in tasks) {
    sum += t.progress.clamp(0, 100);
  }
  return sum / (tasks.length * 100.0);
}

/// Weekly headline ratio \[0, 1\] for the Mon–Sun week starting [weekMonday],
/// using [metricFormulaProvider] (Math / Physics / Chemistry).
double computeWeeklyMetricRatio(Ref ref, DateTime weekMonday) {
  final mode = ref.watch(metricFormulaProvider);
  final monday = DateUtils.dateOnly(weekMonday);
  final progressPerTask = <int>[];
  final dailyAvgs = <double>[];
  final dailyCounts = <int>[];
  for (var i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final key = dateKey(date);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    dailyCounts.add(tasks.length);
    dailyAvgs.add(dailyAverageProgressRatio(tasks));
    for (final t in tasks) {
      progressPerTask.add(t.progress.clamp(0, 100));
    }
  }
  return weeklyRatioForMode(
    mode: mode,
    progressPerTask: progressPerTask,
    dailyAverageRatios: dailyAvgs,
    taskCountPerDay: dailyCounts,
  );
}

/// Same as [computeWeeklyMetricRatio] (week-over-week ribbon uses this).
double weeklyProgressRatioForWeek(Ref ref, DateTime weekMonday) {
  return computeWeeklyMetricRatio(ref, weekMonday);
}

/// Per-calendar-day progress snapshot (for history / calendar). Merged in [homeTasksForDateProvider].
final daySnapshotForDateProvider =
    StreamProvider.family<Map<String, int>, String>((ref, dateKey) {
  return streamWhenSignedIn(
    ref,
    <String, int>{},
    () => ref.watch(tasksRepositoryProvider).watchDaySnapshot(dateKey),
  );
});

/// Entity keys the user pulled into “today” for the **current** calendar day.
final carryIdsForTodayProvider = StreamProvider<List<String>>((ref) {
  final k = dateKey(DateTime.now());
  return streamWhenSignedIn(
    ref,
    <String>[],
    () => ref.watch(tasksRepositoryProvider).watchCarryIdsForDateKey(k),
  );
});

/// Per entity: number of distinct days this task was added to “today” via spill-over.
final carrySpillDayCountsProvider =
    StreamProvider<Map<String, int>>((ref) {
  return streamWhenSignedIn(
    ref,
    <String, int>{},
    () => ref.watch(tasksRepositoryProvider).watchCarrySpillDayCounts(),
  );
});

/// Builds the list of home tasks for a given date using priority:
///   1. Topics with matching date (always shown)
///   2. Chapters with matching date — only if the chapter has NO topics at all
///   3. Standalone tasks with matching date (always shown)
///
/// Subject-level target dates are not shown as tasks; completion is driven by chapters
/// (and subject [Subject.date] is set when all chapters complete).
final homeTasksForDateProvider =
    Provider.family<List<HomeTask>, String>((ref, targetKey) {
  final tasks = ref.watch(allStandaloneTasksProvider).valueOrNull ?? [];
  final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

  final result = <HomeTask>[];

  for (final task in tasks) {
    if (dateKey(task.date) == targetKey) {
      result.add(HomeTask.fromTask(task));
    }
  }

  for (final subject in subjects) {
    final chapters =
        ref.watch(chaptersStreamProvider(subject.id)).valueOrNull ?? [];

    for (final ch in chapters) {
      final topics = ref
              .watch(topicsStreamProvider(
                  (subjectId: subject.id, chapterId: ch.id)))
              .valueOrNull ??
          [];

      if (topics.isEmpty) {
        if (ch.date != null && dateKey(ch.date!) == targetKey) {
          final completion = chapterCompletion(ch, topics);
          result.add(HomeTask.fromChapter(ch, subject.name, completion));
        }
      } else {
        for (final topic in topics) {
          if (topic.date != null && dateKey(topic.date!) == targetKey) {
            result.add(HomeTask.fromTopic(
                topic, subject.id, subject.name, ch.name));
          }
        }
      }
    }
  }

  final snap = ref.watch(daySnapshotForDateProvider(targetKey)).valueOrNull ?? {};
  return result
      .map((t) {
        final p = snap[homeTaskEntityKey(t)];
        if (p == null) return t;
        return t.copyWith(progress: p);
      })
      .toList();
});

/// Scheduled tasks for [targetKey], excluding any entity in [carryIdsForTodayProvider].
/// Spillover items “added to today” still appear in the home list but must not move
/// week ribbon, surf, streak, or week-over-week stats.
final homeTasksForMetricsProvider =
    Provider.family<List<HomeTask>, String>((ref, targetKey) {
  final tasks = ref.watch(homeTasksForDateProvider(targetKey));
  final carry = ref.watch(carryIdsForTodayProvider).valueOrNull ?? [];
  if (carry.isEmpty) return tasks;
  final carrySet = carry.toSet();
  return tasks
      .where((t) => !carrySet.contains(homeTaskEntityKey(t)))
      .toList();
});

/// Mon–Sun average progress ratios \[0,1\] for the week starting [weekMonday] (00:00 Monday).
final weeklyCompletionsForWeekProvider =
    Provider.family<Map<String, double>, DateTime>((ref, weekMonday) {
  final monday = DateUtils.dateOnly(weekMonday);

  final completions = <String, double>{};
  for (int i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final key = dateKey(date);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    completions[key] = dailyAverageProgressRatio(tasks);
  }
  return completions;
});

final weeklyCompletionsProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(weeklyCompletionsForWeekProvider(mondayOfWeekContaining(DateTime.now())));
});

/// Surf bar heights + per-day task counts + week progress totals for the tracker UI.
class WeeklySurfData {
  final List<double> heights;
  final List<int> taskTotalsPerDay;
  /// Sum of task progress per day (0–100 each), parallel to [taskTotalsPerDay].
  final List<int> progressSumPerDay;
  /// Tasks at 100% that day — drives surf building height vs the week’s max count.
  final List<int> completedCountPerDay;
  /// Total progress points across the week (sum of per-task progress).
  final int weekProgressSum;
  /// Max possible for the week (\[task count\] × 100).
  final int weekProgressCap;

  /// Ribbon / footer % — from [metricFormulaProvider], not always sum ÷ cap.
  final double weekMetricRatio;

  const WeeklySurfData({
    required this.heights,
    required this.taskTotalsPerDay,
    required this.progressSumPerDay,
    required this.completedCountPerDay,
    required this.weekProgressSum,
    required this.weekProgressCap,
    required this.weekMetricRatio,
  });
}

/// Surf bar heights in \[0, 1\] for Mon–Sun.
///
/// **Today and future** columns use **that day’s** completion fraction
/// (`completedTasks / scheduledTasks`) so 1-of-3 and 2-of-3 produce different bar
/// heights (previously `completed ÷ weekMax` often collapsed to full height).
///
/// **Past** days keep the older “scheduled load” height scaled by [maxDayScale]
/// when incomplete so ruined / cracked facades stay readable in the painter.
final weeklySurfDataForWeekProvider =
    Provider.family<WeeklySurfData, DateTime>((ref, weekMonday) {
  ref.watch(metricFormulaProvider);
  final monday = DateUtils.dateOnly(weekMonday);
  final todayOnly = DateUtils.dateOnly(DateTime.now());

  final totalCounts = <int>[];
  final progressSums = <int>[];
  final completedPerDay = <int>[];

  for (var i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final key = dateKey(date);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    final total = tasks.length;
    var sum = 0;
    var done = 0;
    for (final t in tasks) {
      sum += t.progress.clamp(0, 100);
      if (t.isComplete) done++;
    }
    totalCounts.add(total);
    progressSums.add(sum);
    completedPerDay.add(done);
  }

  final weekProgressSum =
      progressSums.fold<int>(0, (a, b) => a + b);
  final weekTaskCount =
      totalCounts.fold<int>(0, (a, b) => a + b);
  final weekProgressCap = weekTaskCount * 100;

  final weekMetricRatio = computeWeeklyMetricRatio(ref, monday);

  var maxDayScale = 0;
  for (var i = 0; i < 7; i++) {
    final t = totalCounts[i];
    if (t == 0) continue;
    final c = completedPerDay[i];
    final scale = c > 0 ? c : t;
    if (scale > maxDayScale) maxDayScale = scale;
  }

  if (weekTaskCount == 0) {
    return WeeklySurfData(
      heights: List<double>.filled(7, 0),
      taskTotalsPerDay: totalCounts,
      progressSumPerDay: progressSums,
      completedCountPerDay: completedPerDay,
      weekProgressSum: weekProgressSum,
      weekProgressCap: weekProgressCap,
      weekMetricRatio: weekMetricRatio,
    );
  }

  if (maxDayScale == 0) {
    return WeeklySurfData(
      heights: List<double>.filled(7, 0),
      taskTotalsPerDay: totalCounts,
      progressSumPerDay: progressSums,
      completedCountPerDay: completedPerDay,
      weekProgressSum: weekProgressSum,
      weekProgressCap: weekProgressCap,
      weekMetricRatio: weekMetricRatio,
    );
  }

  final heights = List<double>.generate(7, (i) {
    if (totalCounts[i] == 0) return 0.0;
    final t = totalCounts[i];
    final c = completedPerDay[i];
    final dayOnly = DateUtils.dateOnly(monday.add(Duration(days: i)));
    final isTodayOrFuture = !dayOnly.isBefore(todayOnly);
    if (isTodayOrFuture) {
      return t > 0 ? (c / t).clamp(0.0, 1.0) : 0.0;
    }
    final num = c > 0 ? c : t;
    return (num / maxDayScale).clamp(0.0, 1.0);
  });

  return WeeklySurfData(
    heights: heights,
    taskTotalsPerDay: totalCounts,
    progressSumPerDay: progressSums,
    completedCountPerDay: completedPerDay,
    weekProgressSum: weekProgressSum,
    weekProgressCap: weekProgressCap,
    weekMetricRatio: weekMetricRatio,
  );
});

final weeklySurfDataProvider = Provider<WeeklySurfData>((ref) {
  return ref.watch(weeklySurfDataForWeekProvider(mondayOfWeekContaining(DateTime.now())));
});

/// Week-over-week for the **ribbon** only: total weekly progress ÷ cap (not surf).
class WeekOverWeekStats {
  final double thisWeekProgressRatio;
  final double lastWeekProgressRatio;
  final int thisWeekTaskTotal;
  final int lastWeekTaskTotal;

  const WeekOverWeekStats({
    required this.thisWeekProgressRatio,
    required this.lastWeekProgressRatio,
    required this.thisWeekTaskTotal,
    required this.lastWeekTaskTotal,
  });

  /// Both weeks must have at least one scheduled task — otherwise vs last week is misleading
  /// (e.g. empty future week vs a full prior week reads as −100%).
  bool get canShowWeekOverWeekComparison =>
      thisWeekTaskTotal > 0 && lastWeekTaskTotal > 0;

  /// Difference in **percentage points** (not relative %): this week − last week.
  double get deltaPctPoints =>
      (thisWeekProgressRatio - lastWeekProgressRatio) * 100;
}

/// Same definition as [WeeklySurfData.weekMetricRatio] / ribbon `Progress` column.
/// Compares the week starting [weekMonday] to the prior Mon–Sun week.
final weekOverWeekForWeekProvider =
    Provider.family<WeekOverWeekStats, DateTime>((ref, weekMonday) {
  ref.watch(metricFormulaProvider);
  final thisMonday = DateUtils.dateOnly(weekMonday);
  final lastMonday = thisMonday.subtract(const Duration(days: 7));

  var thisTotal = 0;
  var lastTotal = 0;
  for (var i = 0; i < 7; i++) {
    final thisKey = dateKey(thisMonday.add(Duration(days: i)));
    final lastKey = dateKey(lastMonday.add(Duration(days: i)));
    thisTotal += ref.watch(homeTasksForMetricsProvider(thisKey)).length;
    lastTotal += ref.watch(homeTasksForMetricsProvider(lastKey)).length;
  }

  return WeekOverWeekStats(
    thisWeekProgressRatio: weeklyProgressRatioForWeek(ref, thisMonday),
    lastWeekProgressRatio: weeklyProgressRatioForWeek(ref, lastMonday),
    thisWeekTaskTotal: thisTotal,
    lastWeekTaskTotal: lastTotal,
  );
});

final weekOverWeekProvider = Provider<WeekOverWeekStats>((ref) {
  return ref.watch(weekOverWeekForWeekProvider(mondayOfWeekContaining(DateTime.now())));
});

/// Days with **at least one countable task** and **100%** of those complete,
/// counting backward from today. Days with **no tasks** are skipped (rest
/// days don’t break the streak). The first day that has countable tasks but
/// not all done stops the count.
///
final currentStreakProvider = Provider<int>((ref) {
  // Ensure streak recomputes whenever any task / subject stream changes (not
  // only the dates visited in the loop below).
  ref.watch(allStandaloneTasksProvider);
  ref.watch(subjectsStreamProvider);

  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);
  var streak = 0;
  for (var i = 0; i < 400; i++) {
    final key = dateKey(d);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    if (tasks.isEmpty) {
      d = d.subtract(const Duration(days: 1));
      continue;
    }
    if (tasks.every((t) => t.isComplete)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
});

/// All date keys that have at least one task (for calendar dot indicators).
final allTaskDateKeysProvider = Provider<Map<String, List<HomeTask>>>((ref) {
  final tasks = ref.watch(allStandaloneTasksProvider).valueOrNull ?? [];
  final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? [];

  final map = <String, List<HomeTask>>{};

  for (final task in tasks) {
    final key = dateKey(task.date);
    map.putIfAbsent(key, () => []).add(HomeTask.fromTask(task));
  }

  for (final subject in subjects) {
    final chapters =
        ref.watch(chaptersStreamProvider(subject.id)).valueOrNull ?? [];

    for (final ch in chapters) {
      final topics = ref
              .watch(topicsStreamProvider(
                  (subjectId: subject.id, chapterId: ch.id)))
              .valueOrNull ??
          [];

      if (topics.isEmpty) {
        if (ch.date != null) {
          final key = dateKey(ch.date!);
          final completion = chapterCompletion(ch, topics);
          map.putIfAbsent(key, () => []).add(
              HomeTask.fromChapter(ch, subject.name, completion));
        }
      } else {
        for (final topic in topics) {
          if (topic.date != null) {
            final key = dateKey(topic.date!);
            map.putIfAbsent(key, () => []).add(HomeTask.fromTopic(
                topic, subject.id, subject.name, ch.name));
          }
        }
      }
    }
  }

  return map;
});

/// Home week strip: **back** = earliest week that has any scheduled task (or current week if none);
/// **forward** ≈ one month: week containing **today + 31 days** (upper bound).
final homeWeekNavBoundsProvider =
    Provider<({DateTime earliestMonday, DateTime latestMonday})>((ref) {
  final now = DateTime.now();
  final today = DateUtils.dateOnly(now);
  final thisMonday = mondayOfWeekContaining(now);
  final latestMonday =
      mondayOfWeekContaining(today.add(const Duration(days: 31)));

  final map = ref.watch(allTaskDateKeysProvider);
  if (map.isEmpty) {
    return (earliestMonday: thisMonday, latestMonday: latestMonday);
  }

  DateTime? minD;
  for (final key in map.keys) {
    final parts = key.split('-');
    if (parts.length != 3) continue;
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    if (minD == null || d.isBefore(minD)) minD = d;
  }
  if (minD == null) {
    return (earliestMonday: thisMonday, latestMonday: latestMonday);
  }

  var earliestMonday = mondayOfWeekContaining(minD);
  final thisNorm = DateUtils.dateOnly(thisMonday);
  if (earliestMonday.isAfter(thisNorm)) {
    earliestMonday = thisNorm;
  }
  return (earliestMonday: earliestMonday, latestMonday: latestMonday);
});

/// All [HomeTask]s keyed by [homeTaskEntityKey] (latest streams; used to resolve carry ids).
final homeTaskEntityLookupProvider = Provider<Map<String, HomeTask>>((ref) {
  final map = ref.watch(allTaskDateKeysProvider);
  final out = <String, HomeTask>{};
  for (final list in map.values) {
    for (final t in list) {
      out[homeTaskEntityKey(t)] = t;
    }
  }
  return out;
});

/// Carried spillover tasks listed under today (editable; excluded from surf/streak via schedule).
final carriedTasksForTodayProvider = Provider<List<HomeTask>>((ref) {
  final ids = ref.watch(carryIdsForTodayProvider).valueOrNull ?? [];
  if (ids.isEmpty) return [];
  final lookup = ref.watch(homeTaskEntityLookupProvider);
  return ids.map((id) => lookup[id]).whereType<HomeTask>().toList();
});

/// Incomplete tasks scheduled before today, excluding those already carried into today.
final spilloverTasksProvider = Provider<List<HomeTask>>((ref) {
  final todayKey = dateKey(DateTime.now());
  final carry =
      ref.watch(carryIdsForTodayProvider).valueOrNull ?? const <String>[];
  final carrySet = carry.toSet();
  final map = ref.watch(allTaskDateKeysProvider);
  final out = <HomeTask>[];
  for (final e in map.entries) {
    if (e.key.compareTo(todayKey) >= 0) continue;
    for (final t in e.value) {
      if (t.isComplete) continue;
      if (carrySet.contains(homeTaskEntityKey(t))) continue;
      out.add(t);
    }
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
});

/// Tasks for calendar **dots** (and month grid): past scheduled days must not show
/// “all done” from spillover completion today when there is no snapshot for that day.
/// For **today**, includes [carriedTasksForTodayProvider] with today’s snapshot overlay.
final calendarDayTasksProvider =
    Provider.family<List<HomeTask>, String>((ref, targetDateKey) {
  final todayKey = dateKey(DateTime.now());

  if (targetDateKey == todayKey) {
    final native = ref.watch(homeTasksForDateProvider(todayKey));
    final carried = ref.watch(carriedTasksForTodayProvider);
    final snap =
        ref.watch(daySnapshotForDateProvider(todayKey)).valueOrNull ?? {};
    final carriedWithSnap = carried.map((t) {
      final p = snap[homeTaskEntityKey(t)];
      if (p == null) return t;
      return t.copyWith(progress: p);
    }).toList();
    return [...native, ...carriedWithSnap];
  }

  final tasks = ref.watch(homeTasksForDateProvider(targetDateKey));
  if (targetDateKey.compareTo(todayKey) > 0) return tasks;

  final snap =
      ref.watch(daySnapshotForDateProvider(targetDateKey)).valueOrNull ?? {};
  final carry =
      ref.watch(carryIdsForTodayProvider).valueOrNull ?? const <String>[];
  final carrySet = carry.toSet();

  return tasks.map((t) {
    final ek = homeTaskEntityKey(t);
    if (carrySet.contains(ek) && t.isComplete && !snap.containsKey(ek)) {
      return t.copyWith(progress: 0);
    }
    return t;
  }).toList();
});

/// Native today + carried (for notifications / combined counts).
/// Same list as [calendarDayTasksProvider] for today so counts stay aligned with calendar/home.
final todayCombinedTasksProvider = Provider<List<HomeTask>>((ref) {
  return ref.watch(calendarDayTasksProvider(dateKey(DateTime.now())));
});
