# Exam Ace

Exam prep tracker for **Flutter** — syllabus, daily tasks, mock tests, and real exam attempts in one place. Built for aspirants preparing for government and competitive exams (e.g. SSC, UPSC, banking, railways, state PSCs).

## Features

- **Home** — week-at-a-glance surf chart, task board, streaks, and configurable week completion metrics
- **Syllabus** — subjects, chapters, topics, notes, and progress
- **Mocks & exams** — log scores, link attempts to syllabus, and view trends
- **Calendar** — history of what you completed on each day
- **Profile** — theme (light / dark / system), color accent presets, week-% formula (Simple / Strong / Strict), reminders

Settings persist locally via **SharedPreferences** (theme, formula, accent).

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel), Dart **^3.10**
- Xcode (iOS) and/or Android Studio / SDK (Android) for device builds

## Firebase setup (required)

Real Firebase config files are **not** in this repo. After cloning:

1. Copy the templates and fill them using the [Firebase Console](https://console.firebase.google.com/) or FlutterFire CLI:

   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   cp android/app/google-services.json.example android/app/google-services.json
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   ```

2. **Recommended:** install the FlutterFire CLI and run:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   That overwrites the three files above with values for your Firebase project.

See **[SECURITY.md](SECURITY.md)** for rules, App Check, and what must stay out of git.

## Run the app

```bash
flutter pub get
flutter run
```

Optional Google Sign-In Web client ID on Android (if needed):

```bash
flutter run --dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=your-id.apps.googleusercontent.com
```

## Build release

```bash
flutter build apk    # Android
flutter build ios      # iOS (on macOS)
```

Use your own signing keys for store releases; do not commit `key.properties`, `.jks`, or `.keystore` (see `.gitignore`).

## Project layout (high level)

| Path | Purpose |
|------|---------|
| `lib/app.dart`, `lib/main.dart` | App entry, routing |
| `lib/core/` | Theme, settings, router, utilities |
| `lib/features/` | Feature screens (auth, home, subjects, mocks, exams, profile, …) |
| `firestore.rules`, `storage.rules` | Firebase security rules |

## Week % modes (headline metric)

The ribbon % on Home can use three formulas — **Simple** (plain average), **Strong** (cubic mean — rewards high completion per task), **Strict** (weakest day sets the week). Details and formulas: **About** in the app or `lib/core/settings/metric_formula_mode.dart` / `lib/core/utils/metric_formulas.dart`.

## License

This project is licensed under the [MIT License](LICENSE). The package is not published to pub.dev (`publish_to: 'none'` in `pubspec.yaml`). Update the copyright line in `LICENSE` if you fork or rebrand.
