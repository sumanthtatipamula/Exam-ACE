import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_storage/firebase_storage.dart';

/// Deletes all app data under [users/{uid}] in Firestore and files under
/// [users/{uid}/] in Storage. Does not delete the Firebase Auth user.
class UserDataCleanupService {
  UserDataCleanupService(
    this._firestore,
    this._storage,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> deleteAllDataForUser(String uid) async {
    final userRef = _userRef(uid);

    await _deleteCollectionInBatches(userRef.collection('tasks'));
    await _deleteCollectionInBatches(userRef.collection('daySnapshots'));
    await _deleteCollectionInBatches(userRef.collection('carryToToday'));
    await _deleteCollectionInBatches(userRef.collection('mockTests'));
    await _deleteCollectionInBatches(userRef.collection('examScores'));

    await _deleteSubjectsTree(userRef);

    await _deleteStorageUnderUser(uid);

    final snap = await userRef.get();
    if (snap.exists) {
      await userRef.delete();
    }
  }

  Future<void> _deleteSubjectsTree(
    DocumentReference<Map<String, dynamic>> userRef,
  ) async {
    final subjects = await userRef.collection('subjects').get();
    for (final subj in subjects.docs) {
      final chapters = await subj.reference.collection('chapters').get();
      for (final ch in chapters.docs) {
        await _deleteCollectionInBatches(ch.reference.collection('topics'));
        await ch.reference.delete();
      }
      await subj.reference.delete();
    }
  }

  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snap = await col.limit(500).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteStorageUnderUser(String uid) async {
    final root = _storage.ref('users/$uid');
    try {
      await _deleteStorageRefRecursive(root);
    } on FirebaseException catch (_) {
      // Bucket or path may be empty / missing rules — continue.
    }
  }

  Future<void> _deleteStorageRefRecursive(Reference ref) async {
    final list = await ref.listAll();
    for (final item in list.items) {
      try {
        await item.delete();
      } on FirebaseException catch (_) {}
    }
    for (final prefix in list.prefixes) {
      await _deleteStorageRefRecursive(prefix);
    }
  }
}
