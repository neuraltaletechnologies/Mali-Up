# MaliUp — SaaS Business Management Suite

![Neuraltale](https://img.shields.io/badge/Neuraltale-MaliUp-6366f1?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0-blue?style=for-the-badge)
![Stack](https://img.shields.io/badge/Flutter-Fastify-informational?style=for-the-badge)

MaliUp is a cloud-native, multi-tenant SaaS mobile application designed and engineered by **Neuraltale** to empower small and medium-sized businesses (SMBs) across Africa and emerging markets. Built on a microservice architecture, MaliUp delivers a full-stack business management suite inside a single, elegant mobile application.

---

## 🏗 System Architecture

MaliUp uses a **Multi-Tenant Microservice Architecture**.

- **Frontend:** Flutter (Mobile) & Next.js (Web Dashboard).
- **Backend:** Node.js (Fastify + TypeScript) Microservices.
- **Data Layer:** PostgreSQL (Relational) + MongoDB (Document) + Redis (Cache).
- **Isolation Strategy:** Schema-per-Tenant in PostgreSQL for complete data isolation.

### Technology Stack
- **Mobile:** Flutter 3.x, BLoC/Riverpod, Drift (SQLite) for offline-first.
- **Backend:** Node.js 20 LTS, Fastify, Prisma ORM, Zod validation.
- **Infrastructure:** Docker, Kubernetes, RabbitMQ (Message Broker).

---

## 📂 Project Structure

```text
MaliUp/
├── apps/
│   ├── mobile-app/          # Flutter Mobile Application
│   └── web-app/             # Next.js Admin/Owner Dashboard
├── services/
│   ├── auth-service/        # JWT Authentication & 2FA
│   ├── user-service/        # RBAC & User Management
│   ├── tenant-service/      # Tenant Onboarding & Billing
│   ├── sales-service/       # Invoicing & POS Logic
│   ├── customer-service/    # CRM & Client Management
│   ├── inventory-service/   # Stock & Warehouse Management
│   ├── purchase-service/    # Procurement & Supplier Management
│   ├── finance-service/     # Cash Flow & Expense Tracking
│   ├── debt-service/        # Receivables & Payables
│   ├── analytics-service/   # Business Intelligence & Reports
│   ├── notification-service/ # Push, SMS & Email
│   ├── file-service/        # Document & Image Management
│   └── Payment-service/     # Payment Gateway Integration
└── docker-compose.yml       # Local Development Infrastructure
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js 20+](https://nodejs.org/)
- [Docker](https://www.docker.com/) & Docker Compose

### Local Infrastructure
Start the core services (PostgreSQL, MongoDB, Redis, RabbitMQ):
```bash
docker-compose up -d
```

### Development
1.  **Backend Services:** Each service in `/services` is a standalone Node.js application. Navigate to a service folder and run:
    ```bash
    npm install
    npm run dev
    ```
2.  **Mobile App:**
    ```bash
    cd apps/mobile-app
    flutter pub get
    flutter run
    ```

---

## 📈 Roadmap (7 Phases)

| Phase | Milestone | Deliverables | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Foundation** | Project Setup, Auth & Tenant Services | 🏁 *Current* |
| **Phase 2** | **Core Modules** | Sales, CRM, Inventory, Procurement | ⏳ |
| **Phase 3** | **Finance** | Expenses, Cash Flow, Debt Tracking | ⏳ |
| **Phase 4** | **Intelligence** | Analytics, Reports, Dashboard | ⏳ |
| **Phase 5** | **Polish** | Offline Sync, UI/UX, Notifications | ⏳ |
| **Phase 6** | **Launch** | Beta testing, Beta release | ⏳ |
| **Phase 7** | **Post-Launch** | Scaling, Multi-language (Swahili) | ⏳ |

---

## 📜 Documentation
Full Technical Architecture and Module Specifications can be found in the Internal Design Docs.

---

### Internal Use Only
Built with ❤ by **Neuraltale Engineering**
© 2026 Neuraltale Technologies. Confidential — Internal Use Only.
