import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String id;
  final String chapterId;
  final String name;
  final DateTime? date;
  final int progress;
  final String notes;

  /// When this topic was first created (list order). Legacy docs may omit this.
  final DateTime? createdAt;

  const Topic({
    required this.id,
    required this.chapterId,
    required this.name,
    this.date,
    this.progress = 0,
    this.notes = '',
    this.createdAt,
  });

  bool get isComplete => progress >= 100;

  Topic copyWith({
    String? id,
    String? chapterId,
    String? name,
    DateTime? date,
    int? progress,
    String? notes,
    DateTime? createdAt,
  }) {
    return Topic(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      name: name ?? this.name,
      date: date ?? this.date,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Topic.fromMap(String id, String chapterId, Map<String, dynamic> map) {
    return Topic(
      id: id,
      chapterId: chapterId,
      name: map['name'] as String,
      date: (map['date'] as Timestamp?)?.toDate(),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'progress': progress,
      'notes': notes,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
