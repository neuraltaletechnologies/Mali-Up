# ClickPesa Payment Gateway Integration

## Overview

ClickPesa payments for Mali Up plan upgrades are handled entirely **server-side**,
via two Cloud Functions (`apps/mobile-app/functions/src/clickpesa.ts`). The
mobile app never holds a ClickPesa API key and can never activate a plan by
itself — `firestore.rules` rejects any client write to `plan`, `planExpiresAt`,
`premiumExpiresAt`, `lastPayment`, or `enterpriseOverrides` on a user's own
profile doc. Only the Admin SDK (used by these Cloud Functions and the admin
portal) can set those fields.

## Architecture

### Files
- `functions/src/clickpesa.ts` — `createClickPesaPayment` and
  `verifyClickPesaPayment` callables. These are the only code that ever talks
  to the ClickPesa API or holds the secret key.
- `lib/core/services/clickpesa_service.dart` — thin client that calls the two
  callables above via `cloud_functions`.
- `lib/shared/widgets/upgrade_sheet.dart` — upgrade paywall UI.
- `firestore.rules` — blocks client writes to entitlement fields on
  `users/{uid}`.

### Payment flow

1. User selects a plan (Growth/Business) and taps "Upgrade".
2. App calls `createClickPesaPayment({tier})`. The function reads the
   *current* admin-configured price from `platform_config/plans`, creates the
   ClickPesa payment, and stores a pending record in `clickpesa_payments/{id}`
   (server-only collection — the client never reads or writes it directly).
3. App opens the returned `paymentUrl` in an external browser
   (M-Pesa/Card/etc., ClickPesa's own UI).
4. App polls `verifyClickPesaPayment({paymentId})` every 3s (up to 30
   attempts). The function checks the *real* ClickPesa status, cross-checks
   the charged amount against what was actually quoted, and — the first time
   it sees `completed` — activates the plan on `users/{uid}` via the Admin
   SDK inside a transaction (idempotent against concurrent calls).
5. Client sees `status: 'completed'` and shows the confirmation card. There is
   no separate client-side activation step; by the time the client sees
   success, the plan is already active.

## Configuration

### Production (Secret Manager)

The ClickPesa Client ID and API Key are stored as Firebase Secret Manager
secrets, referenced in code via `defineSecret()`. They are **never** committed
and **never** shipped in the app binary. Set them once per environment:

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
2. Open the upgrade sheet, select a plan, tap Upgrade.
3. Complete the sandbox payment in the opened browser.
4. Confirm the app shows the success card and `users/{uid}.plan` updates in
   the emulator UI.

## Troubleshooting

1. **`FirebaseFunctionsException(not-found)` on verify** — the payment record
   in `clickpesa_payments/{id}` doesn't exist; usually means `createPayment`
   failed or was called against a different Firebase project than the one the
   Functions are deployed to.
2. **`permission-denied` on verify** — the payment belongs to a different
   `uid` than the caller. Should never happen through the app's own UI.
3. **`failed-precondition` / "Payment amount mismatch"** — ClickPesa reports a
   different amount than what the payment was created for; the function
   refuses to activate rather than trust it. Check `platform_config/plans`
   pricing didn't change mid-flow.
4. **Payment URL doesn't open** — check `url_launcher` permissions and that
   ClickPesa returned a `paymentUrl`.
5. **Stuck on ClickPesa's page after paying** — the `maliup://` URL scheme
   (registered in `AndroidManifest.xml` / `Info.plist`) should bring the app
   back to the foreground; the client keeps polling regardless, so activation
   still completes even if that redirect fails.
6. **Plan not activating after payment** — check Cloud Functions logs
   (`firebase functions:log`) for the `verifyClickPesaPayment` call; the
   transaction only commits once ClickPesa reports `completed`/`paid` *and*
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

## Support

- ClickPesa API docs: https://docs.clickpesa.com
- ClickPesa support: support@clickpesa.com
- Mali Up internal: Check Cloud Functions logs / Sentry for payment errors
