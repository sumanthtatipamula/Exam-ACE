import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/mock_test/models/mock_test.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final mockTestRepositoryProvider = Provider<MockTestRepository>((ref) {
  return MockTestRepository();
});

class MockTestRepository {
  final _firestore = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col() =>
      _firestore.collection('users').doc(_uid).collection('mockTests');

  Stream<List<MockTest>> watchAll() {
    return _col()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MockTest.fromMap(d.id, d.data())).toList());
  }

  Future<void> add(MockTest test) async {
    await _col().add(test.toMap());
  }

  Future<void> update(MockTest test) =>
      _col().doc(test.id).update(test.toMap());

  Future<void> delete(String testId) => _col().doc(testId).delete();
}

// ---------------------------------------------------------------------------
// Stream provider
// ---------------------------------------------------------------------------

final mockTestsStreamProvider = StreamProvider<List<MockTest>>((ref) {
  return streamWhenSignedIn(
    ref,
    <MockTest>[],
    () => ref.watch(mockTestRepositoryProvider).watchAll(),
  );
});

/// Mock tests linked to a subject (subject-, chapter-, or topic-level links).
final mockTestsForSubjectProvider =
    Provider.family<List<MockTest>, String>((ref, subjectId) {
  final all = ref.watch(mockTestsStreamProvider).valueOrNull ?? [];
  final list =
      all.where((t) => t.linkedSubjectId == subjectId).toList();
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});

/// Mock tests linked to a specific chapter (includes topic-linked tests in that chapter).
final mockTestsForChapterProvider = Provider.family<
    List<MockTest>,
    ({String subjectId, String chapterId})>((ref, params) {
  final all = ref.watch(mockTestsStreamProvider).valueOrNull ?? [];
  final list = all
      .where((t) =>
          t.linkedSubjectId == params.subjectId &&
          t.linkedChapterId == params.chapterId)
      .toList();
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});
