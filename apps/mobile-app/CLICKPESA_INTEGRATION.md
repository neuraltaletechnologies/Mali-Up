# ClickPesa Payment Gateway Integration

## Overview

ClickPesa payments for Mali Up plan upgrades use ClickPesa's **USSD-Push**
API: the user picks a plan and confirms a phone number, we push a
mobile-money PIN prompt straight to that phone (M-Pesa, Tigo Pesa, Airtel
Money, HaloPesa), they enter their PIN there, and the plan activates the
moment ClickPesa confirms the charge. There is no checkout page and no
browser hop.

Everything ClickPesa-related is handled **server-side**, via three Cloud
Functions (`apps/mobile-app/functions/src/clickpesa.ts`). The mobile app
never holds a ClickPesa API key and can never activate a plan by itself —
`firestore.rules` rejects any client write to `plan`, `planExpiresAt`,
`subscriptionStatus`, `planSource`, or `enterpriseOverrides` on a business
document. Only the Admin SDK (used by these Cloud Functions and the admin
portal) can set those fields. The plan belongs to the specific business a
payment was initiated for — not to the paying account, and not mirrored onto
any other business that account might own.

**Payment status reaches the app via ClickPesa's webhook, not client
polling.** ClickPesa's free/pre-KYC tier caps API usage at 100 calls/day; the
original design polled `verifyClickPesaPayment` (which itself calls
ClickPesa) every 3s for up to 2 minutes per attempt — ~40 calls per payment,
enough to exhaust the daily quota after two attempts. See "Webhook setup"
below — it's a required step, not optional, for this to work at any real
volume.

## Architecture

### Files
- `functions/src/clickpesa.ts` — `initiateClickPesaPayment`,
  `verifyClickPesaPayment`, and `clickpesaWebhook`. These are the only code
  that ever talks to the ClickPesa API or holds the secret key.
- `lib/core/services/clickpesa_service.dart` — thin client: calls
  `initiateClickPesaPayment` via `cloud_functions`, then watches the
  `clickpesa_payments/{orderReference}` Firestore doc directly (no polling)
  with `verifyClickPesaPayment` as a low-frequency fallback.
- `lib/shared/widgets/upgrade_sheet.dart` — upgrade paywall UI, including the
  phone-number confirmation step and the payment POS animation.
- `firestore.rules` — blocks client writes to entitlement fields on
  `businesses/{businessId}`; allows a user to *read* (never write) their own
  `clickpesa_payments/{orderReference}` doc.

### Payment flow

1. User selects a plan (Growth/Business) and taps "Upgrade to …" for their
   active business.
2. App shows a phone-confirmation step, prefilled from the user's profile
   phone when available and always editable (the mobile-money line isn't
   always the account phone).
3. App calls `initiateClickPesaPayment({tier, phoneNumber, businessId})`. The
   function:
   - verifies the caller's uid actually owns `businessId` (`ownerUid` check)
     before charging anything — one account can't use its own payment to
     activate a plan on a business it doesn't own;
   - reads the *current* admin-configured price from `platform_config/plans`
     (never trusts an amount from the client);
   - normalizes the phone to ClickPesa's `255XXXXXXXXX` form and rejects
     anything that doesn't look like a real Tanzanian mobile number (no
     silent fallback to a placeholder number);
   - generates a ClickPesa auth token (cached ~50 min per warm instance —
     ClickPesa tokens are valid 1 hour);
   - calls ClickPesa's `initiate-ussd-push-request`, which pushes the PIN
     prompt to the phone;
   - stores a pending record (including `businessId`) in
     `clickpesa_payments/{orderReference}`.
4. User enters their mobile money PIN on the USSD prompt on their phone.
5. App watches `clickpesa_payments/{orderReference}` in real time
   (`ClickPesaService.waitForPayment`, a Firestore listener — no ClickPesa
   API calls). The moment ClickPesa confirms the charge, its webhook hits
   `clickpesaWebhook`, which re-verifies via an authenticated call to
   ClickPesa (never trusts the webhook payload's claimed status — see the
   security notes) and, on genuine success, activates the plan on that one
   `businesses/{businessId}` document via the Admin SDK inside a transaction
   (idempotent against concurrent/duplicate calls). A 20s-interval fallback
   poll via `verifyClickPesaPayment` runs alongside the listener purely as a
   safety net for a webhook that isn't configured yet or a lost delivery.
6. Client's Firestore listener sees `status: 'completed'` and shows the
   confirmation card. There is no separate client-side activation step; by
   the time the client sees success, the plan is already active.

### Webhook setup (required)

1. Log into the ClickPesa dashboard → **Settings → Developers** → your
   application ("Mali Up") → **Application Webhooks**.
2. Add this URL for both the `PAYMENT RECEIVED` and `PAYMENT FAILED` events:
   ```
   https://us-central1-neuraltale-mali-up.cloudfunctions.net/clickpesaWebhook
   ```
