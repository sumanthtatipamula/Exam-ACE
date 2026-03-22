import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final int progress;
  final DateTime date;

  const Task({
    required this.id,
    required this.title,
    this.progress = 0,
    required this.date,
  });

  bool get isComplete => progress >= 100;

  Task copyWith({
    String? id,
    String? title,
    int? progress,
    DateTime? date,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      date: date ?? this.date,
    );
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] as String,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'progress': progress,
      'date': Timestamp.fromDate(date),
    };
  }
}
