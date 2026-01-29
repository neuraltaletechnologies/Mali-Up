# Copilot Instructions for KAZIYA

## Project Overview
- **KAZIYA** is a modular SaaS business management platform for African SMEs, built with a microservices architecture.
- The system is composed of multiple independent services (auth, client, inventory, sales, payment, notification, reporting), each as a NestJS (Node.js/TypeScript) microservice.
- The frontend consists of a Flutter mobile app and a Next.js/React web dashboard.
- All services interact with a centralized, multi-tenant PostgreSQL database.

## Key Architectural Patterns
- **Service Boundaries:** Each business domain (auth, client, inventory, etc.) is a separate microservice. Communication is via REST APIs and WebSockets.
- **API Gateway:** Handles routing and authentication for backend services.
- **Data Model:** Centralized PostgreSQL with entities like User, Business, Client, Product, Sale/Order, Payment, Report, Notification. See README for relationship diagrams.
- **Messaging:** Redis is used for notifications, caching, and real-time updates. Firebase Cloud Messaging is used for push notifications.
- **Payments:** Integrates with M-Pesa, Tigo Pesa, Airtel Money via dedicated payment service.

## Developer Workflows
- **Source Control:** GitHub, GitFlow branching (feature, develop, main). Daily commits, weekly releases.
- **Build & Deploy:**
  - Backend: CI/CD via GitHub Actions, deploys to Railway/Supabase.
  - Flutter: Built with Expo EAS for Android/iOS.
  - Web: Hosted on Vercel/Supabase.
- **Testing:** Unit, integration, and end-to-end tests are expected for all services. Use Postman/Swagger UI for API testing.
- **Environment:** All secrets/configs are managed via `.env` files.

## Project Conventions
- **Microservice Structure:** Each service lives in its own directory (e.g., `auth-service/`, `client-service/`).
- **API Standards:** Use RESTful conventions (GET, POST, PUT, DELETE), JWT for authentication, and Swagger/OpenAPI for docs.
- **RBAC:** Role-based access (Owner, Manager, Staff) enforced in auth service.
- **Logging:** All critical operations are logged for audit.
- **Security:** HTTPS/TLS, bcrypt for password hashing, regular DB backups.

## Integration Points
- **Frontend ↔ Backend:** Mobile/web clients communicate with backend via REST APIs and WebSockets.
- **Payments:** Payment service integrates with mobile money APIs.
- **Notifications:** Notification service uses Firebase and Redis.

## References
- See [README.md](../README.md) for full architecture, data model, and workflow details.
- Example service directories: `auth-service/`, `client-service/`, `inventory-service/`, etc.
- Example Flutter structure: `kaziya_app/lib/screens/`, `kaziya_app/lib/services/`, etc.

---
**For AI agents:**
- Always follow the modular microservice pattern.
- Reference the README for data models and service boundaries before making architectural changes.
- Use existing service directories as templates for new modules.
- Ensure all new APIs are documented with Swagger/OpenAPI.
- Adhere to RBAC and security practices as described above.
