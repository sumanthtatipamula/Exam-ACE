import 'package:cloud_firestore/cloud_firestore.dart';

class Chapter {
  final String id;
  final String subjectId;
  final String name;
  final DateTime? date;
  final int progress;
  final String summaryNotes;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.name,
    this.date,
    this.progress = 0,
    this.summaryNotes = '',
  });

  Chapter copyWith({
    String? id,
    String? subjectId,
    String? name,
    DateTime? date,
    int? progress,
    String? summaryNotes,
  }) {
    return Chapter(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      date: date ?? this.date,
      progress: progress ?? this.progress,
      summaryNotes: summaryNotes ?? this.summaryNotes,
    );
  }

  factory Chapter.fromMap(String id, String subjectId, Map<String, dynamic> map) {
    return Chapter(
      id: id,
      subjectId: subjectId,
      name: map['name'] as String,
      date: (map['date'] as Timestamp?)?.toDate(),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      summaryNotes: map['summaryNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'progress': progress,
      'summaryNotes': summaryNotes,
    };
  }
}
