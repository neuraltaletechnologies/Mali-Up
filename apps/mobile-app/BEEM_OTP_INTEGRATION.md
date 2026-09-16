# Beem Africa OTP Integration

## Overview

First-time registration (a brand-new owner account, and a team member's
first-ever PIN setup) verifies the phone number with a 6-digit SMS code
before the Firebase Auth account is created. The code itself is generated,
delivered, and checked by **Beem Africa's dedicated OTP product** — Mali Up
never generates or stores the code; it only proxies two calls to Beem with
server-held credentials and records a short-lived "this phone was verified"
marker.

Returning-user PIN login and PIN recovery are **not** gated by OTP — only
first-time account creation is.

Endpoints/field names were verified against Beem's own docs
(https://docs.beem.africa/guides/otp) and their official Laravel SDK
(`bryceandy/laravel-beem`, `src/Traits/Otp/HandlesOtp.php`), not guessed:

- `POST https://apiotp.beem.africa/v1/request` — body `{ appId, msisdn }` →
  `{ data: { pinId, message: { code, message }, expiresInSeconds } }`
- `POST https://apiotp.beem.africa/v1/verify` — body `{ pinId, pin }` →
  `{ data: { message: { code, message } } }` (`code === 117` means verified)
- Auth: `Authorization: Basic base64(apiKey:secretKey)`, `Content-Type: application/json`

## Architecture

### Files
- `functions/src/beem_otp.ts` — `sendBeemOtp`, `verifyBeemOtp`,
  `consumeOtpVerification`. The only code that ever talks to Beem's API or
  holds the API key/secret.
- `lib/features/onboarding/data/repositories/onboarding_repository.dart` —
  `sendOtp`/`verifyOtp` call the two callables; `createNewUserAccount` /
  `createTeamMemberAccount` call `consumeOtpVerification` first.
- `lib/features/onboarding/presentation/screens/_onboarding_scaffold.dart` —
  shared `OtpVerifyBody` widget (used by both the new-owner PIN screen and the
  team-member setup screen).
- `firestore.rules` — denies all client access to `otp_verifications/{phone}`
  and the `beem_otp_*_rate_limits_*` counters (Admin SDK only).

### Flow

1. User reaches the PIN-setup step of registration (new owner: Screen 6
   `/security`; team member: `/team-setup`'s PIN step). The screen calls
   `sendBeemOtp({ phone })` automatically.
2. `sendBeemOtp` rate-limits the send (3 per 15 min + 8/day per phone, 20/hour
   per IP — every send costs real Beem SMS credit), then calls Beem's
   `/v1/request` and returns `{ pinId, expiresInSeconds }` to the client. Beem
   texts the code to the phone.
3. User enters the 6-digit code; the app calls
   `verifyBeemOtp({ phone, pinId, pin })`.
4. `verifyBeemOtp` rate-limits verify attempts (5 per 10 min per phone — caps
   brute-forcing a captured `pinId`), calls Beem's `/v1/verify`, and on
   success writes `otp_verifications/{phone} = { verifiedAt, expiresAtMs }`
   (30-minute TTL — long enough to finish the rest of onboarding).
5. Immediately before creating the Firebase Auth account,
   `createNewUserAccount` / `createTeamMemberAccount` call
   `consumeOtpVerification({ phone })`, which reads-and-deletes that marker
   (one-time use) and throws `failed-precondition` if it's missing or
   expired — the app then routes the user back to re-verify.

Firebase Auth account creation itself is a direct client SDK call with no
server hook (no Blocking Functions / Identity Platform are used here), so
`consumeOtpVerification` is the one real enforcement point — the same trust
boundary as every other onboarding step guard in this app, which are
otherwise client-state-driven (see `routing.dart`'s `_redirect`).

## Setup

1. Create a free account at https://login.beem.africa, verify email + phone.
2. **OTP → Applications** → create a new application, channel **Tanzania
   SMS**, pin length **6 digits** (must match
   `OnboardingValidator.validateOtp` and `OtpVerifyBody`'s 6-digit input).
   Copy the **Application ID**.
3. **OTP → SMS Templates** → create and get an SMS OTP template approved with
   an approved Sender ID (Beem rejects OTP sends from an unapproved template
   or Sender ID).
4. **OTP → API Setup** → Generate API Key & Secret (the secret is shown once
   — store it now).
5. Set the two real secrets (never in `.env`, never committed):
   ```bash
   firebase functions:secrets:set BEEM_API_KEY
   firebase functions:secrets:set BEEM_SECRET_KEY
   ```
6. Copy `functions/.env.example` to `functions/.env` and set
   `BEEM_OTP_APP_ID` to the Application ID from step 2 (not secret, but
   required — deploy fails closed with `internal` if unset).
7. `firebase deploy --only functions,firestore:rules`.

For local emulator testing, mirror the two secret names in
`functions/.secret.local` (gitignored) per the existing convention in
`functions/.gitignore`.
