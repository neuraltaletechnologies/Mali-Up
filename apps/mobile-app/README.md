# Mali Up Mobile

Mali Up Mobile is a Swahili-first Flutter app for Tanzanian SMEs.

## Current Stack

- Flutter + Riverpod UI
- Firebase Auth for identity
- Cloud Firestore for onboarding, business, customer, and app state
- Firebase Storage for media
- Sentry for crash reporting

## Authentication Model

The app is Firebase-only for onboarding and sign-in.

- Phone lookup reads directly from Firestore.
- Returning users sign in with Firebase Auth and their PIN-derived password.
- New users complete onboarding and are provisioned in Firebase Auth + Firestore.
- PIN recovery uses Firebase Auth password reset.

There is no custom auth backend in the mobile app flow.

## Data Layer

- Onboarding data is stored in Firestore under the active tenant/business scope.
- Repository classes keep the UI isolated from persistence details.
- The generic HTTP helper only exists for explicit API URLs that you pass in yourself.

## UI Direction

The app uses the Premium Fintech White system:

- `navyPrimary` `#0D1B3E`
- `tealAccent` `#1A6E8A`
- `yellowBrand` `#FFC107`
- `surfaceLight` `#F8F9FC`
- `cardWhite` `#FFFFFF`

## Getting Started

```bash
flutter pub get
flutter run
```

## Sentry (Full Setup)

The app initializes Sentry only when `SENTRY_DSN` is provided via
`--dart-define` / `--dart-define-from-file`.

1. Copy `sentry.example.json` to `sentry.local.json`.
2. Put your real DSN in `SENTRY_DSN`.
3. Run with Sentry enabled:

```bash
flutter run --dart-define-from-file=sentry.local.json
```

Windows helper:

```bash
run_with_sentry.bat
```

Optional one-time verification:

- Set `"SENTRY_TEST_EVENT": "true"` in `sentry.local.json`.
- Start the app once. A startup test message is sent.
- Set it back to `"false"` afterward.

## Business location — worldwide regions & districts

The business-details onboarding step lets the owner pick any country, then its
region ("Mkoa") and district ("Wilaya"). Tanzania is served from the curated
`lookups/*` data in Firestore; every other country is looked up live from the
free [Country-State-City API](https://countrystatecity.in) by
`lib/core/services/geo_lookup_service.dart`.

- Get a free key at <https://countrystatecity.in/> and put it in
  `CSC_API_KEY` (in `.env.json` locally, or as a repo secret for CI — see
  `.github/workflows/release-android.yml`).
- With no key the picker degrades gracefully: the region/district rows become
  free-text fields so onboarding is never blocked.

## Session Replay

Session Replay is enabled in [lib/main.dart](lib/main.dart) with:

- `options.replay.sessionSampleRate = 1.0`
- `options.replay.onErrorSampleRate = 1.0`
- `options.privacy.maskAllText = true`
- `options.privacy.maskAllImages = true`

Use `1.0` while testing so every session is captured. Lower `sessionSampleRate` before production if needed.

## Application Metrics

The app now emits a few basic metrics through `Sentry.metrics`:

- `app_launch` when the app starts with Sentry enabled.
- `barcode_scan` for barcode scanner success and miss events.
- `scan_to_cart_time_ms` for the time from accepted barcode to cart add.
- `sales_created` and `sales_created_amount` when an invoice is saved.
- `invoice_printed` when the receipt/share sheet is opened.
- `customer_added` when a customer is persisted through the repository.

Metrics can be extended from `lib/core/services/sentry_metrics_service.dart`.
Use `count`, `gauge`, and `distribution` there when you want to track anything
that should help you debug product behavior.

Part of the [Mali Up](../../README.md) suite.
