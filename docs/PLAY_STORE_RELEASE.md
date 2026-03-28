# Google Play release checklist (Exam Ace)

Use this with [README.md](../README.md) and [PRIVACY.md](../PRIVACY.md).

## Before `flutter build appbundle`

1. **Signing** — Copy `android/key.properties.example` → `android/key.properties`. Create an upload keystore (see comments in the example), place the `.jks` next to `android/` or adjust `storeFile`. Enable **Play App Signing** in Play Console (recommended).

2. **Firebase** — Ensure `lib/firebase_options.dart`, `android/app/google-services.json`, and iOS plist exist locally (not committed). Release builds must point at your production Firebase project.

3. **Privacy policy URL (live):** [https://sumanthtatipamula.github.io/Exam-ACE/](https://sumanthtatipamula.github.io/Exam-ACE/) — enter this in **Play Console → App content → Privacy policy**. The app uses the same URL via [`lib/core/constants/legal_urls.dart`](../lib/core/constants/legal_urls.dart) (override with `--dart-define=PRIVACY_POLICY_URL=...` if needed). Keep [PRIVACY.md](../PRIVACY.md) and `docs/index.html` aligned when you edit the policy.

4. **Version** — Bump `version:` in `pubspec.yaml` (`1.0.1+2` = versionName `1.0.1`, versionCode `2`). Every Play upload needs a **higher versionCode**.

5. **Build App Bundle** (required for new apps on Play):
   ```bash
   flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://your.domain/privacy
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

## Store listing graphics (Play)

**Source art** (your hat-on-gradient PNG): place or replace  
[`docs/store_assets/source_app_icon_reference.png`](../docs/store_assets/source_app_icon_reference.png).  
`tools/generate_store_graphics.py` trims the dark border, crops a square, then builds launcher/icon sizes and the banner (one horizontal gradient from the square’s left/right; the **graduation cap** is composited on the left so the background stays continuous—not a second full icon tile):

| Asset | Path |
|-------|------|
| **App icon 512×512** (upload in Play) | `docs/store_assets/google_play_icon_512.png` |
| **Feature graphic 1024×500** | `docs/store_assets/google_play_feature_graphic_1024x500.png` |
| **Launcher source 1024×1024** | `assets/app_icon.png` (from source; used by `flutter_launcher_icons`) |

Regenerate:

```bash
python3 -m venv .venv_store_assets && . .venv_store_assets/bin/activate && pip install Pillow && python3 tools/generate_store_graphics.py
flutter pub get && dart run flutter_launcher_icons
```

## Play Console (after first upload)

- **App content** — Full walkthrough (privacy URL, ads, app access, target audience, permissions, ratings, COVID-19, news): **[GOOGLE_PLAY_APP_CONTENT.md](GOOGLE_PLAY_APP_CONTENT.md)** (mirrors Google’s *Prepare your app for review* / App content checklist for Exam Ace).
- **Data safety** — Declare data collected (account email, user content, Firebase, etc.) to match [PRIVACY.md](../PRIVACY.md).
- **Target audience** — If you do **not** target children under 13, say so consistently with [PRIVACY.md](../PRIVACY.md).

## Notes

- Release builds use **release signing** only when `android/key.properties` exists; otherwise they still use the debug key (fine for local `--release` tests, **not** for Play uploads).
- Do **not** commit `key.properties`, `.jks`, or `.keystore`.
