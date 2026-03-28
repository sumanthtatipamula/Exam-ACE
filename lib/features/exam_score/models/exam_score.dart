import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether the exam has been written or is still upcoming.
enum ExamAttemptStatus {
  taken,
  yetToTake,
}

extension ExamAttemptStatusLabels on ExamAttemptStatus {
  String get label => switch (this) {
        ExamAttemptStatus.taken => 'Taken',
        ExamAttemptStatus.yetToTake => 'Yet to take',
      };
}

/// A government / competitive exam entry (upcoming or completed).
class Exam {
  final String id;
  final String examName;
  final DateTime date;
  final ExamAttemptStatus status;
  final int? marksObtained;
  final int? totalMarks;

  const Exam({
    required this.id,
    required this.examName,
    required this.date,
    required this.status,
    this.marksObtained,
    this.totalMarks,
  });

  /// Null when scores are missing or invalid (e.g. not taken yet).
  double? get percentage {
    final t = totalMarks;
    final m = marksObtained;
    if (t == null || t <= 0 || m == null) return null;
    return (m / t * 100).clamp(0.0, 100.0);
  }

  Exam copyWith({
    String? id,
    String? examName,
    DateTime? date,
    ExamAttemptStatus? status,
    int? marksObtained,
    int? totalMarks,
    bool clearMarks = false,
  }) {
    return Exam(
      id: id ?? this.id,
      examName: examName ?? this.examName,
      date: date ?? this.date,
      status: status ?? this.status,
      marksObtained: clearMarks ? null : (marksObtained ?? this.marksObtained),
      totalMarks: clearMarks ? null : (totalMarks ?? this.totalMarks),
    );
  }

  factory Exam.fromMap(String id, Map<String, dynamic> map) {
    ExamAttemptStatus status;
    final raw = map['status'] as String?;
    if (raw == ExamAttemptStatus.yetToTake.name) {
      status = ExamAttemptStatus.yetToTake;
    } else {
      status = ExamAttemptStatus.taken;
    }

    return Exam(
      id: id,
      examName: map['examName'] as String? ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      status: status,
      marksObtained: (map['marksObtained'] as num?)?.toInt(),
      totalMarks: (map['totalMarks'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examName': examName,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
    };
  }
}
