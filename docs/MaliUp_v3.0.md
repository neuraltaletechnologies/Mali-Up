# Mali Up v3.0 - Business Edition

## Current Blueprint for Mali Up B v1.0

**Product:** Mali Up (Business Edition)  
**Current Build:** Mali Up B v1.0  
**Target Market:** Tanzanian small business owners  
**Primary Language:** Swahili-first, English fallback  
**Design Direction:** Premium Fintech White  
**Architecture Direction:** Feature-First Clean Architecture, Riverpod from day one, microservice-ready data layer

> This document is the current source of truth for the app we are building now. The original hybrid personal/business vision is preserved in the future roadmap and appendix sections.

## 1. Executive Summary

Mali Up B v1.0 is a business-only MVP for Tanzanian entrepreneurs who need a clean, premium, mobile-first tool for running daily business operations. The product focuses on the highest-value workflow first: dashboard visibility, invoicing, customers, expenses, and inventory.

The v3.0 direction intentionally narrows scope so the solo developer can ship faster, validate the market, and build a stable foundation that can later expand into the full microservice platform vision.

### 1.1 Product Identity

| Item | Decision |
| --- | --- |
| Product name | Mali Up (Business Edition) |
| Current version | Mali Up B v1.0 |
| Target users | Tanzanian small business owners only |
| Primary mode | Business only |
| Core promise | Run business money, customers, invoices, and stock from one premium app |

### 1.2 Positioning

- Business-first, not hybrid.
- Premium fintech feel, not generic ERP.
- Swahili-first, with English as fallback.
- Built for speed, clarity, and trust.
- Future-ready for Cloud Functions and microservices without redesigning the UI.

### 1.3 Monetization

| Plan | Price | Limits | Notes |
| --- | --- | --- | --- |
| Free | TZS 0 | Up to 20 invoices per month | Core MVP access |
| Premium | TZS 3,000/month | Unlimited usage | Includes future M-Pesa import support |

Initial M-Pesa verification will be manual. Premium payment validation can later move to automated integration once the product has market traction.

## 2. Scope Definition

### 2.1 Built Now

Only five core business modules are in scope for Mali Up B v1.0:

| ID | Module | Swahili-first label | Status |
| --- | --- | --- | --- |
| B1 | Dashboard | Hali ya biashara | Build now |
| B2 | Invoicing | Tuma ankara | Build now |
| B3 | Customers | Wateja wangu | Build now |
| B4 | Expenses | Gharama zangu | Build now |
| B5 | Inventory | Bidhaa zangu | Build now |

### 2.2 Deferred Scope

All personal finance modules and advanced business modules are deferred to future phases.

| Group | Modules |
| --- | --- |
| Personal finance v1.5+ | P1 Income Tracker, P2 Expenses, P3 Savings Pots, P4 Budget Planner, P5 Bills, P6 Debts, P7 Financial Goals, P8 Net Worth |
| Advanced business v2.0+ | B6 Cash Flow, B7 Purchase & Supplier, B8 Profit & Reports, B9 Staff / Roles, B10 Advanced Administration |

## 3. Architecture

### 3.1 Feature-First Clean Architecture

The app is organized by feature rather than by technical layer alone. Each feature owns its screens, state, use cases, and repository contracts.

| Layer | Responsibility |
| --- | --- |
| Presentation | Screens, widgets, forms, view state, and UI composition |
| Domain | Models, repository interfaces, use cases, and business rules |
| Data | FirestoreService, AuthService, repository implementations, and remote data mapping |

### 3.2 Microservice-Ready Data Design

The data layer is intentionally abstracted behind repository interfaces so the UI never talks directly to Firestore details. In v1.0, repository implementations call Firestore directly for speed and simplicity. Later, the same interfaces can be swapped to Cloud Functions or other backend services without changing the presentation layer.

That means the app is microservice-ready even though the MVP is not microservice-heavy yet.

### 3.3 Asynchronous Contract

Repositories should expose asynchronous contracts by default:

- `Future` for one-time operations such as create, update, delete, and dashboard aggregation.
- `Stream` for live collections such as invoices, customers, expenses, and inventory.

Example repository contracts:

- `InvoiceRepository`
- `CustomerRepository`
- `ExpenseRepository`
- `InventoryRepository`
- `DashboardRepository`

This keeps the code ready for a future backend split into Cloud Functions and microservices without rewriting the app shell.

