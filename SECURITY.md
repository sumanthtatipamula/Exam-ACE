# Security notes

- **Firestore / Storage rules** live in `firestore.rules` and `storage.rules`. Deploy after any change: `firebase deploy --only firestore:rules,storage`.
- **User data** is isolated under `users/{uid}/**`; only that authenticated user may read or write (see rules).
- **Firebase config is not committed.** Real keys live only in ignored files on your machine:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`  
  Copy the matching `*.example` files, then run **`flutterfire configure`** (recommended) or paste values from [Firebase Console](https://console.firebase.google.com/) → Project settings. Restrict keys with [Firebase App Check](https://firebase.google.com/docs/app-check) for production builds.
- **Secrets**: do not commit keystores, `key.properties`, or `.env` files (see `.gitignore`).

### First-time setup after clone

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
# Then run: dart pub global activate flutterfire_cli && flutterfire configure
# Or replace placeholders in the three files from Firebase Console.
```
