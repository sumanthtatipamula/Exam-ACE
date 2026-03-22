import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/features/home/models/task.dart';
import 'package:exam_ace/features/home/models/home_task.dart'
    show HomeTask, homeTaskEntityKey;
import 'package:exam_ace/features/subjects/providers/subjects_provider.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository();
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
  return ref.watch(tasksRepositoryProvider).watchAll();
});

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Per-calendar-day progress snapshot (for history / calendar). Merged in [homeTasksForDateProvider].
final daySnapshotForDateProvider =
    StreamProvider.family<Map<String, int>, String>((ref, dateKey) {
  return ref.watch(tasksRepositoryProvider).watchDaySnapshot(dateKey);
});

/// Entity keys the user pulled into “today” for the **current** calendar day.
final carryIdsForTodayProvider = StreamProvider<List<String>>((ref) {
  final k = dateKey(DateTime.now());
  return ref.watch(tasksRepositoryProvider).watchCarryIdsForDateKey(k);
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

final weeklyCompletionsProvider = Provider<Map<String, double>>((ref) {
  final now = DateTime.now();
  final weekday = now.weekday;
  final monday = DateUtils.dateOnly(now.subtract(Duration(days: weekday - 1)));

  final completions = <String, double>{};
  for (int i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final key = dateKey(date);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    if (tasks.isEmpty) {
      completions[key] = 0.0;
    } else {
      final done = tasks.where((t) => t.isComplete).length;
      completions[key] = done / tasks.length;
    }
  }
  return completions;
});

/// Surf bar heights + per-day task counts + week totals for the tracker UI.
class WeeklySurfData {
  final List<double> heights;
  final List<int> taskTotalsPerDay;
  /// Completed task count per day (Mon–Sun), parallel to [taskTotalsPerDay].
  final List<int> completedPerDay;
  final int weekCompletedTotal;
  final int weekTaskTotal;

  const WeeklySurfData({
    required this.heights,
    required this.taskTotalsPerDay,
    required this.completedPerDay,
    required this.weekCompletedTotal,
    required this.weekTaskTotal,
  });

  double get weekAverageRatio =>
      weekTaskTotal == 0 ? 0.0 : weekCompletedTotal / weekTaskTotal;
}

/// Surf bar heights in \[0, 1\] for Mon–Sun: **relative to the week’s max completions**
/// so more tasks finished that day → taller building (1 done vs 3 done are visibly different).
final weeklySurfDataProvider = Provider<WeeklySurfData>((ref) {
  final now = DateTime.now();
  final weekday = now.weekday;
  final monday = DateUtils.dateOnly(now.subtract(Duration(days: weekday - 1)));

  final doneCounts = <int>[];
  final totalCounts = <int>[];

  for (var i = 0; i < 7; i++) {
    final date = monday.add(Duration(days: i));
    final key = dateKey(date);
    final tasks = ref.watch(homeTasksForMetricsProvider(key));
    final total = tasks.length;
    final done = tasks.where((t) => t.isComplete).length;
    totalCounts.add(total);
    doneCounts.add(done);
  }

  final weekCompletedTotal =
      doneCounts.fold<int>(0, (a, b) => a + b);
  final weekTaskTotal =
      totalCounts.fold<int>(0, (a, b) => a + b);

  final maxDone = doneCounts.fold<int>(0, (a, b) => a > b ? a : b);
  final maxTotal = totalCounts.fold<int>(0, (a, b) => a > b ? a : b);

  if (maxDone == 0 && maxTotal == 0) {
    return WeeklySurfData(
      heights: List<double>.filled(7, 0),
      taskTotalsPerDay: totalCounts,
      completedPerDay: doneCounts,
      weekCompletedTotal: weekCompletedTotal,
      weekTaskTotal: weekTaskTotal,
    );
  }

  final heights = List<double>.generate(7, (i) {
    if (totalCounts[i] == 0) return 0.0;
    if (maxDone == 0) return 0.0;
    return (doneCounts[i] / maxDone).clamp(0.0, 1.0);
  });

  return WeeklySurfData(
    heights: heights,
    taskTotalsPerDay: totalCounts,
    completedPerDay: doneCounts,
    weekCompletedTotal: weekCompletedTotal,
    weekTaskTotal: weekTaskTotal,
  );
});

/// Same **daily average** metric as the home ribbon: mean of Mon–Sun daily
/// completion ratios (each day 0–100%, empty days count as 0%).
class WeekOverWeekStats {
  final double thisWeekDailyAvg;
  final double lastWeekDailyAvg;
  final int lastWeekTaskTotal;

  const WeekOverWeekStats({
    required this.thisWeekDailyAvg,
    required this.lastWeekDailyAvg,
    required this.lastWeekTaskTotal,
  });

  /// Last week had at least one scheduled task on some day — we can compare.
  bool get canCompareLastWeek => lastWeekTaskTotal > 0;

  /// Difference in **percentage points** (not relative %): this week − last week.
  double get deltaPctPoints => (thisWeekDailyAvg - lastWeekDailyAvg) * 100;
}

/// This week vs previous calendar week (Mon–Sun), using the same daily average
/// definition as [weeklyCompletionsProvider].
final weekOverWeekProvider = Provider<WeekOverWeekStats>((ref) {
  final now = DateTime.now();
  final wd = now.weekday;
  final thisMonday =
      DateUtils.dateOnly(now.subtract(Duration(days: wd - 1)));
  final lastMonday = thisMonday.subtract(const Duration(days: 7));

  double averageForWeekStarting(DateTime monday) {
    var sum = 0.0;
    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = dateKey(date);
      final tasks = ref.watch(homeTasksForMetricsProvider(key));
      if (tasks.isEmpty) {
        sum += 0.0;
      } else {
        final done = tasks.where((t) => t.isComplete).length;
        sum += done / tasks.length;
      }
    }
    return sum / 7.0;
  }

  var lastTotal = 0;
  for (var i = 0; i < 7; i++) {
    final date = lastMonday.add(Duration(days: i));
    final key = dateKey(date);
    lastTotal += ref.watch(homeTasksForMetricsProvider(key)).length;
  }

  return WeekOverWeekStats(
    thisWeekDailyAvg: averageForWeekStarting(thisMonday),
    lastWeekDailyAvg: averageForWeekStarting(lastMonday),
    lastWeekTaskTotal: lastTotal,
  );
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

/// Native today + carried (for notifications / combined counts).
final todayCombinedTasksProvider = Provider<List<HomeTask>>((ref) {
  final todayKey = dateKey(DateTime.now());
  final native = ref.watch(homeTasksForDateProvider(todayKey));
  final carried = ref.watch(carriedTasksForTodayProvider);
  return [...native, ...carried];
});
