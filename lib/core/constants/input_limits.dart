/// Upper bounds for user-editable strings (Firestore abuse / oversized-field guard).
abstract final class InputLimits {
  static const int examName = 200;
  static const int mockTestTitle = 200;
  static const int displayName = 120;
}
