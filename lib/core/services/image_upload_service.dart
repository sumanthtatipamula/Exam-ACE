import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  ImageUploadService._();

  static final _picker = ImagePicker();
  static final _storage = FirebaseStorage.instance;

  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) {
    return _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
  }

  /// Firebase Storage path segments must not contain `# [ ] * / \`.
  static String _sanitizeSegment(String s) {
    return s
        .replaceAll(RegExp(r'[#\[\]*\\/]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Prefer [XFile.readAsBytes] over [File] — on Android the picked path is
  /// often not readable as a local file (scoped storage), which breaks `putFile`.
  ///
  /// Await the [UploadTask] and call [getDownloadURL] on [TaskSnapshot.ref] so
  /// the object is finalized before resolving the URL — avoids
  /// `storage/object-not-found` from racing or stale refs.
  static Future<String> _uploadXFile(Reference ref, XFile file, String ext) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError(
        'Could not read image data (empty file). Try another photo or pick again.',
      );
    }
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeForExtension(ext)),
    );
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  static String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Extension from path; falls back to MIME; default `jpg`.
  static String _inferExtension(XFile file) {
    final path = file.path;
    if (path.contains('.')) {
      final last = path.split('.').last.toLowerCase();
      if (last.length <= 5 && !last.contains('/') && !last.contains(r'\')) {
        return last;
      }
    }
    final mime = file.mimeType?.toLowerCase() ?? '';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('gif')) return 'gif';
    if (mime.contains('heic') || mime.contains('heif')) return 'heic';
    return 'jpg';
  }

  static Future<String> uploadSubjectImage(String subjectName, XFile file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ext = _inferExtension(file);
    final safeName = _sanitizeSegment(subjectName);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('users/$uid/subjects/${ts}_$safeName.$ext');
    return _uploadXFile(ref, file, ext);
  }

  static Future<String> uploadProfilePhoto(XFile file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ext = _inferExtension(file);
    final ref = _storage.ref('users/$uid/profile/avatar.$ext');
    return _uploadXFile(ref, file, ext);
  }

  /// Deletes a file in Firebase Storage given its download URL. No-op if [downloadUrl]
  /// is empty, or if it is not a Firebase Storage URL (e.g. Google account photo).
  static Future<void> deleteFirebaseStorageDownloadUrl(String downloadUrl) async {
    final u = downloadUrl.trim();
    if (u.isEmpty) return;
    if (!u.contains('firebasestorage.googleapis.com')) return;
    try {
      await _storage.refFromURL(u).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    } on Object {
      // refFromURL invalid for non-Storage URLs — intentional no-op.
    }
  }
}
