# Mali Up Mobile

The current Mali Up B v1.0 app is a business-only Flutter product for Tanzanian small business owners. It uses a premium fintech white UI, Swahili-first labels, and Riverpod from day one.

## Current MVP Modules

- Hali ya biashara
- Tuma ankara
- Wateja wangu
- Gharama zangu
- Hisa zangu

## Architecture

| Layer | Responsibility |
| --- | --- |
| Presentation | Screens, widgets, forms, and view state |
| Domain | Models, repository interfaces, and use cases |
| Data | FirestoreService, AuthService, and repository implementations |

The data layer is repository-driven so the app can move to Cloud Functions or service-backed APIs later without rewriting the UI.

## State Management

Riverpod is the primary state system.

- `authStateProvider`
- `currentUserIdProvider`
- `isLoggedInProvider`
- `userProfileProvider`
- `dashboardDataProvider`
- `invoicesProvider`
- `customerProvider`
- `expenseProvider`
- `inventoryProvider`

Form state should use small `StateNotifier` classes, while simple and live state should use `StateProvider` and `StreamProvider`.

## UI Direction

The app uses the Premium Fintech White system:

- `navyPrimary` `#0D1B3E`
- `tealAccent` `#1A6E8A`
- `yellowBrand` `#FFC107`
- `surfaceLight` `#F8F9FC`
- `cardWhite` `#FFFFFF`

Core components include `MaliCard`, `PrimaryButton`, `SecondaryButton`, `GhostButton`, `AmountDisplay`, `StatusChip`, `EmptyState`, and `HeroCard`.

## Getting Started

```bash
flutter pub get
flutter run
```

Localization should stay Swahili-first with English as fallback.

## Note

Personal finance features, context switching, and advanced business modules are intentionally out of scope for the current MVP and are planned for later phases.

Part of the [Mali Up](../../README.md) suite.
