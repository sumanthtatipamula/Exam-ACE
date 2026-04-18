/// Optional overrides for federated sign-in. See comments on each constant.
///
/// **Google (Android):** If `android/app/google-services.json` has `"oauth_client": []`,
/// add your debug/release **SHA-1** in Firebase Console → Project settings → Android app,
/// download a new `google-services.json`, then rebuild. Alternatively pass the **Web client ID**
/// (OAuth 2.0 client of type “Web application” from Google Cloud Console → Credentials for the
/// same Firebase project):
///
/// `flutter run --dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=xxxxx.apps.googleusercontent.com`

const String kGoogleSignInWebClientId = String.fromEnvironment(
  'GOOGLE_SIGN_IN_WEB_CLIENT_ID',
  defaultValue: '733539721297-co07j15ubrki9jmqt2nvq486spfcutei.apps.googleusercontent.com',
);
