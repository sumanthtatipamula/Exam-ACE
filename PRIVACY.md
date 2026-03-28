# Privacy Policy — Exam Ace

**Last updated:** March 28, 2026  

**Published at:** https://sumanthtatipamula.github.io/Exam-ACE/ (GitHub Pages from `docs/index.html` in this repository.)

This policy describes how **Exam Ace** (“we”, “the app”) handles information when you use our mobile application. By using Exam Ace, you agree to this policy.

Use the **Published at** URL above in the Google Play Console, App Store Connect, and anywhere a privacy policy link is required.

---

## 1. Who we are

Exam Ace is a mobile **exam preparation tracker**: syllabus, daily tasks, mock tests, exam records, calendar history, and progress — with optional reminders.

**Contact:** sumanthtatipamula999@gmail.com

### 1.1 Not a government service; user-provided study content

Exam Ace is **not** a government agency and is **not** affiliated with or endorsed by any government, exam conducting body, or public-sector employer (including commissions such as SSC or UPSC, railway recruitment authorities, banking recruitment bodies, or state public service commissions). We do **not** operate an official channel for government notifications, syllabi, eligibility rules, or results.

**Syllabus, tasks, exam dates, and scores** stored in the app are **information you enter** (or your own notes). We process that data only to provide the app’s features described in **section 2** — not as a publisher of official government information.

---

## 2. Information we collect and use

### 2.1 Account and authentication

- **Email and password:** If you register with email, we process your **email address** and a **password** (handled by **Firebase Authentication**; we do not store your password in plain text on our servers in a way we can read — standard Firebase security applies).
- **Google Sign-In:** If you choose **Sign in with Google**, Google’s service provides authentication. We request access consistent with **email** and **profile** scopes so you can sign in and we can show your name or profile photo from Google where the app displays account details. Tokens are handled by Google and Firebase as described in their policies.
- Each signed-in user receives a **unique user ID** used to store your app data under your account.

### 2.2 Study and app data stored in the cloud (Firestore)

When you use the app, data you enter is stored in **Google Cloud Firestore** under your user ID. Depending on how you use Exam Ace, this may include:

- **Tasks** and related progress or completion information  
- **Calendar / day snapshots** and streak or summary-style data the app derives for the UI  
- **Syllabus data:** subjects, chapters, topics, notes, and progress you save  
- **Mock test** records you log  
- **Exam score / exam attempt** records you log  
- Other **user profile fields** stored in your user document as needed for the app to function  

This data is used only to **provide app features** (sync across devices when you sign in with the same account, backup, and display in the app).

### 2.3 Files stored in the cloud (Firebase Storage)

If you upload **images** (for example a **profile photo** or **subject / cover images**), files are stored in **Firebase Storage** under paths tied to your account (for example under `users/{your user id}/…`). Images may be resized or compressed before upload as implemented in the app.

### 2.4 Data stored only on your device

Some preferences are saved **locally** on your phone or tablet using the platform’s storage (for example **SharedPreferences**). They typically include:

- **Theme** (light / dark / system)  
- **Accent / colour preset**  
- **Week progress metric** (Simple / Strong / Strict)  
- **Syllabus sort order** (how chapters and topics are ordered)  
- **Notification** preferences (times, on/off), where those settings are not synced to our servers  

These stay on the device unless the OS backs them up according to your **iCloud / Google device backup** settings (outside our control).

### 2.5 Notifications

The app can schedule **local notifications** on your device (for example morning or evening reminders). They are **not** used to send your full task list or notes to our servers for the purpose of showing the notification — scheduling uses information the app already has locally at schedule time. Notification text may include **high-level counts** (for example how many tasks you have or that you have incomplete items), not your full private notes.

On **Android 13+** and on **iOS**, the system may ask for **notification permission**; you can change this in **Settings** at any time.

### 2.6 Camera and photo library (optional)

If you add a photo, the app may use the **camera** or **photo library** **only when you choose** to pick or take a picture. We use this solely to let you attach images you choose (for example profile or subject images). See Apple and Google platform policies for how the OS protects those permissions.

### 2.7 Opening links (privacy policy)

