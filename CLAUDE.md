# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Mali Up — a Swahili-first business management app for Tanzanian SMEs, built by Neuraltale. Monorepo:

- `apps/mobile-app/` — the Flutter MVP app. **Almost all active development happens here.**
- `apps/web-app/` — Next.js 16 product site (pnpm, Tailwind 4, Radix UI).
- `services/` — future backend microservices (Fastify + TypeScript + Prisma + firebase-admin). Most are empty placeholders; `auth-service` is the most developed. **The mobile app does not call these** — it is Firebase-only (Auth, Firestore, Storage, Cloud Functions).
- `l10n/` — shared translation JSON (`translations/en.json`, `sw.json`) plus `DEVELOPER_STYLE_GUIDE.md` and `TERMINOLOGY_DICTIONARY.md`.
- `docs/MaliUp_v3.0.md` — architecture blueprint / source of truth for roadmap decisions.
- `docker-compose.yml` — Postgres, MongoDB, Redis for the future backend services only.

Note: `.github/copilot-instructions.md` describes the aspirational microservice architecture (NestJS, central PostgreSQL). The actual code differs — services are Fastify, and the shipping mobile app talks directly to Firebase with no custom backend.

## Commands

### Mobile app (run from `apps/mobile-app/`)

```bash
flutter pub get
flutter run
flutter analyze                  # or run_analyze.bat from repo root
flutter test                     # all tests
flutter test test/core/database/invoice_dao_test.dart   # single test file
dart run build_runner build --delete-conflicting-outputs # regen Drift/Freezed *.g.dart
```

Sentry is enabled only when `SENTRY_DSN` is provided: copy `sentry.example.json` → `sentry.local.json`, then `flutter run --dart-define-from-file=sentry.local.json` (or `run_with_sentry.bat`).

### Web app (run from `apps/web-app/`)

```bash
pnpm install
pnpm dev
pnpm build      # runs scripts/generate-sitemap.mjs first
pnpm lint
```

### auth-service (run from `services/auth-service/`)

```bash
npm run dev               # nodemon + ts-node
npm run build && npm start
npm run prisma:generate / prisma:migrate
```

## Mobile app architecture

Feature-first layout under `lib/`:

- `lib/features/<feature>/` — `data/` (repositories, mappers, providers), `domain/models/`, `presentation/` (screens, providers, widgets). Features: auth, dashboard, invoice, customer, inventory, finance, product, sales, debt, onboarding, security, settings, rbac, team, reports…
- `lib/core/` — database (Drift), sync engine, shared services, providers, theme, localization.
- `lib/config/routing.dart` — GoRouter setup; route constants live in `AppRoutes`.
- `lib/shared/widgets/` — reusable UI (`mali_components.dart`, `main_shell_page.dart`, etc.).

State management is Riverpod (`flutter_riverpod`), with some app-level state on static `ValueNotifier`s (`LocalizationService`, `SecurityService`, `MotionService`).

### Offline-first sync (the most important pattern)

Drift (SQLite) is the **source of truth**; Firestore's own persistence cache is deliberately disabled in `main.dart` to avoid dual-cache inconsistency. Each synced entity (invoice, customer, expense, inventory) follows a three-repository pattern:

- `local_<entity>_repository.dart` — Drift reads/writes.
- `remote_<entity>_repository.dart` — Firestore, scoped by `uid` + `businessId`.
- `sync_<entity>_repository.dart` — the only implementation the UI uses. Reads always come from Drift; writes commit the entity **and** a sync-queue entry in a single SQLite transaction.

`lib/core/sync/sync_service.dart` drains the queue to Firestore (batched, retry-capped), listens for connectivity changes, and uses `ConflictResolver` for conflicts and `OfflinePolicyNotifier` for offline write policy. Drift tables/DAOs live in `lib/core/database/`; DAO tests in `test/core/database/` use `test_helpers.dart` for an in-memory database.

When adding a new synced entity, mirror this whole chain: table + DAO + mapper + the three repositories + wiring into `SyncService`.

### Localization

Swahili-first, English fallback — every user-facing string needs both. The app currently uses static string classes with `(String language)` getters or En/Sw constant pairs (`lib/core/constants/app_strings.dart`, per-feature `strings/` files), keyed off `LocalizationService.languageNotifier` (`'sw'` / `'en'`). The shared `l10n/` JSON uses nested namespaces (`common`, `finance`, `errors`, …) that must stay consistent across mobile/web/backend — see `l10n/DEVELOPER_STYLE_GUIDE.md` and use the terminology dictionary for Kiswahili terms.

### Auth & security

Firebase-only: phone lookup reads Firestore directly; users sign in with a PIN-derived Firebase Auth password; PIN recovery via Firebase password reset. `SecurityService` drives an app-level PIN lock — the app locks when backgrounded (`AppLifecycleState.paused`) and `main.dart` renders `PinLockScreen` as a standalone MaterialApp on top of everything while locked.

### Conventions

- Lints: `flutter_lints` plus `prefer_single_quotes`, `prefer_final_locals`, `prefer_const_constructors` (see `analysis_options.yaml`). Generated `*.g.dart` / `*.freezed.dart` are excluded from analysis.
- UI follows the "Premium Fintech White" system — colors in `lib/core/theme/app_colors.dart` (`navyPrimary #0D1B3E`, `tealAccent #1A6E8A`, `yellowBrand #FFC107`).
- Product metrics go through `lib/core/services/sentry_metrics_service.dart` (`count`/`gauge`/`distribution`).
