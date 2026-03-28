import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:exam_ace/core/config/social_auth_config.dart';
import 'package:exam_ace/core/services/user_data_cleanup_service.dart';

export 'package:exam_ace/core/utils/auth_error_mapper.dart' show friendlyAuthError;

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final userDataCleanupServiceProvider = Provider<UserDataCleanupService>((ref) {
  return UserDataCleanupService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// User-scoped Firestore streams must not run while signed out: a lingering
/// listener could still target `users/{oldUid}/...` after sign-in as another user.
Stream<T> streamWhenSignedIn<T>(
  Ref ref,
  T emptyValue,
  Stream<T> Function() stream,
) {
  if (ref.watch(authStateProvider).valueOrNull?.uid == null) {
    return Stream.value(emptyValue);
  }
  return stream();
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(userDataCleanupServiceProvider),
  );
});

class AuthService {
  final FirebaseAuth _auth;
  final UserDataCleanupService _cleanup;

  /// Single instance so [signOut] clears the same session [signInWithGoogle] created.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId:
        kGoogleSignInWebClientId.isEmpty ? null : kGoogleSignInWebClientId,
  );

  AuthService(this._auth, this._cleanup);

  /// Deletes all Firestore + Storage data for the current user, then deletes
  /// the Firebase Auth account and signs out. **Cannot be undone.**
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await _cleanup.deleteAllDataForUser(user.uid);
    await user.delete();
    await signOut();
  }

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  bool get isEmailPasswordUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Creates an email/password account. Firebase rejects duplicate emails with
  /// [FirebaseAuthException] code `email-already-in-use` (including when the
  /// same address exists via Google if “one account per email” is enabled).
  Future<UserCredential> signUpWithEmail(
      String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message:
            'Google Sign-In did not return tokens. For Android: add your app’s SHA-1 in '
            'Firebase Console, replace google-services.json, and rebuild; or run with '
            '--dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=<web_client_id>.apps.googleusercontent.com',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('No authenticated user');
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    // Email users never used Google; sign-out can throw on Android if no session.
    try {
      await _googleSignIn.signOut();
    } on Object {
      // No Google session, or platform SDK quirk — safe to ignore before Firebase sign-out.
    }
    await _auth.signOut();
  }
}