If you open the **Privacy policy** link from the app, the system **browser** may open using your default browser app (**url_launcher**). That request only navigates to the URL you see; we do not embed a full web tracker in that flow beyond what your browser and that website do.

### 2.8 Technical data, security, and analytics

- **Firebase and Google Cloud** process **technical data** needed to run authentication, database, and storage (for example **security tokens**, **IP-related** or **server logs** as described in [Firebase documentation](https://firebase.google.com/support/privacy), and abuse prevention).
- Data is transmitted using **HTTPS** in line with standard mobile and Firebase practices.
- **This app does not integrate a separate third-party analytics SDK** (for example we do not bundle Firebase Analytics in the app as listed in our public dependencies). Operational data may still appear in **Google Cloud / Firebase project** consoles for the developer to operate the service.

We do **not** sell your personal information.

---

## 3. Third-party services

The app relies on services that have their own privacy policies:

| Service | Purpose |
|--------|---------|
| **Google Firebase** (Authentication, Firestore, Storage, and related Google Cloud infrastructure) | Sign-in, encrypted sync and storage of your app data |
| **Google Sign-In** | Optional “Sign in with Google” |

You should review:

- [Google Privacy Policy](https://policies.google.com/privacy)  
- [Firebase Privacy and Security](https://firebase.google.com/support/privacy)  

We do not control how Google processes data when you use their services; that is governed by Google’s terms and your Google account choices.

---

## 4. Account and data deletion

**Public link for app store requirements (for example Google Play Data safety):**  
`https://sumanthtatipamula.github.io/Exam-ACE/#account-deletion`  
Opening this URL in a browser opens this policy at the **Account and data deletion** section.

You can **request deletion** of your account and associated data as follows:

- **In the app:** From **Profile → Data & account**, you can:
  - **Clear all data** — permanently deletes your Firestore data (including tasks, syllabus tree, mock tests, exam scores, day snapshots, and related records) and files under your user folder in **Firebase Storage**, as implemented by the app. Your **sign-in account** remains so you can keep using Exam Ace with an empty slate.
  - **Delete account** — permanently deletes your **Firebase Authentication** account after removing your data as above, then signs you out.
- **By email:** If you cannot use the app, send a request using this link: [Request account and data deletion](mailto:sumanthtatipamula999@gmail.com?subject=Exam%20Ace%20-%20Account%20and%20data%20deletion%20request&body=Please%20include%20the%20email%20address%20associated%20with%20your%20Exam%20Ace%20account%3A%0A%0A)

Include the email address tied to your account where possible so we can verify you. We will process requests within a reasonable time, subject to applicable law.

---

## 5. How long we keep data

We retain your account and app data for as long as your account exists and you use the service, until you delete data or the account as described in **section 4**.

You can also email us at the contact address in section 1 if you need help. Rare legal or technical limits may still apply in exceptional cases.

---

## 6. Children’s privacy

**Exam Ace is not intended for children under 13.** We do not knowingly collect personal information from children under 13. If you believe a child under 13 has provided us with personal information, contact us at the address above and we will take steps to delete it where required by law.

If your store listing targets users under 13, you must comply with additional rules (including parental consent where applicable). This policy alone is not legal advice; consult qualified counsel for COPPA, GDPR-K, or local child-protection rules.

---

## 7. Your rights

Depending on where you live, you may have rights to access, correct, delete, or export your personal data, or to object to certain processing. To exercise these rights, use **section 4** (including the email link there), contact us using the contact information in section 1, or use **Clear all data** / **Delete account** in the app where applicable. You can also manage some data through your **Google Account** and Google’s tools where applicable.

---

## 8. International users

If you use the app from outside your home country, your information may be processed in countries where our service providers (including Google) operate facilities, including the United States and other regions described in their policies.

---

## 9. Changes to this policy

We may update this policy from time to time. We will post the new version at the same URL (or update the “Last updated” date) and, where required, provide additional notice. Continued use of the app after changes means you accept the updated policy.

---

## 10. Disclaimer

This document is provided to support transparency for app stores and users. It is **not** legal advice. For regulated or high-risk use cases, consult a qualified lawyer.
