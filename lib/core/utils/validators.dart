final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

final _specialCharRegex =
    RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]');

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter your email';
  if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
  return null;
}

String? validatePasswordStrength(String? value) {
  if (value == null || value.isEmpty) return 'Enter a password';
  if (value.length < 8) return 'At least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Include at least one uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Include at least one lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Include at least one number';
  }
  if (!_specialCharRegex.hasMatch(value)) {
    return 'Include at least one special character';
  }
  return null;
}

String? validateRequired(String? value, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) return '$fieldName is required';
  return null;
}

/// Rejects strings longer than [max] (after trim). Use for Firestore text fields.
String? validateMaxLength(String? value, int max, String fieldLabel) {
  if (value == null) return null;
  if (value.trim().length > max) {
    return '$fieldLabel must be at most $max characters';
  }
  return null;
}

int passwordStrengthScore(String password) {
  if (password.isEmpty) return 0;
  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password)) {
    score++;
  }
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (_specialCharRegex.hasMatch(password)) score++;
  return score;
}
