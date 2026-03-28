import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/services/image_upload_service.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/subjects/models/subject.dart';
import 'package:exam_ace/core/settings/syllabus_sort.dart';
import 'package:exam_ace/core/settings/syllabus_sort_provider.dart';
import 'package:exam_ace/features/subjects/models/chapter.dart';
import 'package:exam_ace/features/subjects/models/topic.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository();
});

class SubjectsRepository {
  final _firestore = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _subjectsCol() =>
      _firestore.collection('users').doc(_uid).collection('subjects');

  CollectionReference<Map<String, dynamic>> _chaptersCol(String subjectId) =>
      _subjectsCol().doc(subjectId).collection('chapters');

  CollectionReference<Map<String, dynamic>> _topicsCol(
          String subjectId, String chapterId) =>
      _chaptersCol(subjectId).doc(chapterId).collection('topics');

  // --- Subjects ---

  Stream<List<Subject>> watchSubjects() {
    return _subjectsCol()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList());
  }

  Future<void> addSubject(Subject subject) =>
      _subjectsCol().add(subject.toMap());

  /// When [clearImageUrl] is true, removes `imageUrl` in Firestore and deletes the
  /// previous Storage object if [previousImageUrlForStorageDelete] is a Firebase URL.
  Future<void> updateSubject(
    Subject subject, {
    bool clearImageUrl = false,
    String? previousImageUrlForStorageDelete,
  }) async {
    final map = Map<String, dynamic>.from(subject.toMap());
    if (clearImageUrl) {
      map['imageUrl'] = FieldValue.delete();
    }
    await _subjectsCol().doc(subject.id).update(map);
    if (clearImageUrl && previousImageUrlForStorageDelete != null) {
      await ImageUploadService.deleteFirebaseStorageDownloadUrl(
          previousImageUrlForStorageDelete);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    final chaptersSnap = await _chaptersCol(subjectId).get();
    for (final chDoc in chaptersSnap.docs) {
      await deleteChapter(subjectId, chDoc.id);
    }
    await _subjectsCol().doc(subjectId).delete();
  }

  // --- Chapters ---

  Stream<List<Chapter>> watchChapters(String subjectId) {
    return _chaptersCol(subjectId).snapshots().map((snap) => snap.docs
        .map((d) => Chapter.fromMap(d.id, subjectId, d.data()))
        .toList());
  }

  Future<void> addChapter(String subjectId, Chapter chapter) async {
    await _chaptersCol(subjectId).add(chapter.toMap());
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  Future<void> updateChapter(String subjectId, Chapter chapter) async {
    await _chaptersCol(subjectId).doc(chapter.id).update(chapter.toMap());
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  /// Updates only [progress] (e.g. from Home when the chapter has no topics).
  Future<void> updateChapterProgress(
    String subjectId,
    String chapterId,
    int progress,
  ) async {
    await _chaptersCol(subjectId).doc(chapterId).update({'progress': progress});
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  Future<void> deleteChapter(String subjectId, String chapterId) async {
    final topicsSnap = await _topicsCol(subjectId, chapterId).get();
    for (final tDoc in topicsSnap.docs) {
      await tDoc.reference.delete();
    }
    await _chaptersCol(subjectId).doc(chapterId).delete();
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  /// When every chapter is fully complete and [Subject.date] is still null,
  /// sets it to today's calendar date (completion milestone).
  Future<void> _syncSubjectCompletionDateIfNeeded(String subjectId) async {
    final doc = await _subjectsCol().doc(subjectId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if ((data['date'] as Timestamp?) != null) return;

    final chaptersSnap = await _chaptersCol(subjectId).get();
    if (chaptersSnap.docs.isEmpty) return;

    for (final chDoc in chaptersSnap.docs) {
      final topicsSnap = await _topicsCol(subjectId, chDoc.id).get();
      if (topicsSnap.docs.isEmpty) {
        final progress = (chDoc.data()['progress'] as num?)?.toInt() ?? 0;
        if (progress < 100) return;
      } else {
        for (final tDoc in topicsSnap.docs) {
          final prog = (tDoc.data()['progress'] as num?)?.toInt() ?? 0;
          if (prog < 100) return;
        }
      }
    }

    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    await _subjectsCol().doc(subjectId).update({'date': Timestamp.fromDate(d)});
  }

  // --- Topics ---

  Stream<List<Topic>> watchTopics(String subjectId, String chapterId) {
    return _topicsCol(subjectId, chapterId).snapshots().map((snap) => snap.docs
        .map((d) => Topic.fromMap(d.id, chapterId, d.data()))
        .toList());
  }

  Future<void> addTopic(String subjectId, String chapterId, Topic topic) async {
    await _topicsCol(subjectId, chapterId).add(topic.toMap());
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  Future<void> updateTopic(String subjectId, String chapterId, Topic topic) async {
    await _topicsCol(subjectId, chapterId).doc(topic.id).update(topic.toMap());
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  /// Updates only [progress] (e.g. from Home) without touching notes.
  Future<void> updateTopicProgress(
    String subjectId,
    String chapterId,
    String topicId,
    int progress,
  ) async {
    await _topicsCol(subjectId, chapterId).doc(topicId).update({'progress': progress});
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }

  Future<void> deleteTopic(
          String subjectId, String chapterId, String topicId) async {
    await _topicsCol(subjectId, chapterId).doc(topicId).delete();
    await _syncSubjectCompletionDateIfNeeded(subjectId);
  }
}

// ---------------------------------------------------------------------------
// Stream providers (kept as top-level for backward compatibility)
// ---------------------------------------------------------------------------

final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  return streamWhenSignedIn(
    ref,
    <Subject>[],
    () => ref.watch(subjectsRepositoryProvider).watchSubjects(),
  );
});

/// Raw Firestore order for chapters (unsorted).
final _rawChaptersStreamProvider =
    StreamProvider.family<List<Chapter>, String>((ref, subjectId) {
  return streamWhenSignedIn(
    ref,
    <Chapter>[],
    () => ref.watch(subjectsRepositoryProvider).watchChapters(subjectId),
  );
});

/// Chapters for [subjectId] sorted by [syllabusSortProvider].
final chaptersStreamProvider =
    Provider.family<AsyncValue<List<Chapter>>, String>((ref, subjectId) {
  final raw = ref.watch(_rawChaptersStreamProvider(subjectId));
  final mode = ref.watch(syllabusSortProvider);
  return raw.whenData((list) {
    final copy = List<Chapter>.from(list);
    sortChapters(copy, mode);
    return copy;
  });
});

/// Raw Firestore order for topics (unsorted).
final _rawTopicsStreamProvider = StreamProvider.family<
    List<Topic>,
    ({String subjectId, String chapterId})>((ref, params) {
  return streamWhenSignedIn(
    ref,
    <Topic>[],
    () => ref.watch(subjectsRepositoryProvider).watchTopics(
          params.subjectId,
          params.chapterId,
        ),
  );
});

/// Topics sorted by [syllabusSortProvider].
final topicsStreamProvider = Provider.family<
    AsyncValue<List<Topic>>,
    ({String subjectId, String chapterId})>((ref, params) {
  final raw = ref.watch(_rawTopicsStreamProvider(params));
  final mode = ref.watch(syllabusSortProvider);
  return raw.whenData((list) {
    final copy = List<Topic>.from(list);
    sortTopics(copy, mode);
    return copy;
  });
});

// ---------------------------------------------------------------------------
// Completion helpers
// ---------------------------------------------------------------------------

int chapterCompletion(Chapter chapter, List<Topic> topics) {
  if (topics.isEmpty) return chapter.progress;
  final done = topics.where((t) => t.isComplete).length;
  return ((done / topics.length) * 100).round();
}

int subjectCompletion(List<int> chapterCompletions) {
  if (chapterCompletions.isEmpty) return 0;
  final done = chapterCompletions.where((c) => c >= 100).length;
  return ((done / chapterCompletions.length) * 100).round();
}
