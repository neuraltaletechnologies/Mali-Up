# Mali Up - Business Edition

![Neuraltale](https://img.shields.io/badge/Neuraltale-Mali%20Up-0D1B3E?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-B%201.0-1A6E8A?style=for-the-badge)
![Stack](https://img.shields.io/badge/Flutter-Firebase-Riverpod-059669?style=for-the-badge)

Mali Up B v1.0 is the current business-only MVP for Tanzanian small business owners. It is a premium fintech-style Flutter app backed by Firebase, Riverpod, and a feature-first architecture that is ready to grow into a microservice-based platform later.

## The Current Scope

The MVP ships only five core modules:

- Hali ya biashara
- Tuma ankara
- Wateja wangu
- Gharama zangu
- Bidhaa zangu

All personal finance modules and advanced business modules are deferred to later phases and preserved in the architecture document.

## Architecture

| Area | Current Decision |
| --- | --- |
| Mobile app | Flutter 3.x |
| State management | Riverpod from day one |
| Data access | Repository interfaces over Firestore |
| Backend direction | Microservice-ready, Cloud Functions later |
| UI style | Premium Fintech White |
| Language | Swahili-first, English fallback |

## Repository Layout

```text
Mali-Up/
├── apps/
│   ├── mobile-app/   # Current MVP app
│   └── web-app/      # Product site / future web shell
├── services/         # Future backend service contracts
├── docs/             # Source-of-truth architecture docs
└── docker-compose.yml
```

## Getting Started

### Mobile App

```bash
cd apps/mobile-app
flutter pub get
flutter run
```

### Web App

```bash
cd apps/web-app
pnpm install
pnpm dev
```

## Roadmap

| Phase | Timeline | Focus |
| --- | --- | --- |
| Phase 1 | Weeks 1-8 | Business MVP: auth, dashboard, invoices, customers, expenses, inventory |
| Phase 2 | Weeks 9-12 | M-Pesa integration, subscription paywall, push notifications, Play Store launch |
| Phase 3 | v1.5 | Personal finance modules, Drift offline support, GoRouter |
| Phase 4 | v2.0 | Context engine, multi-business, full business suite, staff roles, iOS launch |

## Documentation

The current blueprint lives in [docs/MaliUp_v3.0.md](docs/MaliUp_v3.0.md).

### Internal Use Only

Built by Neuraltale Engineering for internal product development.
