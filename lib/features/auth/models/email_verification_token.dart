import 'package:cloud_firestore/cloud_firestore.dart';

/// Email verification token stored in Firestore
/// Tokens expire after 24 hours
class EmailVerificationToken {
  final String email;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;

  EmailVerificationToken({
    required this.email,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.used = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !used && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'token': token,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': used,
    };
  }

  factory EmailVerificationToken.fromMap(Map<String, dynamic> map) {
    return EmailVerificationToken(
      email: map['email'] as String,
      token: map['token'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      used: map['used'] as bool? ?? false,
    );
  }
}
