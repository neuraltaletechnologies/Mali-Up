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

Part of the [Mali Up](../../README.md) suite.
