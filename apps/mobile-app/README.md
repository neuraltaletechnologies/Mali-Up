# Maliapp Mobile — Flutter App

The flagship mobile application for the Maliapp SaaS ecosystem. Built with Flutter to provide a premium, offline-first experience for business owners and staff.

## 🛠 Tech Stack
- **Framework:** Flutter 3.x
- **State Management:** BLoC + Riverpod
- **Local Database:** Drift (SQLite) for offline persistence
- **HTTP Client:** Dio with interceptors and retry logic
- **Navigation:** GoRouter
- **Charts:** fl_chart for business analytics

## 🏛 Clean Architecture
The app follows a strict Clean Architecture pattern:
- **Presentation Layer:** Flutter Widgets, Cubits/BLoCs
- **Domain Layer:** Business Entities, Use Cases, Repository Interfaces
- **Data Layer:** API Clients, DTOs, Repository Implementations, Local SQLite

## 📦 Getting Started
1. Ensure Flutter is installed.
2. Run `flutter pub get` to fetch dependencies.
3. Run `flutter gen-l10n` for localization.
4. Run `flutter run`.

## 🔄 Offline Strategy
- All frequently accessed data (Sales, Inventory, Customers) is cached locally.
- Optimistic UI updates ensure a snappy experience without network lag.
- Automatic background synchronization when connectivity is restored.
- Persistence queue to ensure data integrity during intermittent connectivity.

---
Part of the [Maliapp](../../README.md) suite by **Neuraltale**.