## 4. Riverpod State Management

Riverpod is the state system from day one. The MVP uses a simplified and practical subset:

- `StateProvider`
- `StreamProvider`
- `StateNotifierProvider`

Future adoption of `Notifier` and `AsyncNotifier` can happen later once the codebase grows.

### 4.1 Core Providers

| Provider | Type | Purpose |
| --- | --- | --- |
| `authStateProvider` | `StreamProvider` | Auth session stream |
| `currentUserIdProvider` | `StateProvider` | Cached current user id |
| `isLoggedInProvider` | `StateProvider` | Simple login flag |
| `userProfileProvider` | `StreamProvider` or `FutureProvider` | User profile data |
| `dashboardDataProvider` | `FutureProvider` | Aggregated dashboard metrics |
| `invoicesProvider` | `StreamProvider` | Live invoice collection |
| `customerProvider` | `StreamProvider` | Live customer collection |
| `expenseProvider` | `StreamProvider` | Live expense collection |
| `inventoryProvider` | `StreamProvider` | Live inventory collection |

### 4.2 Form State

Form flows should use small `StateNotifier` classes for:

- Create invoice
- Add customer
- Add expense
- Add stock item
- Update settings

That keeps local form state isolated from remote stream state.

## 5. Firebase & Firestore

### 5.1 Data Structure

The business data lives under a business-scoped path.

| Collection | Purpose |
| --- | --- |
| `business/{userId}/invoices` | Invoice documents |
| `business/{userId}/customers` | Customer records |
| `business/{userId}/expenses` | Business expense records |
| `business/{userId}/inventory` | Product and stock records |
| `business/{userId}/settings` | App preferences and business settings |

### 5.2 Dashboard Aggregation Methods

Dashboard data should be derived through repository aggregation methods rather than hardcoded UI logic.

Recommended metrics:

- Total invoice count
- Paid, sent, draft, and overdue counts
- Revenue today / this week / this month
- Expense totals by date range
- Low stock count
- Top customers by sales value
- Outstanding balances

These methods can later move into Cloud Functions without changing the screen layer.

### 5.3 Personal Collections

Personal finance collections remain in the design as `v1.5+` only. They exist in the long-term vision, but they are not part of the current build scope.

### 5.4 Security Rules Direction

The MVP can allow direct client access where appropriate for speed, but the rules must be shaped so the future transition is simple:

- v1.0: direct client reads and writes where permitted.
- later: block direct writes.
- later: route mutations through Cloud Functions.

The goal is to avoid a security-rules rewrite when backend services are introduced.

## 6. UI Design System

### 6.1 Premium Fintech White

| Token | Hex | Usage |
| --- | --- | --- |
| `navyPrimary` | `#0D1B3E` | Primary brand color, hero cards, buttons |
| `tealAccent` | `#1A6E8A` | Secondary accent, charts, links |
| `yellowBrand` | `#FFC107` | Primary CTA, badges, highlights |
| `purpleAccent` | `#7C3AED` | Reserved for future or special states |
| `surfaceLight` | `#F8F9FC` | App background |
| `cardWhite` | `#FFFFFF` | Cards and surfaces |
| `successGreen` | `#059669` | Paid and success states |
| `warningAmber` | `#D97706` | Caution states |
| `dangerRed` | `#DC2626` | Error and overdue states |
| `borderGray` | `#E2E8F0` | Borders and dividers |

### 6.2 Typography

| Style | Font | Usage |
| --- | --- | --- |
| Body | DM Sans | Standard UI copy and labels |
| Hero amounts | DM Serif Display | Large financial figures |
| Monetary values | JetBrains Mono | Amounts, codes, and totals |

### 6.3 Core Components

| Component | Purpose |
| --- | --- |
| `MaliCard` | Standard white card container |
| `PrimaryButton` | Yellow CTA button |
| `SecondaryButton` | Navy action button |
| `GhostButton` | Quiet secondary action |
| `AmountDisplay` | Large formatted money display |
| `StatusChip` | Paid, sent, overdue, draft labels |
| `EmptyState` | Friendly no-data UI |
| `HeroCard` | Business hero card with navy-to-teal gradient |
| `ContextSwitcher` | Reserved for future context mode support |

## 7. Language & UX

### 7.1 Swahili-First Rule

Every label, button, notification, and empty state should be Swahili-first. English is a fallback, not the default voice.

### 7.2 Module Naming

