/// Legal URLs for store compliance (Play / App Store).
///
/// **Privacy policy** — public page (GitHub Pages):
/// https://sumanthtatipamula.github.io/Exam-ACE/
///
/// Override per build if needed:
/// `--dart-define=PRIVACY_POLICY_URL=https://...`
const String kPrivacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: 'https://sumanthtatipamula.github.io/Exam-ACE/',
);

/// Web anchor for account/data deletion (store listings, Data safety form).
///
/// Override: `--dart-define=ACCOUNT_DELETION_REQUEST_URL=https://...#account-deletion`
const String kAccountDeletionRequestUrl = String.fromEnvironment(
  'ACCOUNT_DELETION_REQUEST_URL',
  defaultValue:
      'https://sumanthtatipamula.github.io/Exam-ACE/#account-deletion',
);
