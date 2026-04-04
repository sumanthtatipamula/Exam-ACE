# Firebase Functions Setup for Email Service

This guide explains how to deploy and configure Firebase Cloud Functions for secure email sending with Resend.

## 🚀 Quick Start

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Install Function Dependencies

```bash
cd functions
npm install
cd ..
```

### 4. Configure Resend API Key (Using Secret Manager)

Firebase now uses Secret Manager for secure configuration. Set your API key as a secret:

```bash
# Add the secret to Secret Manager
firebase functions:secrets:set RESEND_API_KEY
```

When prompted, paste your API key: `re_6Q9Wmv7U_3tE4uJc2s2zcPzAtWXHNxzTn`

Verify it's set:
```bash
firebase functions:secrets:access RESEND_API_KEY
```

### 5. Deploy Functions

```bash
firebase deploy --only functions
```

This will deploy the following functions:
- `sendVerificationEmail` - For user signup verification (callable)
- `sendPasswordResetEmail` - For password reset emails (callable)
- `verifyEmailToken` - Verify email token (callable, used by the Flutter app)
- `verifyPasswordResetToken` - Reset password with token (callable, used by the Flutter app)
- `verifyEmailTokenHttp` - Verify email token (HTTP endpoint, used by web pages)
- `resetPasswordHttp` - Reset password with token (HTTP endpoint, used by web pages)
- `sendEmailVerification` - Send email verification (callable)

## 📱 Flutter App Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Usage in Your App

The `EmailVerificationService` is already configured to use Firebase Functions:

```dart
import 'package:exam_ace/core/services/email_verification_service.dart';

// Send verification email
await EmailVerificationService.sendVerificationEmail(
  toEmail: user.email!,
  userName: user.displayName ?? 'User',
  verificationLink: 'https://yourapp.com/verify?token=abc123',
);

// Send password reset email
await EmailVerificationService.sendPasswordResetEmail(
  toEmail: email,
  userName: userName,
  resetLink: 'https://yourapp.com/reset?token=xyz789',
);
```

## 🔧 Local Testing

### 1. Start Firebase Emulators

```bash
firebase emulators:start
```

### 2. Configure Flutter to Use Emulator

In your app initialization:

```dart
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

## 📧 Update Sender Email (Production)

1. **Verify your domain in Resend**:
   - Go to https://resend.com/domains
   - Add your domain (e.g., `examace.app`)
   - Add DNS records (SPF, DKIM, DMARC)

2. **Update sender email in `functions/index.js`**:
   ```javascript
   from: 'Exam Ace <noreply@yourdomain.com>', // Change this
   ```

3. **Redeploy functions**:
   ```bash
   firebase deploy --only functions
   ```

## 🔒 Security Benefits

✅ **API Key Never Exposed**
- API key stored securely in Firebase config
- Not included in APK or client code
- Can't be extracted by decompiling

✅ **Authentication Required**
- `sendVerificationEmail` requires user to be logged in
- Prevents abuse from unauthorized users

✅ **Rate Limiting**
- Firebase automatically rate limits function calls
- Prevents spam and abuse

✅ **Monitoring**
- View function logs: `firebase functions:log`
- Track usage in Firebase Console
- Monitor email delivery in Resend dashboard

## 📊 Monitoring & Logs

### View Function Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only sendVerificationEmail
```

### Firebase Console

- Go to Firebase Console → Functions
- View invocations, errors, and execution time
- Set up alerts for errors

### Resend Dashboard

- https://resend.com/emails
- View all sent emails
- Check delivery status
- Monitor bounce rates

## 💰 Costs

### Firebase Functions (Spark/Free Plan)
- 2M invocations/month
- 400K GB-seconds/month
- 200K CPU-seconds/month

**Typical usage**: ~0.1s per email = 2M emails/month free

### Resend
- Free: 100 emails/day, 3,000/month
- Pro: $20/month for 50,000 emails

## 🔄 Updating Functions

After making changes to `functions/index.js`:

```bash
firebase deploy --only functions
```

Or deploy specific function:
```bash
firebase deploy --only functions:sendVerificationEmail
```

## 🐛 Troubleshooting

### "Function not found" error
- Make sure functions are deployed: `firebase deploy --only functions`
- Check function names match in Flutter code

### "Resend API key not configured"
- Set the secret: `firebase functions:secrets:set RESEND_API_KEY`
- Redeploy functions after setting secret
- Make sure to grant Secret Manager access when prompted

