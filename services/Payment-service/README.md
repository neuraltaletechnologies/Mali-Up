# Mali Up Payment Service

Future backend contract for premium billing and payment orchestration.

## Status

- This standalone service is still not part of the Phase 1 MVP and remains an
  empty placeholder — the mobile app is still Firebase-only end to end.
- Automated payment verification already shipped, but as **Firebase Cloud
  Functions** living in `apps/mobile-app/functions/src/clickpesa.ts`
  (`createClickPesaPayment` / `verifyClickPesaPayment`), not as this service.
  Those functions hold the ClickPesa secret, verify payment status and amount
  server-side, and activate the plan via the Admin SDK — the mobile app can
  no longer write `plan`/`planExpiresAt` to its own profile directly
  (enforced in `firestore.rules`). See `CLICKPESA_INTEGRATION.md` for the
  full flow.
- The manual admin-review path (`plan_requests` claims, reviewed in the admin
  portal) still exists and still applies to Enterprise inquiries — ClickPesa
  activation is instant and automated, Enterprise is not.
- This service becomes relevant if/when billing outgrows Cloud Functions
  (e.g. multi-provider payments, subscription/recurring billing, invoicing
  the merchant side, dunning) rather than for the initial M-Pesa/ClickPesa
  verification, which is already automated.

## Future Responsibilities

- Multi-provider payment orchestration (beyond ClickPesa).
- Recurring/subscription billing and dunning.
- Payment status tracking and receipts across providers.

Part of the [Mali Up](../../README.md) suite.
