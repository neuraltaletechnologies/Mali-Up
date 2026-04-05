# MaliUp Tenant Service

Microservice managing the multi-tenant infrastructure, onboarding, and SaaS subscriptions.

## 🚀 Responsibilities
- Tenant registration and schema provisioning.
- Subscription plan management (Pricing tiers).
- Tenant-specific application settings.
- Billing integration for SaaS fees.
- Logic for logical isolation of business data.

## 🛠 Tech Stack
- **Runtime:** Node.js 20
- **Framework:** Fastify + TypeScript
- **ORM:** Prisma
- **Database:** PostgreSQL (Public Schema)
- **Messaging:** RabbitMQ (Publishes `tenant.created` events)

---
Part of the [MaliUp](../../README.md) suite by **Neuraltale**.
