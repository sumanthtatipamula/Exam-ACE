import 'package:firebase_auth/firebase_auth.dart';

String friendlyAuthError(Exception e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'wrong-password' || 'invalid-credential' =>
        'Incorrect email or password. Please try again.',
      'user-not-found' =>
        'No account found with this email. Please sign up first.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'email-already-in-use' =>
        'An account already exists with this email.',
      'weak-password' => 'Password is too weak. Please choose a stronger one.',
      'invalid-email' => 'Please enter a valid email address.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      'requires-recent-login' =>
        'For security, please sign out, sign in again, then try this action.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}