| English | Swahili-first label |
| --- | --- |
| Business dashboard | Hali ya biashara |
| Sales / invoicing | Tuma ankara |
| Customers | Wateja wangu |
| Expenses | Gharama zangu |
| Inventory | Bidhaa zangu |

### 7.3 Tone of Voice

- Speak like a helpful Tanzanian business assistant, not like enterprise software.
- Keep prompts short, direct, and respectful.
- Encourage action without sounding pushy.
- Use friendly accountability, especially around money and overdue items.
- Avoid jargon unless the user is clearly in an advanced accounting flow.

Examples:

- `Uko tayari kutuma ankara?`
- `Karibu, leo una salio la mauzo la TZS 240,000.`
- `Onyo: bidhaa za bidhaaa hii ziko karibu kuisha.`
- `Fuatilia gharama zako haraka kabla mwezi haujaisha.`

## 8. Monetization

Mali Up B v1.0 uses a simple freemium model that is easy to explain and easy to sell:

- Free plan: up to 20 invoices per month.
- Premium plan: TZS 3,000 per month.
- Premium unlocks unlimited usage and later M-Pesa import support.

M-Pesa verification starts as a manual workflow, then can be automated later once the product and payment flow are stable.

## 9. AI-Assisted Development Strategy

The build process is prompt-first and AI-assisted. Cursor and Windsurf are used as implementation accelerators, but this document remains the single source of truth.

### 9.1 Workflow

1. Update this document first.
2. Derive implementation tasks from the document.
3. Generate or refine code feature by feature.
4. Keep UI, state, and data contracts aligned with the blueprint.
5. Revisit the document before major changes so the code stays consistent.

### 9.2 Practical Rule

If a code change conflicts with this document, the document wins until the product direction changes intentionally.

## 10. Development Roadmap

### 10.1 Phased Plan

| Phase | Timeline | Deliverables |
| --- | --- | --- |
| Phase 1 | Weeks 1-8 | Business MVP: auth, dashboard, 5 modules, UI polish, testing |
| Phase 2 | Weeks 9-12 | M-Pesa integration, subscription paywall, push notifications, Play Store launch |
| Phase 3 | v1.5 | Personal finance modules P1-P8, Drift offline support, GoRouter |
| Phase 4 | v2.0 | Context engine, multi-business, full business suite, staff roles, iOS launch |

### 10.2 Phase 1 Delivery Rule

Phase 1 must stay focused on the five core business modules. Anything outside that scope belongs to later phases.

## 11. Future Vision and Appendix

### 11.1 Future Business Expansion

| Area | Future Scope |
| --- | --- |
| Cash flow | B6 and beyond |
| Supplier management | Procurement and purchase workflows |
| Reports | Profit, loss, tax, and cash flow statements |
| Staff roles | Multi-user permissions |
| Multi-business | Switch between multiple businesses |

### 11.2 Personal Finance Vision v1.5+

| Module | Label |
| --- | --- |
| P1 | Income Tracker |
| P2 | Personal Expenses |
| P3 | Savings Pots |
| P4 | Budget Planner |
| P5 | Bills & Subscriptions |
| P6 | Personal Debts |
| P7 | Financial Goals |
| P8 | Net Worth Overview |

### 11.3 Long-Term Architecture Vision

The long-term vision still includes:

- Microservice-backed backend services.
- Cloud Functions for privileged writes and scheduled tasks.
- Multi-business support.
- Context engine for personal and business modes.
- iOS expansion after Android validation.

## 12. What Changed from the Original v2.0 Document

| Original v2.0 Direction | v3.0 / B v1.0 Decision |
| --- | --- |
| Hybrid personal + business platform | Business-only MVP first |
| 18 modules in scope | 5 core business modules now |
| Context engine immediately | Deferred to future phase |
| Broad product vision first | Focused Tanzanian SMB validation first |
| Multiple advanced business modules now | Moved to future phases |
| Complex backend-first rollout | Direct Firestore MVP with microservice-ready interfaces |
| Generic business tone | Swahili-first, Tanzanian, human tone |
| Larger enterprise-style stack | Feature-first Flutter app with Riverpod and repository abstraction |
| No clear monetization constraint | Freemium with TZS 3,000 premium plan |

### Final Summary

Mali Up v3.0 is the practical build plan for the current reality: a solo developer shipping a premium business MVP for Tanzania now, while preserving the original larger vision for later phases.
