# PIN Recovery

## Overview

A user who forgot their login PIN taps **"Umesahau PIN?" → "Nitumie Kiungo"**
on the PIN login screen. The backend emails a magic link to the address on
file; opening it on the phone launches the app straight to a "set a new PIN"
screen (Android App Link). On confirmation the new PIN's derived password is
written to the Firebase Auth account and the user is dropped back on the PIN
login screen to sign in.

### Why this isn't Firebase's built-in password reset

- Every account's Firebase Auth email is the **derived `<phone>@mali.up`**
  (`lib/core/utils/phone_number_utils.dart`) — a domain that cannot receive
  mail. `FirebaseAuth.sendPasswordResetEmail` bounces, or (with email
  enumeration protection on) silently sends nothing. The real email lives only
  in Firestore `users/{uid}.email`.
- The Auth password is a deterministic HMAC of phone + PIN
  (`buildAuthPasswordFromPin`, `lib/features/auth/presentation/utils/pin_auth_password.dart`).
  A stock reset that set an arbitrary password would leave `loginWithPin`
  broken — recovery must end by setting the password to exactly
  `buildAuthPasswordFromPin(phone, newPin)`.

## Architecture

### Cloud Functions — `functions/src/pin_recovery.ts`

All three are `onCall`, region `us-central1`, **callable without auth**
(recovery is pre-sign-in, like `requestOtpAllowance`). Every entry point is
rate-limited via `enforceRateLimit` (`functions/src/rate_limit.ts`) before it
does any work.

| Function | Purpose |
|---|---|
| `requestPinReset({phone, language})` | Looks the user up by phone, mints a 32-byte token, stores its SHA-256 hash in `pin_reset_tokens/{hash}` (30-min `expiresAt`), and emails the magic link via **Resend**. Returns `{status: "sent", maskedEmail}` or `{status: "no_email"}` (the latter also covers "no account" — deliberately indistinguishable). |
| `validatePinResetToken({token})` | Called by `PinResetScreen` on open. Returns `{valid: true, phone, maskedEmail}` (the canonical phone lets the client derive the new password) or `{valid: false, reason}`. |
| `confirmPinReset({token, newPassword})` | `newPassword` is the client-computed `buildAuthPasswordFromPin(phone, newPin)` — the pepper/HMAC stay client-side; the server only shape-checks it. Burns the token in a transaction, then `admin.auth().updateUser(uid, {password})`. The Auth email is left as `<phone>@mali.up`. |

Rate-limit windows: 3 requests / 15 min per phone, 10 / hour per IP for
`requestPinReset`; 30 / 15 min per IP for validate + confirm; 5 confirm
attempts per token.

Server-only collections (client read/write denied in `firestore.rules`):
`pin_reset_tokens`, `pin_reset_rate_limits_phone`, `pin_reset_rate_limits_ip`,
`pin_reset_validate_rate_limits_ip`.

### Web — `apps/admin` (`https://maliup.neuraltale.com`)

- **`public/.well-known/assetlinks.json`** — Android App Links verification for
  `com.neuraltale.maliup`. **Must** contain the real signing-cert SHA-256
  fingerprints (see Setup) — the committed file has placeholders.
- **`app/reset-pin/page.tsx`** — the landing page. On a verified Android device
  with the app installed, the OS opens the app directly and this page is never
  seen. Otherwise (desktop, app not installed, unverified link) it shows an
  "open the app" button that hands off via the `maliup://` custom scheme, plus
  a Play Store link.

### Mobile app

| Piece | Where |
|---|---|
| Manifest App Link + `flutter_deeplinking_enabled` | `android/app/src/main/AndroidManifest.xml` |
| Route `AppRoutes.resetPin` + `_redirect` exception | `lib/config/routing.dart` |
| `PinResetScreen` (set-new-PIN UI) | `lib/features/onboarding/presentation/screens/pin_reset_screen.dart` |
| Request sheet (`_ForgotPinSheet`) | `lib/features/onboarding/presentation/screens/pin_login_screen.dart` |
| Repository / service / notifier methods | `requestPinReset` / `validatePinResetToken` / `confirmPinReset` in the onboarding data + provider layers |
| Result types | `lib/features/onboarding/domain/models/pin_reset_result.dart` |

GoRouter receives the link through Flutter's built-in deep linking (the
manifest meta-data). After a successful `confirmPinReset`, the notifier seeds
the onboarding state + runs the returning-user phone lookup and sets
`OnboardingState.pinJustReset`, so `/pin-login` renders correctly and shows a
one-off confirmation toast.

## Setup