3. That's it — no secret/checksum needs configuring for this endpoint to
   work correctly (see security notes for why). The endpoint responds 200 to
   any POST, including ones for a reference it doesn't recognize, so ClickPesa
   won't see failures during setup/testing.

Without this configured, the app still works — it just falls back entirely to
the 20s-interval poll, which is far cheaper than the old 3s design but still
burns real ClickPesa API calls per pending payment. Confirm it's working by
watching `firebase functions:log --only clickpesaWebhook` while completing a
test payment; you should see an invocation within seconds of confirming the
PIN.

### Verified ClickPesa endpoints

Endpoint shapes below come from https://docs.clickpesa.com, fetched and
cross-checked while building this — not guessed:

| Purpose | Method | URL |
|---|---|---|
| Auth token | `POST` | `https://api.clickpesa.com/third-parties/generate-token` (headers: `client-id`, `api-key`; returns `{success, token}`, valid 1h) |
| Initiate push | `POST` | `https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request` (body: `amount` as **string**, `currency`, `orderReference`, `phoneNumber`) |
| Query status | `GET` | `https://api.clickpesa.com/third-parties/payments/{orderReference}` (returns an **array** of payment attempts) |

An earlier version of this integration called `https://api.clickpesa.com/v2/payments`,
which does not exist in ClickPesa's real API — every payment attempt would
have failed outright. If you ever see 404s from ClickPesa, check the base
path is still `/third-parties/...`.

### Checksum validation

ClickPesa supports an HMAC-SHA256 payload checksum (Settings → Developers →
Checksum in the ClickPesa dashboard). When it's **enabled** for the
application, every `initiate-ussd-push-request` **must** carry a `checksum`
field or ClickPesa rejects it with `400 { "message": "checksum is required" }`
— which `initiateClickPesaPayment` forwards to the app as
`invalid-argument: Payment could not be started: checksum is required`.

