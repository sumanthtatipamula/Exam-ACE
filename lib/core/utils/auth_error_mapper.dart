import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

String friendlyAuthError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'wrong-password' =>
        'Incorrect email or password. Please try again.',
      'invalid-credential' => e.message?.isNotEmpty == true
          ? e.message!
          : 'Incorrect email or password. Please try again.',
      'user-not-found' =>
        'No account found with this email. Please sign up first.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'email-already-in-use' =>
        'This email is already registered. Sign in with that account, or use a different email.',
      'weak-password' => 'Password is too weak. Please choose a stronger one.',
      'invalid-email' => 'Please enter a valid email address.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      'requires-recent-login' =>
        'For security, please sign out, sign in again, then try this action.',
      'operation-not-allowed' =>
        e.message ?? 'This sign-in method is not allowed or is misconfigured.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  if (e is PlatformException) {
    final msg = e.message ?? '';
    // Google Sign-In on Android: ApiException 10 = DEVELOPER_ERROR (SHA-1 / OAuth not set up).
    if (e.code == 'sign_in_failed' &&
        (msg.contains('10:') || msg.contains('DEVELOPER_ERROR'))) {
      return 'Google Sign-In is not set up for this build. In Firebase Console, add your '
          'Android SHA-1 fingerprint, download a new google-services.json, rebuild, or use '
          '--dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com';
    }
    if (msg.isNotEmpty) return msg;
    return 'Sign-in failed. Please try again.';
  }
  if (e is Exception) {
    return e.toString();
  }
  return 'Something went wrong. Please try again.';
}
