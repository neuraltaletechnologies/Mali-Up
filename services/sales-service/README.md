# Maliapp Sales Service

The core revenue-generating microservice for Maliapp, managing the entire sales and invoicing lifecycle.

## 🚀 Responsibilities
- Point of Sale (POS) transaction processing.
- Invoice generation (PDF) and status tracking (Draft, Paid, Overdue).
- Sales return and credit note management.
- Multi-currency support and tax calculations.
- Receipt printing support (Bluetooth thermal).

## 📊 Core Entities
- Invoices
- Invoice Items
- Sales Orders

## 🔄 Integration
- **Inventory Service:** Validates stock availability before sales.
- **Finance Service:** Updates cash flow upon payment recording.
- **Notification Service:** Sends invoices to customers via WhatsApp/Email.

---
Part of the [Maliapp](../../README.md) suite by **Neuraltale**.
