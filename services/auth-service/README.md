# Maliapp Auth Service

Microservice responsible for high-security authentication and authorization across the Maliapp ecosystem.

## 🚀 Responsibilities
- User registration and login flow.
- JWT Access and Refresh token management (RS256).
- Two-Factor Authentication (2FA) via TOTP.
- Session invalidation and security audits.
- Password/OTP verification logic.

## 🛠 Tech Stack
- **Runtime:** Node.js 20
- **Framework:** Fastify + TypeScript
- **ORM:** Prisma
- **Auth:** Argon2 (Password hashing), Passport.js/Fastify-Auth
- **Communication:** REST API, RabbitMQ

## 📊 Endpoints
- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/refresh`
- `POST /auth/2fa/verify`

---
Part of the [Maliapp](../../README.md) suite by **Neuraltale**.
