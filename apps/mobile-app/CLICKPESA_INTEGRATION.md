# ClickPesa Payment Gateway Integration

## Overview

ClickPesa payments for Mali Up plan upgrades use ClickPesa's **USSD-Push**
API: the user picks a plan and confirms a phone number, we push a
mobile-money PIN prompt straight to that phone (M-Pesa, Tigo Pesa, Airtel
Money, HaloPesa), they enter their PIN there, and the plan activates the
moment ClickPesa confirms the charge. There is no checkout page and no
browser hop.

Everything ClickPesa-related is handled **server-side**, via two Cloud
Functions (`apps/mobile-app/functions/src/clickpesa.ts`). The mobile app
never holds a ClickPesa API key and can never activate a plan by itself —
`firestore.rules` rejects any client write to `plan`, `planExpiresAt`,
`premiumExpiresAt`, `lastPayment`, or `enterpriseOverrides` on a user's own
profile doc. Only the Admin SDK (used by these Cloud Functions and the admin
portal) can set those fields.

## Architecture

### Files
- `functions/src/clickpesa.ts` — `initiateClickPesaPayment` and
  `verifyClickPesaPayment` callables. These are the only code that ever
  talks to the ClickPesa API or holds the secret key.
- `lib/core/services/clickpesa_service.dart` — thin client that calls the two
  callables above via `cloud_functions`.
- `lib/shared/widgets/upgrade_sheet.dart` — upgrade paywall UI, including the
  phone-number confirmation step.
- `firestore.rules` — blocks client writes to entitlement fields on
  `users/{uid}`.

### Payment flow

1. User selects a plan (Growth/Business) and taps "Upgrade to …".
2. App shows a phone-confirmation step, prefilled from the user's profile
   phone when available and always editable (the mobile-money line isn't
   always the account phone).
3. App calls `initiateClickPesaPayment({tier, phoneNumber})`. The function:
   - reads the *current* admin-configured price from `platform_config/plans`
     (never trusts an amount from the client);
   - normalizes the phone to ClickPesa's `255XXXXXXXXX` form and rejects
     anything that doesn't look like a real Tanzanian mobile number (no
     silent fallback to a placeholder number);
   - generates a ClickPesa auth token (cached ~50 min per warm instance —
     ClickPesa tokens are valid 1 hour);
   - calls ClickPesa's `initiate-ussd-push-request`, which pushes the PIN
     prompt to the phone;
   - stores a pending record in `clickpesa_payments/{orderReference}`
     (server-only collection — the client never reads or writes it
     directly).
4. User enters their mobile money PIN on the USSD prompt on their phone.
5. App polls `verifyClickPesaPayment({orderReference})` every 3s (up to 40
   attempts — 2 minutes). The function queries ClickPesa's real payment
   status, cross-checks the collected amount against what was actually
   quoted, and — the first time it sees `SUCCESS`/`SETTLED` — activates the
   plan on `users/{uid}` via the Admin SDK inside a transaction (idempotent
   against concurrent calls).
6. Client sees `status: 'completed'` and shows the confirmation card. There
   is no separate client-side activation step; by the time the client sees
   success, the plan is already active.

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

### Optional: checksum validation

ClickPesa supports an optional HMAC-SHA256 payload checksum (Settings →
Developers → Checksum in the ClickPesa dashboard). It's off unless you turn
it on. If you do, set `CLICKPESA_CHECKSUM_KEY` as a **plain** env var (not a
Secret Manager secret — see `checksumFor()` in `clickpesa.ts`) via
`functions/.env` (production) or `functions/.secret.local` (emulator); the
code picks it up automatically and starts sending the checksum. Leaving it
unset is safe — the field is simply omitted.

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
4. Confirm the app shows the success card and `users/{uid}.plan` updates in
   the emulator UI.

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
   (`firebase functions:log`) for the `verifyClickPesaPayment` call; the
   transaction only commits once ClickPesa reports `SUCCESS`/`SETTLED` *and*
   the amount matches.

## Security notes

- The ClickPesa API key lives only in Secret Manager, injected into the
  Cloud Functions runtime — never in the mobile app binary, never in git.
- `firestore.rules` makes `plan`/`planExpiresAt`/`lastPayment`/
  `premiumExpiresAt`/`enterpriseOverrides` on `users/{uid}` write-only from
  the Admin SDK. A user cannot self-grant a paid plan by writing to their own
  profile doc, regardless of what the client app does.
- The amount charged always comes from the server-side read of
  `platform_config/plans`, never from anything the client supplies — a
  tampered client can't ask ClickPesa to charge less than the real price.
- `verifyClickPesaPayment` is idempotent: repeated polls, retries, or two
  concurrent calls for the same payment activate the plan at most once
  (guarded by a Firestore transaction).
- The phone number is validated server-side too (not just client-side) — a
  tampered client can't push to garbage or a placeholder number.

## Support

- ClickPesa API docs: https://docs.clickpesa.com
- ClickPesa support: support@clickpesa.com
- Mali Up internal: Check Cloud Functions logs / Sentry for payment errors
