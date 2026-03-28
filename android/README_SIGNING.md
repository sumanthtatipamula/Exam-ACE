# Android release signing (Google Play)

Release builds use `key.properties` plus an upload keystore. Those files stay **local** and are listed in the repo root `.gitignore`.

## One-time setup

1. Generate a keystore (run from this `android/` directory):

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy the template and fill in passwords and paths:

   ```bash
   cp key.properties.example key.properties
   ```

3. Build the App Bundle:

   ```bash
   cd .. && flutter build appbundle
   ```

4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

5. **Deobfuscation:** Release builds currently have **R8 minify disabled** (see comment in `android/app/build.gradle.kts`) so we can ship **modular Play libraries** compatible with **targetSdk 34+** without the deprecated `com.google.android.play:core:1.x` artifact. If you re-enable minify later, you’ll need a Java mapping file at `build/app/outputs/mapping/release/mapping.txt` for Play crash deobfuscation.

Back up `upload-keystore.jks` and `key.properties` (or the passwords) in a safe place. Enable [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756) so Google can rotate keys if needed.
