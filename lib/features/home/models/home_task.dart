import 'package:exam_ace/features/home/models/task.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';

enum HomeTaskSource { standalone, chapter, topic }

class HomeTask {
  final String id;
  final String title;
  final int progress;
  final DateTime date;
  final HomeTaskSource source;

  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final String? subjectName;
  final String? chapterName;

  HomeTask({
    required this.id,
    required this.title,
    required this.progress,
    required this.date,
    required this.source,
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.subjectName,
    this.chapterName,
  });

  bool get isComplete => progress >= 100;
  bool get isStandalone => source == HomeTaskSource.standalone;
  bool get isLinked => source != HomeTaskSource.standalone;

  String get sourceLabel => switch (source) {
        HomeTaskSource.standalone => 'Task',
        HomeTaskSource.chapter => 'Chapter',
        HomeTaskSource.topic => 'Topic',
      };

  String? get subtitle => switch (source) {
        HomeTaskSource.topic =>
          [subjectName, chapterName].whereType<String>().join(' · '),
        HomeTaskSource.chapter => subjectName,
        _ => null,
      };

  factory HomeTask.fromTask(Task task) {
    return HomeTask(
      id: task.id,
      title: task.title,
      progress: task.progress,
      date: task.date,
      source: HomeTaskSource.standalone,
    );
  }

  /// Call only when [Chapter.date] is non-null (scheduled day for chapter rows without topics).
  factory HomeTask.fromChapter(
    Chapter chapter,
    String subjectName,
    int completion,
  ) {
    return HomeTask(
      id: chapter.id,
      title: chapter.name,
      progress: completion,
      date: chapter.date!,
      source: HomeTaskSource.chapter,
      subjectId: chapter.subjectId,
      chapterId: chapter.id,
      subjectName: subjectName,
    );
  }

  factory HomeTask.fromTopic(
    Topic topic,
    String subjectId,
    String subjectName,
    String chapterName,
  ) {
    return HomeTask(
      id: topic.id,
      title: topic.name,
      progress: topic.progress,
      date: topic.date!,
      source: HomeTaskSource.topic,
      subjectId: subjectId,
      chapterId: topic.chapterId,
      topicId: topic.id,
      subjectName: subjectName,
      chapterName: chapterName,
    );
  }

  HomeTask copyWith({int? progress}) {
    return HomeTask(
      id: id,
      title: title,
      progress: progress ?? this.progress,
      date: date,
      source: source,
      subjectId: subjectId,
      chapterId: chapterId,
      topicId: topicId,
      subjectName: subjectName,
      chapterName: chapterName,
    );
  }
}

/// Stable id for snapshot / carry maps (Firestore keys).
String homeTaskEntityKey(HomeTask t) {
  switch (t.source) {
    case HomeTaskSource.standalone:
      return 's:${t.id}';
    case HomeTaskSource.chapter:
      return 'c:${t.subjectId}:${t.chapterId}';
    case HomeTaskSource.topic:
      return 't:${t.subjectId}:${t.chapterId}:${t.topicId}';
  }
}
