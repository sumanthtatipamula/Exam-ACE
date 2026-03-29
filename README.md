# Exam Ace

Exam prep tracker for **Flutter** — syllabus, daily tasks, mock tests, and real exam attempts in one place. Built for aspirants preparing for government and competitive exams (e.g. SSC, UPSC, banking, railways, state PSCs).

## Features

- **Home** — week-at-a-glance surf chart, task board, streaks, and configurable week completion metrics
- **Syllabus** — subjects, chapters, topics, notes, and progress
- **Mocks & exams** — log scores, link attempts to syllabus, and view trends
- **Calendar** — history of what you completed on each day
- **Profile** — theme (light / dark / system), color accent presets, week-% formula (Simple / Strong / Strict), reminders

Settings persist locally via **SharedPreferences** (theme, formula, accent).

📖 **For detailed feature documentation, see [FEATURES.md](FEATURES.md)**

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
flutter build apk    # Android quick install
flutter build appbundle   # Android — required for Google Play (.aab)
flutter build ios      # iOS (on macOS)
```

Use your own signing keys for store releases; do not commit `key.properties`, `.jks`, or `.keystore` (see `.gitignore`).

### Google Play

1. **[docs/PLAY_STORE_RELEASE.md](docs/PLAY_STORE_RELEASE.md)** — signing, version codes, Data safety, privacy URL.
2. **[docs/GOOGLE_PLAY_APP_CONTENT.md](docs/GOOGLE_PLAY_APP_CONTENT.md)** — Play Console **App content** checklist (privacy policy, ads, reviewer access, target audience, permissions, content ratings, COVID-19, news/magazine) aligned with Exam Ace.
3. Copy **`android/key.properties.example`** → **`android/key.properties`** and point `storeFile` at your upload keystore.
4. Production bundle — privacy URL is set in code ([`lib/core/constants/legal_urls.dart`](lib/core/constants/legal_urls.dart)). Optional override:

   ```bash
   flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://sumanthtatipamula.github.io/Exam-ACE/
   ```

5. **Privacy policy (live):** [https://sumanthtatipamula.github.io/Exam-ACE/](https://sumanthtatipamula.github.io/Exam-ACE/) — paste this **exact URL** into **Google Play Console → App content → Privacy policy**. Profile → **Privacy policy** in the app opens the same link. Keep **[PRIVACY.md](PRIVACY.md)** and **`docs/index.html`** in sync when you change the policy, then push so GitHub Pages updates.

## Web-based email verification & password reset

Email verification and password reset are handled **in the browser** — no dependency on deep links.

- **Verify email:** `https://examace.sumanthtatipamula.com/verify-email?token=...`
- **Reset password:** `https://examace.sumanthtatipamula.com/reset-password?token=...`

These pages are served by **Firebase Hosting** with a custom domain (`examace.sumanthtatipamula.com`) and call Cloud Function HTTP endpoints (`verifyEmailTokenHttp`, `resetPasswordHttp`) via hosting rewrites. The pages use **Tailwind CSS** for responsive design across all devices.

To deploy hosting + functions:

```bash
firebase deploy --only functions,hosting
```

See **[FIREBASE_FUNCTIONS_SETUP.md](FIREBASE_FUNCTIONS_SETUP.md)** for full details.

## Project layout (high level)

| Path | Purpose |
|------|---------|
| `lib/app.dart`, `lib/main.dart` | App entry, routing, deep link handling |
| `lib/core/` | Theme, settings, router, utilities |
| `lib/features/` | Feature screens (auth, home, subjects, mocks, exams, profile, …) |
| `functions/index.js` | Firebase Cloud Functions (email, verification, reset) |
| `public/` | Firebase Hosting static pages (verify-email, reset-password) |
| `firebase.json` | Hosting rewrites, functions config |
| `firestore.rules`, `storage.rules` | Firebase security rules |

## Week % modes (headline metric)

The ribbon % on Home can use three formulas — **Simple** (plain average), **Strong** (cubic mean — rewards high completion per task), **Strict** (weakest day sets the week). Details and formulas: **About** in the app or `lib/core/settings/metric_formula_mode.dart` / `lib/core/utils/metric_formulas.dart`.

## License

This project is licensed under the [MIT License](LICENSE). The package is not published to pub.dev (`publish_to: 'none'` in `pubspec.yaml`). Update the copyright line in `LICENSE` if you fork or rebrand.