### Emails not sending
- Check function logs: `firebase functions:log`
- Verify Resend API key is correct
- Check Resend dashboard for errors

### CORS errors (if using HTTP functions)
- Use callable functions (already configured)
- Callable functions handle CORS automatically

## 🌐 Firebase Hosting & Web Pages

### Custom domain (`examace.sumanthtatipamula.com`)

Do this **once** so email links and browsers load your pages on HTTPS.

#### 1. Deploy Hosting at least once (default URL)

```bash
firebase deploy --only hosting
```

Confirm **`https://exam-ace-db272.web.app/verify-email.html`** loads (or `/reset-password.html`). If not, fix `public/` + `firebase.json` first.

#### 2. Add the domain in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com) → project **exam-ace-db272**.
2. **Build** → **Hosting** → **Add custom domain**.
3. Enter **`examace.sumanthtatipamula.com`** (subdomain only; no `https://`).
4. Firebase shows **DNS records** to add (verification **TXT** and either **A** records or a **CNAME** — follow **exactly** what the wizard shows; Google updates these over time).

#### 3. Add DNS at your registrar

Where **`sumanthtatipamula.com`** is registered (Namecheap, Google Domains, Cloudflare, etc.):

1. Open **DNS management** for the domain.
2. Add the **TXT** record(s) for **domain verification** (Firebase will show host + value).
3. Add the **A** or **CNAME** record(s) Firebase gives for **examace** (or `@` if you used apex — you chose a **subdomain**, so it’s usually a **CNAME** named `examace` pointing to a Firebase target such as `exam-ace-db272.web.app` or a `ghs.googlehosted.com`-style host — **copy from the console**, don’t guess).

Save DNS. Propagation can take **minutes to 48 hours** (often &lt; 1 hour).

#### 4. Wait for SSL and “Connected”

In **Hosting → Custom domains**, wait until the domain shows **Connected** and **SSL certificate** is active. Until then, links may fail or show certificate warnings.

#### 5. Redeploy Cloud Functions (email links)

`functions/index.js` uses **`HOSTING_PUBLIC_URL = 'https://examace.sumanthtatipamula.com'`** for links in emails. After the domain works in a browser:

```bash
firebase deploy --only functions
```

#### 6. Test

- Open **`https://examace.sumanthtatipamula.com/verify-email.html`** in a browser — should load without “site can’t be reached”.
- Trigger a real verification / password reset email and open the link.

#### Troubleshooting

| Issue | What to check |
|--------|----------------|
| **Site can’t be reached** | DNS not propagated yet; wrong CNAME/A; typo in hostname `examace`. Use [dig](https://toolbox.googleapps.com/apps/dig/) or `nslookup examace.sumanthtatipamula.com`. |
| **SSL pending** | Wait; Firebase issues certs after DNS is correct. |
| **Works on web.app but not custom** | Custom domain not added in Hosting or DNS incomplete. |
| **Need a working link before DNS is ready** | Temporarily set `HOSTING_PUBLIC_URL` to `https://exam-ace-db272.web.app` in `functions/index.js`, deploy functions, then switch back after the custom domain is **Connected**. |

### Hosting rewrites (`firebase.json`)

| Path | Target |
|------|--------|
| `/api/verify-email` | `verifyEmailTokenHttp` Cloud Function |
| `/api/reset-password` | `resetPasswordHttp` Cloud Function |
| `/verify-email` | `verify-email.html` |
| `/reset-password` | `reset-password.html` |

### Web pages

- **`public/verify-email.html`** — Automatically calls `/api/verify-email` on page load to verify the user's email. Shows loading → success/error states.
- **`public/reset-password.html`** — Displays a password form. On submit, calls `/api/reset-password` to update the password. Shows form → success/error states.

Both pages use **Tailwind CSS** (CDN) for responsive design across all devices.

### Deploy hosting + functions

```bash
firebase deploy --only functions,hosting
```

## 📝 Next Steps

1. ✅ Deploy functions: `firebase deploy --only functions`
2. ✅ Test email sending in your app
3. ✅ Verify domain in Resend (for production)
4. ✅ Update sender email in functions
5. ✅ Monitor usage and logs
6. ✅ Build and distribute APK (API key stays secure!)
7. ✅ Deploy hosting: `firebase deploy --only hosting`
8. ✅ Test web-based verification and password reset in browser

## 🎯 Build & Distribute

Now you can safely build and share your APK:

```bash
flutter build apk --release
```

The API key is **NOT** in the APK - it's securely stored in Firebase Cloud Functions!
