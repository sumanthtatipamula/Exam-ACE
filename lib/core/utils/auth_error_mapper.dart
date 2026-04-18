import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Support email shown in user-facing error messages that require manual help.
const String kSupportEmail = 'support@examace.app';

String friendlyAuthError(Object e) {
  // Handle Cloud Functions errors first
  if (e is FirebaseFunctionsException) {
    // Try to extract the actual error message from details
    final details = e.details;
    if (details != null && details is String && details.isNotEmpty) {
      return details;
    }
    // Fall back to message
    final message = e.message;
    if (message != null && message.isNotEmpty && message != 'INTERNAL') {
      return message;
    }
    // If we only have INTERNAL, return a generic message
    return 'Something went wrong. Please try again.';
  }
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'wrong-password' =>
        'Incorrect email or password. Please try again.',
      'invalid-credential' => e.message?.isNotEmpty == true
          ? e.message!
          : 'Incorrect email or password. Please try again.',
      'user-not-found' =>
        'No account found with this email. Please sign up first.',
      'user-disabled' =>
        'This account has been disabled. Contact $kSupportEmail for help.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'email-already-in-use' =>
        'This email is already registered. Sign in with that account, or use a different email.',
      'weak-password' => 'Password is too weak. Please choose a stronger one.',
      'invalid-email' => 'Please enter a valid email address.',
      'network-request-failed' =>
        'Network error. Please check your internet connection and try again.',
      'requires-recent-login' =>
        'For security, please sign out, sign in again, then try this action.',
      'operation-not-allowed' =>
        e.message ?? 'This sign-in method is not allowed or is misconfigured.',
      'account-exists-with-different-credential' =>
        'An account already exists with the same email but a different sign-in method. '
            'Try signing in with email/password or the provider you used before.',
      'credential-already-in-use' =>
        'This credential is already linked to a different account.',
      'user-token-expired' =>
        'Your session has expired. Please sign in again.',
      'web-context-cancelled' =>
        'Sign-in was cancelled. Please try again.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  if (e is PlatformException) {
    final msg = e.message ?? '';
    // Google Sign-In on Android: ApiException 10 = DEVELOPER_ERROR (SHA-1 / OAuth not set up).
    if (e.code == 'sign_in_failed') {
      if (msg.contains('10:') || msg.contains('DEVELOPER_ERROR')) {
        return 'Google Sign-In configuration error. Please ensure your app is '
            'set up correctly in the Firebase Console (SHA-1 fingerprint). '
            'If this persists, contact $kSupportEmail.';
      }
      if (msg.contains('12500') || msg.contains('SIGN_IN_CANCELLED')) {
        return 'Google Sign-In was cancelled. Please try again.';
      }
      if (msg.contains('7:') || msg.contains('NETWORK_ERROR')) {
        return 'Network error during Google Sign-In. Please check your internet connection.';
      }
      if (msg.contains('12501')) {
        return 'Google Sign-In was cancelled by the user.';
      }
      if (msg.contains('12502')) {
        return 'A Google Sign-In attempt is already in progress. Please wait and try again.';
      }
      return 'Google Sign-In failed. Please check your internet connection '
          'and try again. If the problem persists, try signing in with email instead.';
    }
    if (msg.isNotEmpty) return msg;
    return 'Sign-in failed. Please try again.';
  }
  // Network-level errors (e.g. no internet before Firebase SDK is reached)
  if (e is SocketException) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (e is Exception) {
    final errorString = e.toString();
    // Extract error message from Cloud Functions errors
    // Format: "Exception: Error message here"
    if (errorString.startsWith('Exception: ')) {
      final message = errorString.substring('Exception: '.length);
      // Clean up common prefixes
      if (message.startsWith('[firebase_functions/internal] ')) {
        return message.substring('[firebase_functions/internal] '.length);
      }
      if (message.startsWith('[firebase_functions/')) {
        // Extract just the message part after the error code
        final parts = message.split('] ');
        if (parts.length > 1) {
          return parts[1];
        }
      }
      return message;
    }
    return errorString;
  }
  return 'Something went wrong. Please try again.';
}
