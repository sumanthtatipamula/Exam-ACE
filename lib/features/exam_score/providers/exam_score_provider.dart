import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/exam_score/models/exam_score.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository();
});

class ExamRepository {
  final _firestore = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col() =>
      _firestore.collection('users').doc(_uid).collection('examScores');

  Stream<List<Exam>> watchAll() {
    return _col()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Exam.fromMap(d.id, d.data())).toList());
  }

  Future<void> add(Exam row) async {
    await _col().add(row.toMap());
  }

  Future<void> update(Exam row) => _col().doc(row.id).update(row.toMap());

  Future<void> delete(String id) => _col().doc(id).delete();
}

final examsStreamProvider = StreamProvider<List<Exam>>((ref) {
  return streamWhenSignedIn(
    ref,
    <Exam>[],
    () => ref.watch(examRepositoryProvider).watchAll(),
  );
});
