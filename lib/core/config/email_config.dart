/// Email service configuration
/// 
/// IMPORTANT: Never commit API keys to version control.
/// Set RESEND_API_KEY as an environment variable or use secure storage.
class EmailConfig {
  /// Resend API key - should be loaded from environment or secure storage
  /// For development: Set as environment variable
  /// For production: Use Firebase Remote Config or similar
  static const String resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: '', // Empty default - must be provided at build time
  );

  static const String resendApiUrl = 'https://api.resend.com/emails';
  
  /// Your verified sender email (must be configured in Resend dashboard)
  static const String fromEmail = 'noreply@examace.app'; // Update with your domain
  static const String fromName = 'Exam Ace';

  /// Validate configuration
  static bool get isConfigured => resendApiKey.isNotEmpty;
}
