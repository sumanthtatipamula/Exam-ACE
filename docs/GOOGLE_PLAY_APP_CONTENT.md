# Google Play — App content & policy declarations (Exam Ace)

This guide maps **[Play Console → Policy and programs → App content](https://support.google.com/googleplay/android-developer/answer/9859455)** (“Prepare your app for review”) to **Exam Ace**. It complements [PLAY_STORE_RELEASE.md](PLAY_STORE_RELEASE.md) and [PRIVACY.md](../PRIVACY.md). Official help: Google’s *Prepare your app for review* / *App content* articles.

---

## 1. Privacy policy

**Requirement:** A working **HTTPS** URL on the store listing + disclosures consistent with the app (and in-app link if you access sensitive data).

| Field | What to enter |
|--------|----------------|
| **Privacy policy URL** | `https://sumanthtatipamula.github.io/Exam-ACE/` |

**In-app:** Profile → **Privacy policy** (same URL via [`lib/core/constants/legal_urls.dart`](../lib/core/constants/legal_urls.dart)).

Keep [PRIVACY.md](../PRIVACY.md) and [docs/index.html](index.html) aligned with what you declare in **Data safety** (below).

---

## 2. Ads

**Requirement:** Declare whether the app shows **ads** (third-party ad SDKs, banners, interstitials, native ads, “house ads” that look like ads).

**Exam Ace:** There is **no** ad SDK in [`pubspec.yaml`](../pubspec.yaml) (no AdMob, Meta Audience Network, etc. in dependencies).

| Answer | Use |
|--------|-----|
| **Does your app contain ads?** | **No** |

If you add ads later, switch to **Yes**, update the store listing label, and update this doc and your privacy policy.

---

## 3. App access (for Google reviewers)

**Requirement:** If the app or parts of it need **sign-in**, you must provide instructions (and credentials if needed) so reviewers can access the app. Play may state that reviewers **cannot** create new accounts, use free trials, or contact you for details—so a **working test login** is essential.

**Exam Ace:** Core features require a **Firebase account** (email/password or Google Sign‑In).

### Up to 5 instruction sets

You can add **up to five** separate instruction blocks (e.g. different flows or languages). For Exam Ace, **one** block is usually enough: steps + email/password. Use extra slots only if you need a separate note (for example, optional **Sign in with Google** using a dedicated test Google account).

### “Allow Android to use the credentials…” (performance & compatibility testing)

Play may show an option to **allow Android to use the credentials you provide for performance and app compatibility testing**. That is **separate from manual policy review**: it lets Google’s **automated** tests use your supplied login on more devices/versions to improve compatibility signals.

- **Typical choice:** **Enable** it if you use a **dedicated test account** with no real user data and no payment methods attached—same account you put in the instructions.
- **Skip or disable** if you are uncomfortable sharing credentials with automated tests (you can still pass review with manual instructions only; pre-launch/automated coverage may be weaker).

### Suggested text to paste in Play Console (edit credentials)

```text
Exam Ace requires sign-in; the main app is only available after login.

Test account (email / password):
Email: [YOUR_TEST_EMAIL@example.com]
Password: [YOUR_TEST_PASSWORD]

Steps: Open the app → on the sign-in screen, enter the email and password above → sign in.

Ensure this user is allowed to sign in in Firebase (if email verification is required, verify this address in advance or adjust Firebase settings for testing).

No subscription, invite code, or location gate is required after sign-in.
```

Replace bracketed values with a **dedicated test account** you control. Do **not** commit real passwords in the git repo—only store them in Play Console.

---

## 4. Target audience and content

**Requirement:** Declare who the app is for. Children’s apps trigger **Families** and extra rules.

**Exam Ace** [PRIVACY.md](../PRIVACY.md) states the app is **not directed at children under 13**.

| Topic | Suggested approach |
|--------|---------------------|
| **Target age** | Declare an audience that **does not** include children under 13 if that matches your listing and marketing, or follow the questionnaire honestly. |
| **Content** | Education / productivity style; no user-generated public feeds in the app. |

If Play asks about **UGC** or **social features**, Exam Ace stores **private** user data only (no public posts or chat between users in the typical sense).

---

## 5. Sensitive permissions & declaration forms

**Google:** High-risk permissions (e.g. **SMS**, **Call Log**) may require extra forms.

**Exam Ace (Android manifest)** uses:

| Permission | Typical Play handling |
|------------|------------------------|
| `POST_NOTIFICATIONS` | Runtime on Android 13+; declare in **Data safety** (messages / reminders). |
| `CAMERA` | For optional profile/subject photos; declare in **Data safety** (photos). |

**Not used:** SMS, Call Log, precise location as a core permission, etc.

Complete any **Permissions declaration** prompts in Play Console truthfully after you upload your **App Bundle** (Play may ask based on merged manifest).

---

## 6. Data safety (privacy and security practices)

**Requirement:** “Tell us about your app’s privacy and security practices” — a structured form in Play Console.

Align answers with [PRIVACY.md](../PRIVACY.md).

**Account / data deletion URL (Data safety):** When Play asks for a link to request account and data deletion, use:

`https://sumanthtatipamula.github.io/Exam-ACE/#account-deletion`

That page includes in-app steps and a **mailto** link for email requests. The app also surfaces it under Profile → **Request data deletion** ([`kAccountDeletionRequestUrl`](../lib/core/constants/legal_urls.dart)). Deploy `docs/index.html` to GitHub Pages when you change the policy.

**Typical categories:**

- **Data collected:** Account info (email, name), user-generated content (tasks, notes, scores), photos if uploaded, diagnostics if any (Firebase operational data is governed by Google’s policies).
- **Purpose:** App functionality, account management.
- **Sharing:** Processed by **Google** (Firebase / Sign-In) as described in your policy.
- **Security:** Data transmitted over **HTTPS**; access scoped by account in Firebase.

Update the form whenever you add new SDKs or data types.

---

## 7. Content ratings

**Requirement:** Complete the **IARC / rating questionnaire** so the app is not listed as “Unrated.”

Choose categories that match **education / study / productivity** (not games unless you list it as such).

---

## 8. COVID-19 contact tracing / status

**Exam Ace:** **No** COVID-19 contact tracing or status features.

---

## 9. News and Magazine apps

**Exam Ace:** **Not** a News or Magazine app (it’s a personal study tracker).

---

## 10. Misleading claims & “government information” (store listing)

If Play flags **Misleading Claims** or **missing source links for government information**, ensure the **full description** (and in-app **About**) state clearly that:

1. **Exam Ace is not a government app** and does not represent a government entity.
2. The app is a **personal planner** — it does **not** republish official notifications, syllabi, or rules; users enter their own content.
3. **Official HTTPS sources** for authentic exam information are listed (e.g. `https://upsc.gov.in`, `https://ssc.gov.in`, `https://indianrailways.gov.in`, `https://www.india.gov.in`).

**Source of truth for listing text:** copy from **[play_store_full_description.txt](play_store_full_description.txt)** into **Play Console → Grow → Main store listing → Full description** whenever you update it. The in-app **About** screen includes a matching disclaimer and tappable links to those sites.

---

## 11. “Needs attention” vs “Actioned”

Play Console shows **Needs attention** until required declarations are completed. **Actioned** means submitted—review periodically and keep **App content** + **Data safety** + **Privacy policy** in sync with app updates.

---

## Quick checklist

- [ ] Privacy policy URL saved and site loads.
- [ ] Ads = **No** (unless you add ads).
- [ ] App access instructions + test account (if applicable).
- [ ] Target audience consistent with [PRIVACY.md](../PRIVACY.md).
- [ ] Data safety completed to match policy.
- [ ] Content ratings questionnaire done.
- [ ] COVID-19 = No; News app = No.
- [ ] Full description matches **play_store_full_description.txt** (disclaimer + official `.gov` links).
- [ ] Consult a lawyer for legal compliance; this doc is **not** legal advice.
