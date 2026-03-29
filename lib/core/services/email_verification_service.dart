import 'package:cloud_functions/cloud_functions.dart';

/// Email verification service using Firebase Cloud Functions + Resend API
/// 
/// This service calls Firebase Cloud Functions which securely store the Resend API key.
/// The API key is never exposed in the client app, making it safe for distribution.
class EmailVerificationService {
  static final _functions = FirebaseFunctions.instance;

  /// Send verification email to user
  /// 
  /// Calls Firebase Cloud Function which handles Resend API communication
  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String userName,
    required String verificationLink,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendVerificationEmail');
      final result = await callable.call({
        'email': toEmail,
        'userName': userName,
        'verificationLink': verificationLink,
      });

      return result.data['success'] == true;
    } catch (e) {
      print('Error sending verification email: $e');
      return false;
    }
  }

  /// Send password reset email
  /// 
  /// Calls Firebase Cloud Function which handles Resend API communication
  static Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String userName,
    required String resetLink,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendPasswordResetEmail');
      final result = await callable.call({
        'email': toEmail,
        'userName': userName,
        'resetLink': resetLink,
      });

      return result.data['success'] == true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

}
