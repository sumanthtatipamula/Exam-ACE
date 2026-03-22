import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime? date;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    this.imageUrl,
    this.date,
    required this.createdAt,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String?,
      date: (map['date'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      if (date != null) 'date': Timestamp.fromDate(date!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