### 1. Resend

1. Create a Resend account and **verify the `neuraltale.com` sending domain**
   (add the SPF/DKIM DNS records Resend gives you). Until the domain is
   verified, delivery to real inboxes will fail or land in spam.
2. Create an API key.
3. Store it as a Secret Manager secret:
   ```bash
   cd apps/mobile-app/functions
   firebase functions:secrets:set RESEND_API_KEY
   ```
4. Optional overrides in `functions/.env` (both have safe defaults — see
   `.env.example`):
   ```
   PIN_RECOVERY_LINK_BASE=https://maliup.neuraltale.com/reset-pin
   PIN_RECOVERY_EMAIL_FROM=Mali Up <security@neuraltale.com>
   ```
   `PIN_RECOVERY_EMAIL_FROM` must be a sender Resend has verified on the
   verified domain.

### 2. Android App Links

1. Play Console → **Setup → App signing** → copy the **App signing key
   certificate** SHA-256 fingerprint. Also copy the **upload key certificate**
   SHA-256 so locally-installed (upload-signed) builds verify too.
2. Put both into `apps/admin/public/.well-known/assetlinks.json`, replacing the
   `REPLACE_WITH_...` placeholders.
3. Merge to `main` — Cloudflare rebuilds `maliup.neuraltale.com`. Confirm:
   ```
   curl https://maliup.neuraltale.com/.well-known/assetlinks.json
   ```
   must return the JSON as `Content-Type: application/json`.
4. After the next Play release, verify:
   ```
   adb shell pm verify-app-links --re-verify com.neuraltale.maliup
   adb shell pm get-app-links com.neuraltale.maliup   # expect "verified"
   ```
   or check Play Console → *Deep links*.

Until App Links verify, the flow still works — the link opens
`maliup.neuraltale.com/reset-pin` in a browser and the user taps "open app"
(custom scheme).

### 3. Firestore TTL

Console → Firestore → **TTL** → add a policy on collection `pin_reset_tokens`,
field `expiresAt`. Spent/expired tokens are then cleaned up automatically.

### 4. Deploy

```bash
cd apps/mobile-app/functions
npm run build
firebase deploy --only functions,firestore:rules
```

## Testing

### Functions (emulator)

`.secret.local` with a Resend test key, then
`firebase emulators:start --only functions,firestore`.

1. Seed a `users` doc with a `phone` and a real `email`. Call `requestPinReset`
   → email arrives, `pin_reset_tokens/{hash}` created. Call it 4× in 15 min →
   `resource-exhausted`.
2. Seed a `users` doc whose only email ends `@mali.up` → `{status: "no_email"}`.
3. `validatePinResetToken` with the token → `{valid:true, phone, maskedEmail}`;
   with junk → `invalid`; 30 min later → `expired`.
4. `confirmPinReset({token, newPassword: buildAuthPasswordFromPin(phone, newPin)})`
   → then `signInWithEmailAndPassword("<phone>@mali.up", <same password>)`
   succeeds. Replaying the token → `failed-precondition`.

### App

```
adb shell am start -a android.intent.action.VIEW \
  -d "https://maliup.neuraltale.com/reset-pin?token=XXX" com.neuraltale.maliup
```
opens `PinResetScreen`. Full path: forgot PIN → email → tap link → set new PIN
→ land on PIN login with the toast → sign in with the new PIN.

## Troubleshooting

1. **Email never arrives** — Resend dashboard → Logs. Almost always the
   `neuraltale.com` domain isn't verified, or `PIN_RECOVERY_EMAIL_FROM` isn't a
   verified sender. Check the function log: `firebase functions:log --only requestPinReset`.
2. **Link opens the browser, not the app** — App Links haven't verified.
   Re-check `assetlinks.json` (right fingerprints, served as JSON at the exact
   path) and re-run `pm verify-app-links`. The browser fallback page's "open
   app" button still works in the meantime.
3. **`failed-precondition` on confirm** — token expired, already used, or the
   user opened an older link. Request a fresh one.
4. **PIN login still fails after reset** — the client and server must agree on
   `buildAuthPasswordFromPin`. If `pin_auth_password.dart` (pepper or format)
   changed, old recovery links minted before the change are unaffected (the
   client always derives with the current code), but any account whose password
   predates the change needs a fresh reset.
5. **A signed-in user forgot their app-lock PIN** — `PinLockScreen` sits above
   the router, so the deep link can't reach `PinResetScreen` while locked. That
   user has to reinstall or contact support. (The common case — a signed-out
   user at the onboarding PIN screen — is unaffected.)
