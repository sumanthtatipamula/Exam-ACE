import 'package:cloud_firestore/cloud_firestore.dart';

enum LinkType { none, subject, chapter, topic }

class MockTest {
  final String id;
  final String title;
  final int marksObtained;
  final int totalMarks;
  final DateTime date;
  final LinkType linkType;
  final String? linkedSubjectId;
  final String? linkedChapterId;
  final String? linkedTopicId;
  final String? linkedName;

  const MockTest({
    required this.id,
    required this.title,
    required this.marksObtained,
    required this.totalMarks,
    required this.date,
    this.linkType = LinkType.none,
    this.linkedSubjectId,
    this.linkedChapterId,
    this.linkedTopicId,
    this.linkedName,
  });

  double get percentage =>
      totalMarks > 0 ? (marksObtained / totalMarks * 100) : 0;

  MockTest copyWith({
    String? id,
    String? title,
    int? marksObtained,
    int? totalMarks,
    DateTime? date,
    LinkType? linkType,
    String? linkedSubjectId,
    String? linkedChapterId,
    String? linkedTopicId,
    String? linkedName,
  }) {
    return MockTest(
      id: id ?? this.id,
      title: title ?? this.title,
      marksObtained: marksObtained ?? this.marksObtained,
      totalMarks: totalMarks ?? this.totalMarks,
      date: date ?? this.date,
      linkType: linkType ?? this.linkType,
      linkedSubjectId: linkedSubjectId ?? this.linkedSubjectId,
      linkedChapterId: linkedChapterId ?? this.linkedChapterId,
      linkedTopicId: linkedTopicId ?? this.linkedTopicId,
      linkedName: linkedName ?? this.linkedName,
    );
  }

  factory MockTest.fromMap(String id, Map<String, dynamic> map) {
    final rawLinkType = map['linkType']?.toString() ?? 'none';
    final parsedLinkType = LinkType.values.asNameMap()[rawLinkType] ?? LinkType.none;

    return MockTest(
      id: id,
      title: map['title'] as String? ?? '',
      marksObtained: (map['marksObtained'] as num?)?.toInt() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toInt() ?? 0,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      linkType: parsedLinkType,
      linkedSubjectId: map['linkedSubjectId'] as String?,
      linkedChapterId: map['linkedChapterId'] as String?,
      linkedTopicId: map['linkedTopicId'] as String?,
      linkedName: map['linkedName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'date': Timestamp.fromDate(date),
      'linkType': linkType.name,
      'linkedSubjectId': linkedSubjectId,
      'linkedChapterId': linkedChapterId,
      'linkedTopicId': linkedTopicId,
      'linkedName': linkedName,
    };
  }
}
