import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return ref.watch(mockTestRepositoryProvider).watchAll();
});
