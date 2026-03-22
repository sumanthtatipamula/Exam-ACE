import 'package:exam_ace/features/home/models/home_task.dart';

class DailyRecord {
  final DateTime date;
  final List<HomeTask> tasks;

  const DailyRecord({required this.date, required this.tasks});

  factory DailyRecord.fromHomeTasks(DateTime date, List<HomeTask> tasks) {
    return DailyRecord(date: date, tasks: tasks);
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isComplete).length;

  double get completionRatio =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  bool get allComplete => totalTasks > 0 && completedTasks == totalTasks;
  bool get hasPartial => completedTasks > 0 && !allComplete;
  bool get noneComplete => completedTasks == 0;
}
