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
dart run slang                   # regen lib/i18n/gen/strings.g.dart after editing lib/i18n/*.i18n.json
```

The app ships no third-party crash reporter (`sentry_flutter` was removed for app size). Caught non-fatal errors flow through `lib/core/services/error_reporter.dart` (`ErrorReporter`), which only logs in debug — that's the single hook to wire `firebase_crashlytics` into if it's wanted back.

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

## Branching & releases

`main` is the **live branch** — whatever is on `main` is what deploys.

- **Never commit or push directly to `main`.** All work goes on feature
  branches (or the shared `dev` integration branch), then a PR.
- `dev` is the integration branch: feature branches merge here first for
  testing. Release by opening a PR `dev → main` (or merge a feature branch
  straight into `main` for an isolated web-only or mobile-only change).
- **Merging a reviewed PR into `main` is the release.** There is no
  separate promotion step, no "approve don't merge" rule — merge means ship.
  - `apps/admin/**` changed → Cloudflare rebuilds the `mali-up` Worker
    (it watches the `main` branch; scoped to `apps/admin/**` once
    `.github/scripts/set-cloudflare-build-watch-paths.sh` has run).
  - `apps/mobile-app/**` changed → `.github/workflows/release-android.yml`
    ships a Play Store **Open Testing** release (not the production track;
    promote Open Testing → Production manually in Play Console).
  - A web-only merge never triggers the Android release, and vice versa
    (both are path-filtered).
- After a `dev → main` release, sync `dev` back up (`git merge main` into
  `dev`, or rebase) so it doesn't drift far behind.
- There is **no `production` branch** — it was removed when `main` became
  the live branch. Ignore any GitHub banner suggesting a PR between
  long-lived branches other than `dev → main`.

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

Swahili-first, English fallback — every user-facing string needs both. Two coexisting patterns:

- **Existing screens (legacy pattern, don't migrate)**: static string classes with `(String language)` getters or En/Sw constant pairs (`lib/core/constants/app_strings.dart`, per-feature `strings/` files), or a local `String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);` helper called inline. Keyed off `LocalizationService.languageNotifier` (`AppLanguage.english` / `.swahili`). Leave these as they are — don't rewrite a screen's existing strings into the slang pattern below just because you're touching it.
- **New features (convention going forward): `package:slang`**. Add/extend `lib/i18n/en.i18n.json` and `lib/i18n/sw.i18n.json` (plain nested JSON, one object per locale, keys shared across both files), run `dart run slang` to regen `lib/i18n/gen/strings.g.dart` (gitignored, excluded from analysis like other `*.g.dart`), then read strings via the generated global `t` accessor, e.g. `t.someFeature.title`. Like Drift/Freezed output, `lib/i18n/gen/*.g.dart` is committed, not gitignored — regen and commit it whenever the `.i18n.json` files change. Use the plain `t` getter, not `context.t` — `main.dart`'s `MaterialApp.router` already sits under a `ValueListenableBuilder<AppLanguage>` on `LocalizationService.languageNotifier`, so the whole tree already rebuilds on language change; no `TranslationProvider` wrapping is wired up. `LocalizationService._applyLanguage` (called from `setLanguage`/`changeLanguage`/`initializeWithPrefs`/`resetLanguageSelection`) keeps slang's `LocaleSettings` in sync automatically — `LocalizationService.languageNotifier` stays the single source of truth for current language, slang just mirrors it. `slang.yaml` sets `lazy: false` so both locales are compiled in and available synchronously offline (no deferred/on-demand loading) — don't change that without checking offline behavior.
- The shared `l10n/` JSON (`l10n/translations/en.json`, `sw.json`) is a **terminology reference only** — nothing in mobile/web/backend actually loads it at build or runtime. Use it (and `l10n/DEVELOPER_STYLE_GUIDE.md` / the terminology dictionary) to pick consistent Kiswahili wording, but it is not a data source to wire up.

### Auth & security

Firebase-only: phone lookup reads Firestore directly; users sign in with a PIN-derived Firebase Auth password; PIN recovery via Firebase password reset. `SecurityService` drives an app-level PIN lock — the app locks when backgrounded (`AppLifecycleState.paused`) and `main.dart` renders `PinLockScreen` as a standalone MaterialApp on top of everything while locked.

### Conventions

- Lints: `flutter_lints` plus `prefer_single_quotes`, `prefer_final_locals`, `prefer_const_constructors` (see `analysis_options.yaml`). Generated `*.g.dart` / `*.freezed.dart` are excluded from analysis.
- UI follows the "Premium Fintech White" system — colors in `lib/core/theme/app_colors.dart` (`navyPrimary #0D1B3E`, `tealAccent #1A6E8A`, `yellowBrand #FFC107`).
- Product metrics go through `lib/core/services/sentry_metrics_service.dart` (`SentryMetricsService` — name kept, no longer Sentry-backed; every method is a debug-only no-op until a sink like `firebase_analytics` is wired into `_record`).
