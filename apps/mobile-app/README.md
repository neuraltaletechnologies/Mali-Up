# Mali Up Mobile

Mali Up Mobile is a Swahili-first Flutter app for Tanzanian SMEs.

## Current Stack

- Flutter + Riverpod UI
- Firebase Auth for identity
- Cloud Firestore for onboarding, business, customer, and app state
- Firebase Storage for media

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

## Crash & error reporting

The app ships **no** third-party crash reporter. `sentry_flutter` was removed
to cut ~1.5 MB of native code from every install — release builds never carried
a `SENTRY_DSN`, so it was inert in production anyway. Caught, non-fatal errors
go through `lib/core/services/error_reporter.dart` (`ErrorReporter`), which
only logs in debug. Wire `firebase_crashlytics` into that one file if crash
reporting is wanted back — it is cheap on top of the Firebase SDK already
bundled.

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

## Application Metrics

`lib/core/services/sentry_metrics_service.dart` (`SentryMetricsService` — name
kept for now, no longer Sentry-backed) exposes typed counters —
`salesCreated`, `barcodeScan`, `customerAdded`, `invoicePrinted`, … — called
throughout the app. Every method is currently a **no-op** that only logs in
debug. Point `_record` at `firebase_analytics` (or another sink) to collect
product metrics again.

Part of the [Mali Up](../../README.md) suite.
