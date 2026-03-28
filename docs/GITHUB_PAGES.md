# GitHub Pages (privacy policy)

This folder powers a **public privacy policy page** for Google Play / App Store.

## Enable Pages

1. Push the `docs/` folder to GitHub (including `index.html` and `.nojekyll`).
2. In the repo on GitHub: **Settings → Pages**.
3. Under **Build and deployment**:
   - **Source:** Deploy from a branch.
   - **Branch:** `main` (or your default branch).
   - **Folder:** `/docs` → **Save**.

After a minute, the site is live. **This project’s policy URL:**

**https://sumanthtatipamula.github.io/Exam-ACE/**

Use that in **Play Console → Privacy policy** and in the app ([`lib/core/constants/legal_urls.dart`](../lib/core/constants/legal_urls.dart)).

## App build

The default privacy URL is already set in code. Optional override:

```bash
flutter build appbundle --dart-define=PRIVACY_POLICY_URL=https://sumanthtatipamula.github.io/Exam-ACE/
```

## Updates

- Edit **`docs/index.html`** when the policy changes (and keep **`PRIVACY.md`** at the repo root aligned for developers).
## Notes

- **`.nojekyll`** disables Jekyll so GitHub serves plain HTML as-is.
- If you use a **custom domain**, add it under Pages settings and optionally add `docs/CNAME`.