`checksumFor()` in `clickpesa.ts` computes it exactly per ClickPesa's spec
(https://docs.clickpesa.com/home/checksum): canonicalize the payload
(recursively sort object keys), compact-`JSON.stringify`, `HMAC-SHA256` with
the checksum key, hex digest — with the `checksum`/`checksumMethod` fields
excluded from the hashed payload. It needs the key wired in:

1. ClickPesa dashboard → Settings → Developers → Checksum → copy the checksum
   key. (Regenerate the API token afterwards if the dashboard tells you to.)
2. `cp apps/mobile-app/functions/.env.example apps/mobile-app/functions/.env`
   and set `CLICKPESA_CHECKSUM_KEY=<the key>`. It's a **plain** env var, not a
   Secret Manager secret (see `checksumFor()` — deliberate, so an unset key
   never blocks deployment). `.env` is gitignored and is loaded both on
   deploy and by the emulator; use `.env.local` for an emulator-only override.
3. `cd apps/mobile-app/functions && firebase deploy --only functions`.
4. Verify: `firebase functions:log --only initiateClickPesaPayment` should no
   longer show the `checksum is required` 400 after a test upgrade.

If checksum validation is **off** in the dashboard, leave `CLICKPESA_CHECKSUM_KEY`
unset — `checksumFor()` returns null and the field is simply omitted.

## Configuration

### Production (Secret Manager)

The ClickPesa Client ID and API Key are stored as Firebase Secret Manager
secrets, referenced in code via `defineSecret()`. They are **never**
committed and **never** shipped in the app binary. Set them once per
environment:

```bash
cd apps/mobile-app/functions
firebase functions:secrets:set CLICKPESA_CLIENT_ID
firebase functions:secrets:set CLICKPESA_API_KEY
```

Each command prompts for the value (paste it, press Enter). Then deploy:

```bash
firebase deploy --only functions,firestore:rules
```

To rotate a key later, re-run `functions:secrets:set` with the new value and
redeploy — the old secret version is retained but no longer referenced.

### Local development (emulator)

Create `apps/mobile-app/functions/.secret.local` (gitignored, never commit):

```
CLICKPESA_CLIENT_ID=your-client-id
CLICKPESA_API_KEY=your-api-key
```

Then:

```bash
cd apps/mobile-app/functions
npm install
npm run build
firebase emulators:start --only functions,firestore
```

The mobile app itself needs no ClickPesa configuration at all — no
`--dart-define` flags, no local JSON file. It only needs to be pointed at the
Functions emulator during local testing (`FirebaseFunctions.instance.useFunctionsEmulator(...)`),
same as any other Cloud Function in this app.

## Testing

1. Run functions + Firestore emulators with `.secret.local` set to ClickPesa
   sandbox credentials.
2. Open the upgrade sheet, select a plan, tap Upgrade, confirm/enter a phone
   number, tap Send Payment Request.
3. Complete the sandbox USSD push (sandbox docs describe how to simulate the
   PIN confirmation without a real phone).
4. Confirm the app shows the success card and
   `businesses/{businessId}.plan` updates in the emulator UI.

## Troubleshooting

1. **`FirebaseFunctionsException(not-found)` on verify** — the payment
   record in `clickpesa_payments/{orderReference}` doesn't exist; usually
   means `initiateClickPesaPayment` failed or was called against a different
   Firebase project than the one the Functions are deployed to.
2. **`permission-denied` on verify** — the payment belongs to a different
   `uid` than the caller. Should never happen through the app's own UI.
3. **`invalid-argument` on initiate** — the phone number didn't normalize to
   a valid `255[67]XXXXXXXX` Tanzanian mobile number. The client already
   does a loose check before calling; the server re-validates regardless.
4. **`failed-precondition` / "Payment amount mismatch"** — ClickPesa reports
   a different collected amount than what the payment was created for; the
   function refuses to activate rather than trust it. Check
   `platform_config/plans` pricing didn't change mid-flow.
5. **User never gets the USSD prompt** — check the `channel` ClickPesa
   returned from `initiateClickPesaPayment` (logged), and that the phone
   number's network actually supports ClickPesa's USSD-Push for that
   provider.
6. **Plan not activating after payment** — check Cloud Functions logs
   (`firebase functions:log`) for the `clickpesaWebhook` or
   `verifyClickPesaPayment` call; the transaction only commits once ClickPesa
   reports `SUCCESS`/`SETTLED` *and* the amount matches.
7. **`generate-token` returns 429 "Daily API limit reached"** — the ClickPesa
   application hasn't completed KYC yet and is capped at 100 calls/day. This
   is exactly the failure mode the webhook (see above) exists to avoid — if
   you're hitting it, either the webhook isn't configured, or KYC needs
   completing on the ClickPesa dashboard to lift the cap. Not something the
   code can work around.
8. **`invalid-argument` mentioning something other than the phone number**
   (e.g. "M-Pesa payment method is not active") — `initiateClickPesaPayment`
   forwards ClickPesa's real message here. This class of error is almost
   always a merchant-account configuration gap (a payment method not
   activated for the application, KYC incomplete, etc.) on the ClickPesa
   dashboard, not a code bug — check Settings → Developers → payment methods
   for the application.
9. **`invalid-argument: Payment could not be started: checksum is required`**
   — checksum validation is turned ON for the application in the ClickPesa
   dashboard but `CLICKPESA_CHECKSUM_KEY` isn't set on the deployed function,
   so no `checksum` field is sent. Fix: wire the key in per "Checksum
   validation" above and redeploy, or turn checksum validation off in the
   dashboard. (`invalid checksum` / `checksum mismatch` instead means the key
   is set but wrong — re-copy it from the dashboard.)

## Security notes

- The ClickPesa API key lives only in Secret Manager, injected into the
  Cloud Functions runtime — never in the mobile app binary, never in git.
- `firestore.rules` makes `plan`/`planExpiresAt`/`subscriptionStatus`/
  `planSource`/`enterpriseOverrides` on `businesses/{businessId}` write-only
  from the Admin SDK. A business owner cannot self-grant a paid plan by
  writing to their own business doc, regardless of what the client app does.
- `initiateClickPesaPayment` verifies `businessId.ownerUid == uid` before
  charging anything, so one account can never pay to activate a plan on a
  business it doesn't own.
- The amount charged always comes from the server-side read of
  `platform_config/plans`, never from anything the client supplies — a
  tampered client can't ask ClickPesa to charge less than the real price.
- Both `verifyClickPesaPayment` and `clickpesaWebhook` are idempotent:
  repeated polls, retries, duplicate webhook deliveries, or concurrent calls
  for the same payment activate the plan at most once (guarded by a
  Firestore transaction).
- The phone number is validated server-side too (not just client-side) — a
  tampered client can't push to garbage or a placeholder number.
- `clickpesaWebhook` is necessarily unauthenticated (ClickPesa calls it
  directly, not through Firebase's callable protocol) — but it never trusts
  anything from the request body except *which* `orderReference` to look
  at. It always re-derives the real status from its own authenticated GET to
  ClickPesa, never from the webhook payload. A forged or replayed POST to
  this URL can at most trigger an extra status check (itself capped by the
  5s `lastCheckedAtMs` debounce on the payment doc) — it cannot fake a plan
  activation, because the activation logic never reads "success" from
  anything ClickPesa didn't tell us directly, server-to-server, using our
  own secret.

## Support

- ClickPesa API docs: https://docs.clickpesa.com
- ClickPesa support: support@clickpesa.com
- Mali Up internal: Check Cloud Functions logs / Sentry for payment errors
