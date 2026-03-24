

---

# MALIAPP – Smart Business Management Platform (Modular Microservices MVP)

**Product Name:** MALIAPP
**Developed by:** Neuraltale Technologies
**Product Type:** SaaS – Business Operations & Management Platform
**Target Market:** SMEs & Growing Businesses in Africa
**Version:** 1.0 (MVP)
**Status:** Full Technical Documentation – Modular Microservices

---

## Table of Contents

1. [Overview](#1-overview)
   1.1 [Project Description](#11-project-description)
   1.1.1 [Major Components and Business Processes](#111-major-components-and-business-processes)
   1.1.2 [Simplified Business Flow](#112-simplified-business-flow)
   1.2 [Data Model](#12-data-model)
   1.2.1 [Primary Data Entities and Relationships](#121-primary-data-entities-and-relationships)
   1.2.2 [Simplified Relationship Summary](#122-simplified-relationship-summary)
   1.3 [Technology](#13-technology)
   1.3.1 [Core Technologies](#131-core-technologies)
   1.3.2 [Development Methodology](#132-development-methodology)
   1.4 [Development Tools](#14-development-tools)
   1.4.1 [Primary Tools and Environments](#141-primary-tools-and-environments)
   1.4.2 [Source Control](#142-source-control)
   1.4.3 [Deployment Process](#143-deployment-process)
   1.5 [Interfaces and Services](#15-interfaces-and-services)
   1.5.1 [Primary Interfaces](#151-primary-interfaces)
   1.5.2 [Interface Setup](#152-interface-setup)
   1.5.3 [API Standards](#153-api-standards)
   1.6 [Access, Authentication, and Authorization](#16-access-authentication-and-authorization)
2. [Role-Based Functionalities](#2-role-based-functionalities)
   2.1 [Administrator](#21-administrator)
   2.2 [Business Staff / Manager](#22-business-staff--manager)
   2.3 [Client / Customer](#23-client--customer)
3. [System Design Overview](#3-system-design-overview)
4. [System Module Integration](#4-system-module-integration)
5. [Flutter Project Structure](#5-flutter-project-structure)
6. [Backend Microservices Architecture](#6-backend-microservices-architecture)
7. [Database Schema](#7-database-schema)
8. [Deployment Strategy](#8-deployment-strategy)
9. [Security & Data Protection](#9-security--data-protection)
10. [Scalability & Future Enhancements](#10-scalability--future-enhancements)
11. [Ownership & Licensing](#11-ownership--licensing)

---

## 1. Overview

### 1.1 Project Description

MALIAPP is an **African-built, modular SaaS business management platform** that enables SMEs to handle **clients, inventory, sales, payments, and insights** in a unified ecosystem. Unlike complex ERP systems, MALIAPP is designed for **ease-of-use, affordability, and mobile-first accessibility**, targeting African businesses that need online-first solutions.

**Major Goals:**

* Simplify day-to-day business operations
* Enable real-time, online management
* Provide scalable multi-device access (mobile + web)
* Build modular microservices ready for expansion

---

### 1.1.1 Major Components and Business Processes

| Component              | Function             | Core Business Process                                           |
| ---------------------- | -------------------- | --------------------------------------------------------------- |
| MALIAPP App             | Flutter Mobile App   | Client management, inventory, sales orders, payments, reporting |
| Web Dashboard          | Admin / Owner portal | Reports, analytics, multi-branch management, user roles         |
| Auth Service           | Microservice         | Login, registration, JWT, password & OTP verification           |
| Client Service         | Microservice         | CRM, client history, balances, notes,                            |
| Inventory Service      | Microservice         | Products, stock tracking, supplier info, alerts                 |
| Sales & Orders Service | Microservice         | Sales, invoices, order tracking, payment statuses               |
| Payment Service        | Microservice         | Online payments, mobile money, escrow, commissions              |
| Reporting Service      | Microservice         | Sales summaries, top products, insights, AI forecasts           |
| Notification Service   | Microservice         | Email, SMS, push notifications                                  |

---

### 1.1.2 Simplified Business Flow

1. User registers → assigned role (Owner / Manager / Staff)
2. Staff adds clients, products, and suppliers
3. Sales order created → stock validated → invoice generated
4. Payment recorded → client balance updated → notification sent
5. Dashboard & reports updated in real-time
6. Admin/Owner monitors activity and generates analytics

---

## 1.2 Data Model

MALIAPP follows a **centralized, multi-tenant data model** that supports modular microservices. All modules interact through APIs with the central PostgreSQL database.

### 1.2.1 Primary Data Entities and Relationships

| Entity       | Description           | Relationships                                     |
| ------------ | --------------------- | ------------------------------------------------- |
| User         | Owner, manager, staff | Linked to businesses, roles, activities           |
| Business     | SME or company        | Linked to users, clients, products, orders        |
| Client       | Customers of business | Linked to sales, payments                         |
| Product      | Inventory items       | Linked to sales, stock logs                       |
| Sale / Order | Sales transactions    | Linked to clients, products, payments             |
| Payment      | Records payments      | Linked to sales, clients                          |
| Report       | Analytics data        | Aggregates sales, inventory, and performance      |
| Notification | Messages to users     | Linked to events (payment, stock, client updates) |

---

### 1.2.2 Simplified Relationship Summary

```
[User] ── [Business] ── [Client]
             │
             ├── [Product] ── [Sale / Order] ── [Payment]
             │
             └── [Report]
[Notification] ── tied to User & Events
```

---

## 1.3 Technology

### 1.3.1 Core Technologies

| Layer               | Technology                      | Purpose                                   |
| ------------------- | ------------------------------- | ----------------------------------------- |
| Frontend (Mobile)   | Flutter                         | Cross-platform Android/iOS mobile app     |
| Frontend (Web)      | Next.js / React                 | Web dashboard & admin panel               |
| Backend Framework   | Node.js / NestJS                | Microservices API layer                   |
| Database            | PostgreSQL                      | Centralized relational data               |
| Messaging / Cache   | Redis                           | Notifications, caching, real-time updates |
| Push & Messaging    | Firebase Cloud Messaging        | Push notifications & alerts               |
| Payment Integration | M-Pesa, Tigo Pesa, Airtel Money | Online payments & mobile money            |
| Hosting             | Railway / Vercel / Supabase     | Cloud-native deployment                   |

---

### 1.3.2 Development Methodology

* **Agile Scrum** methodology
* **Modular microservice architecture**
* CI/CD pipelines for staging & production
* Unit tests, integration tests, and end-to-end testing

---

## 1.4 Development Tools

### 1.4.1 Primary Tools & Environments

| Tool                    | Purpose                        |
| ----------------------- | ------------------------------ |
| VS Code                 | Frontend & backend development |
| Android Studio          | Flutter mobile development     |
| Postman / Swagger UI    | API testing & documentation    |
| GitHub                  | Source control & collaboration |
| PgAdmin / DBeaver       | Database management            |
| Firebase Console        | Push notifications & analytics |

---

### 1.4.2 Source Control

* Git with private GitHub repository
* GitFlow branching model (feature, develop, main)
* Daily commits & weekly release branches

---

### 1.4.3 Deployment Process

* CI/CD: GitHub Actions → automated testing → deploy to Railway / Vercel
* Flutter builds via **Expo EAS** for Android/iOS
* Web dashboard hosted on **Vercel / Supabase hosting**

---

## 1.5 Interfaces and Services

### 1.5.1 Primary Interfaces

| Type               | Description                                       | Data Flow      |
| ------------------ | ------------------------------------------------- | -------------- |
| REST API           | Communication between microservices & clients     | Bi-directional |
| WebSockets         | Real-time updates for sales, stock, notifications | Continuous     |
| Payment APIs       | M-Pesa, Tigo Pesa, Airtel Money                   | Bi-directional |
| Firebase Messaging | Push notifications                                | Event-based    |

---

### 1.5.2 Interface Setup

* Real-time WebSocket channels for client updates & stock changes
* Push-based notifications via Firebase
* RESTful API for CRUD operations

---

### 1.5.3 API Standards

* HTTPS / TLS 1.3
* JWT for authentication + OAuth 2.0 for third-party services
* Standard REST conventions (GET, POST, PUT, DELETE)
* Swagger / OpenAPI documentation for each service

---

## 1.6 Access, Authentication, and Authorization

* **Access Methods:** App (Flutter), Web (Next.js)
* **Authentication:** JWT + refresh tokens, OTP via SMS, email/password
* **Authorization:** RBAC (Owner, Manager, Staff)
* **Logging:** All critical operations logged for audit

---

## 2. Role-Based Functionalities

### 2.1 Administrator / Owner

* Full access to all businesses & modules
* View reports & analytics
* Manage users, permissions, and subscriptions

### 2.2 Business Staff / Manager

* Manage clients, products, sales, and inventory
* Generate reports for business performance
* Receive notifications & alerts

### 2.3 Client / Customer

* View invoices & balances (via app/web client portal)
* Receive notifications & updates
* Track orders and payments

---

## 3. System Design Overview

* **Frontend:** Flutter + Next.js
* **Backend:** Modular microservices with NestJS
* **Database:** PostgreSQL central database (multi-tenant ready)
* **Messaging:** Redis & WebSockets
* **Payment Integration:** M-Pesa / Mobile Money APIs
* **Hosting:** Railway, Vercel, Supabase

---

## 4. System Module Integration

* Each module is a **microservice**
* **Auth Service** handles all login & role validation
* **Client Service** manages CRM data
* **Inventory Service** manages stock, products, suppliers
* **Sales Service** handles orders, invoices, payments
* **Payment Service** integrates with mobile money
* **Notification Service** handles push, SMS, email
* **Reporting Service** aggregates analytics & dashboards

---

## 5. Flutter Project Structure

```
maliapp_app/
│
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── clients_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── sales_screen.dart
│   │   └── settings_screen.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── client.dart
│   │   ├── product.dart
│   │   └── sale.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── client_service.dart
│   │   └── inventory_service.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── constants.dart
│   │   └── api_endpoints.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_card.dart
│       └── notification_widget.dart
│
├── pubspec.yaml
└── README.md
```

---

## 6. Backend Microservices Architecture

* Each microservice is **NestJS + TypeScript**
* **API Gateway** handles routing & authentication

**Example Service Modules:**

```
auth-service/
client-service/
inventory-service/
sales-service/
payment-service/
notification-service/
report-service/
```

---

## 7. Database Schema

* PostgreSQL, multi-tenant ready
* Tables: `users`, `businesses`, `business_users`, `clients`, `products`, `sales`, `sale_items`, `payments`, `expenses`

(See previous database schema we discussed for full fields and types)

---

## 8. Deployment Strategy

* CI/CD with GitHub Actions
* Backend → Railway / Supabase
* Flutter → Expo EAS for iOS/Android
* Web → Vercel / Supabase hosting
* Environment variables managed in `.env`

---

## 9. Security & Data Protection

* HTTPS/TLS encryption
* Password hashing (bcrypt)
* JWT authentication
* RBAC for roles
* Regular database backups

---

## 10. Scalability & Future Enhancements

* Multi-branch business support
* AI insights & predictive analytics
* Accounting module
* Multi-language support
* POS hardware integration

---

## 11. Ownership & Licensing

* MALIAPP is IP of **Neuraltale Technologies**
* Offered as SaaS, modular, subscription-based
* Clients receive usage rights under subscription terms

---

