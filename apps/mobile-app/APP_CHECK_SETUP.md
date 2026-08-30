# Firebase App Check — setup & rollout

App Check attaches an attestation token (Play Integrity on Android, App
Attest/DeviceCheck on iOS) to every Firestore and Cloud Functions callable
request, proving the call came from a genuine build of this app rather than
a script hitting our endpoints directly. The SDK is wired up in
[`lib/main.dart`](lib/main.dart) — this doc covers the Console-side steps
that can't be done from code, and the rollout order that keeps this from
locking out real users.

## One-time Console setup

1. Firebase Console → **Project settings → App Check**.
2. Register the Android app:
   - Provider: **Play Integrity**.
   - No extra config needed — it uses the same package name
     (`com.neuraltale.maliup`) and signing setup already in place for
     `checkDeviceIntegrity`.
3. Register the iOS app:
   - Provider: **App Attest**, with **DeviceCheck** as fallback (matches
     `AppleAppAttestWithDeviceCheckFallbackProvider` in `main.dart`).
   - Requires the app's Apple Team ID / bundle ID already on file for the
     iOS Firebase app.
4. **Debug token** (needed for local `flutter run` / debug builds and CI):
   - Run the app in debug mode once. On first launch it prints a line like
     `Firebase App Check debug token: XXXXXXXX-XXXX-...` to the console/logcat.
   - Console → App Check → the app → **Manage debug tokens** → add it, with
     a label (e.g. `<your name> — dev machine`).
   - Without this step, every debug build fails App Check silently as soon
     as enforcement is turned on (step 2 of rollout, below) — it does not
     block anything before that.

## Rollout — two separate steps, do NOT do them together

**Step 1 — ship the client (safe, already done in code):**
Activating App Check on the client (already in `main.dart`) only starts
*attaching* tokens. It does not reject anyone. This is safe to release
immediately — existing users on the previous build are unaffected.

**Step 2 — turn on enforcement (do this only after step 1 has rolled out):**
Wait until the App-Check-enabled build reaches the large majority of active
installs (check version adoption in the Play Console / App Store Connect,
or Firebase Analytics' active-version breakdown). Only then:

- Console → App Check → **APIs** tab → **Cloud Firestore** → Enforce.
- Console → App Check → **APIs** tab → **Cloud Functions** → Enforce (or
  add `enforceAppCheck: true` to the `onCall(...)` options in
  `functions/src/index.ts`, `clickpesa.ts`, and `otp_rate_limit.ts`, then
  redeploy).

Flipping enforcement before the client has rolled out locks every user
still on an older app version out of Firestore and every callable
function — including sign-in and payments. There is no way to whitelist
old clients after the fact; the only way back is un-enforcing, which
re-opens the exact abuse surface App Check exists to close.

## What this does not do

App Check stops requests that don't come from a real build of the app. It
does not rate-limit *legitimate* app usage — that's what
[`functions/src/otp_rate_limit.ts`](functions/src/otp_rate_limit.ts) is for
on the OTP path specifically. The two are complementary: App Check keeps
scripts out; the OTP limiter keeps a compromised or automated *real* client
from hammering a single phone number.
