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
   `consumeOtpVerification({ phone, newPassword? })`, which reads-and-deletes
   that marker (one-time use) and throws `failed-precondition` if it's missing
   or expired — the app then routes the user back to re-verify.
   `newPassword` (the PIN-derived Firebase Auth password, passed only by the
   pre-auth registration callers) additionally heals an orphaned
   `{phone}@mali.up` auth account left behind by an earlier attempt: if one
   exists, its password is reset to `newPassword` *before* the marker is
   burned and the response returns `{ ok, accountExisted: true }`, so the
   client can sign in instead of dead-ending on `email-already-in-use`.

Firebase Auth account creation itself is a direct client SDK call with no
server hook (no Blocking Functions / Identity Platform are used here), so
`consumeOtpVerification` is the one real enforcement point — the same trust
boundary as every other onboarding step guard in this app, which are
otherwise client-state-driven (see `routing.dart`'s `_redirect`).

## Setup

1. Create a free account at https://login.beem.africa, verify email + phone.
2. **Multi-Country OTP Setup (All Supported African Countries)**:
   - For Tanzania-only SMS, the default channel is **Tanzania SMS**.
   - To send OTP and SMS to **all countries supported by Beem Africa** (Kenya, Uganda, Rwanda, Nigeria, South Africa, etc.):
     - Go to your Beem profile settings -> **International API** and ensure credentials are set up.
     - In **OTP → Applications**, create or edit your application, selecting **International API** (or Multi-Country SMS) as the channel.
     - Set pin length to **6 digits** (must match `OnboardingValidator.validateOtp` and `OtpVerifyBody`'s 6-digit input).
     - Copy the **Application ID** and set it as `BEEM_OTP_APP_ID`.
3. **OTP → SMS Templates** → create and get an SMS OTP template approved with
   an approved Sender ID (Beem rejects OTP sends from an unapproved template
   or Sender ID).
4. **Welcome SMS Template ("Maelezo ya mteja mpya")**:
   - In Beem dashboard -> **SMS Templates**, create or configure the template named:
     `Maelezo ya mteja mpya`
   - Content:
     `Habari!! {name} Tumekukalibishe kishupavu zaidi na Ofa ya Free plan kwenye account yako Kwa huduma ya kukuhamishia taarifa zako zote kwenye App, msadaa au changamoto yoyote Piga +255-653-520-829`
   - Note: The Cloud Function fetches this template dynamically from Beem's API (`GET /public/v1/sms-templates`). Whenever you update the wording, offer, or phone number in Beem, it automatically syncs and uses the new template without redeploying code.
   - Timing: Sent 5 minutes after a user account is created.
   - Existing users: Automatically detects users in Firestore who have not yet received the welcome message and delivers it to them.
5. **OTP → API Setup** → Generate API Key & Secret (the secret is shown once
   — store it now).
6. Set the two real secrets (never in `.env`, never committed):
   ```bash
   firebase functions:secrets:set BEEM_API_KEY
   firebase functions:secrets:set BEEM_SECRET_KEY
   ```
7. Copy `functions/.env.example` to `functions/.env`:
   - Set `BEEM_OTP_APP_ID` to the Application ID from step 2.
   - Set `BEEM_SMS_SENDER_ID` to your approved Beem Sender ID (e.g. `INFO` or your brand name).
8. `firebase deploy --only functions,firestore:rules`.

For local emulator testing, mirror the two secret names in
`functions/.secret.local` (gitignored) per the existing convention in
`functions/.gitignore`.
