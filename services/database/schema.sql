-- =============================================================================
-- Mali Up — PostgreSQL schema (initial version)
--
-- Mirrors the app's Drift tables (apps/mobile-app/lib/core/database/tables)
-- and the Firestore-only collections (users, businesses, staff, invites,
-- billing, catalog, admin). See docs/BACKEND_MIGRATION_PLAN.md §4.
--
-- Conventions
--   * IDs are TEXT, not UUID: existing IDs are Firestore auto-IDs (20 chars),
--     Firebase Auth UIDs (28 chars) and app-generated UUIDs. Keeping them as
--     text lets the Firestore → Postgres backfill copy IDs unchanged.
--   * Money is NUMERIC(14,2); stock quantities NUMERIC(14,3). Never float.
--   * Empty strings ('') in the app become NULL here (the backfill converts).
--   * Every synced business table has: business_id, created_at, updated_at,
--     version, is_deleted (soft delete, so deletes can sync to devices) and
--     extra JSONB for any Firestore field not mapped to a column yet.
--   * Rate limits, OTP codes and PIN-reset tokens are NOT here — they belong
--     in Redis / Workers KV with a TTL.
--
-- Run:  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f services/database/schema.sql
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fast ILIKE search on names

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

-- Default for new text IDs created by the server.
CREATE OR REPLACE FUNCTION new_id() RETURNS text
LANGUAGE sql VOLATILE AS $$ SELECT gen_random_uuid()::text $$;

-- BEFORE UPDATE: bump version, and stamp updated_at unless the caller set it
-- explicitly (the backfill preserves original timestamps that way).
CREATE OR REPLACE FUNCTION touch_row() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.version := OLD.version + 1;
  IF NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at THEN
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END $$;

-- =============================================================================
-- 1. IDENTITY & TENANCY
-- =============================================================================

CREATE TABLE users (
  id                    text PRIMARY KEY DEFAULT new_id(),  -- = Firebase UID for migrated users
  phone                 text NOT NULL UNIQUE,               -- canonical digits, e.g. 255712345678
  auth_email            text UNIQUE,                        -- legacy Firebase Auth email derived from phone
  email                 text,
  name                  text NOT NULL DEFAULT '',
  first_name            text NOT NULL DEFAULT '',
  last_name             text NOT NULL DEFAULT '',
  language              text NOT NULL DEFAULT 'sw' CHECK (language IN ('sw', 'en')),
  pin_hash              text,                               -- argon2id/scrypt; NULL until first login on new auth
  legacy_firebase_hash  text,                               -- from `firebase auth:export`, cleared after re-hash
  phone_verified        boolean NOT NULL DEFAULT false,
  is_team_member        boolean NOT NULL DEFAULT false,
  selected_business_id  text,                               -- FK added after businesses exists
  default_context       text,
  welcome_sms_status    text,                               -- in_progress | sent | failed | abandoned
  welcome_sms_attempts  int  NOT NULL DEFAULT 0,
  welcome_sms_sent_at   timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  last_active_at        timestamptz,
  version               bigint NOT NULL DEFAULT 1,
  extra                 jsonb NOT NULL DEFAULT '{}'
);

-- Push notification tokens (was users/{uid}/fcm_tokens).
CREATE TABLE device_tokens (
  token        text PRIMARY KEY,
  user_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform     text NOT NULL DEFAULT '',
  updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX device_tokens_user_idx ON device_tokens (user_id);

-- Refresh tokens for the new JWT auth (store a hash, never the token).
CREATE TABLE refresh_tokens (
  id           text PRIMARY KEY DEFAULT new_id(),
  user_id      text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash   text NOT NULL UNIQUE,
  device_label text NOT NULL DEFAULT '',
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  revoked_at   timestamptz
);
CREATE INDEX refresh_tokens_user_idx ON refresh_tokens (user_id) WHERE revoked_at IS NULL;

-- Subscription tiers (was platform_config/plans).
CREATE TABLE plans (
  id               text PRIMARY KEY,                -- trial | starter | growth | business
  name             text NOT NULL,
  price_per_cycle  numeric(14,2) NOT NULL DEFAULT 0,
  cycle_months     int NOT NULL DEFAULT 1,
  price_monthly    numeric(14,2) NOT NULL DEFAULT 0,
  price_yearly     numeric(14,2) NOT NULL DEFAULT 0,
  limits           jsonb NOT NULL DEFAULT '{}',     -- e.g. {"maxStaff": 3}
  is_active        boolean NOT NULL DEFAULT true,
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE businesses (
  id                   text PRIMARY KEY DEFAULT new_id(),
  owner_user_id        text NOT NULL REFERENCES users(id),
  business_name        text NOT NULL,
  business_category    text NOT NULL DEFAULT '',     -- businessType ("retail", "pharmacy", …)
  owner_name           text NOT NULL DEFAULT '',
  phone                text,
  address              text,
  city                 text,
  region               text,
  district             text,
  country              text NOT NULL DEFAULT 'TZ',
  tin_number           text,
  vat_registered       boolean NOT NULL DEFAULT false,
  vat_rate             numeric(5,4) NOT NULL DEFAULT 0.18,
  currency             text NOT NULL DEFAULT 'TZS',
  invoice_prefix       text NOT NULL DEFAULT 'INV',
  next_invoice_number  int NOT NULL DEFAULT 0,
  logo_file_id         text,                         -- FK added after files exists
  website_url          text,
  has_website          boolean NOT NULL DEFAULT false,
  website_interest     text,
  plan                 text NOT NULL DEFAULT 'trial', -- plain text: Firestore holds mixed values ('Trial', 'starter')
  plan_expires_at      timestamptz,
  is_active            boolean NOT NULL DEFAULT true,
  staff_count          int NOT NULL DEFAULT 0,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  version              bigint NOT NULL DEFAULT 1,
  is_deleted           boolean NOT NULL DEFAULT false,
  extra                jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX businesses_owner_idx ON businesses (owner_user_id);

ALTER TABLE users
  ADD CONSTRAINT users_selected_business_fk
  FOREIGN KEY (selected_business_id) REFERENCES businesses(id) ON DELETE SET NULL;

-- Reusable permission sets (was businesses/{id}/customRoles).
CREATE TABLE custom_roles (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name         text NOT NULL,
  permissions  text[] NOT NULL DEFAULT '{}',
  data_scope   text NOT NULL DEFAULT 'all' CHECK (data_scope IN ('all', 'own')),
  created_by   text REFERENCES users(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX custom_roles_business_idx ON custom_roles (business_id);

-- Team members (was businesses/{id}/staff; Drift: team_members).
CREATE TABLE business_members (
  id                  text PRIMARY KEY DEFAULT new_id(),
  business_id         text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id             text REFERENCES users(id) ON DELETE SET NULL,  -- NULL until the invite is accepted
  name                text NOT NULL,
  email               text,
  phone               text,
  role                text NOT NULL
                      CHECK (role IN ('owner', 'manager', 'accountant', 'cashier', 'stockClerk', 'custom')),
  custom_permissions  text[] NOT NULL DEFAULT '{}',
  custom_role_id      text REFERENCES custom_roles(id) ON DELETE SET NULL,
  custom_role_name    text,
  status              text NOT NULL DEFAULT 'pending',               -- pending | active | suspended | removed
  data_scope          text NOT NULL DEFAULT 'all' CHECK (data_scope IN ('all', 'own')),
  invited_at          timestamptz NOT NULL DEFAULT now(),
  accepted_at         timestamptz,
  invited_by          text,                                          -- user id, or admin name for quick-setup
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  version             bigint NOT NULL DEFAULT 1,
  is_deleted          boolean NOT NULL DEFAULT false,
  extra               jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX business_members_business_idx ON business_members (business_id);
CREATE UNIQUE INDEX business_members_user_uq
  ON business_members (business_id, user_id) WHERE user_id IS NOT NULL AND NOT is_deleted;

-- Phone-keyed invites looked up at staff sign-in (was pendingInvites).
CREATE TABLE pending_invites (
  id                   text PRIMARY KEY DEFAULT new_id(),
  business_id          text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  member_id            text REFERENCES business_members(id) ON DELETE CASCADE,
  owner_user_id        text REFERENCES users(id) ON DELETE CASCADE,
  business_name        text NOT NULL DEFAULT '',
  full_name            text NOT NULL DEFAULT '',
  phone_number         text NOT NULL,
  email                text,
  role                 text NOT NULL,
  invited_by           text,
  status               text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'cancelled')),
  pin_created          boolean NOT NULL DEFAULT false,
  accepted_by_user_id  text REFERENCES users(id) ON DELETE SET NULL,
  accepted_at          timestamptz,
  invite_sms_status    text,                                       -- in_progress | sent | failed | abandoned
  invite_sms_attempts  int NOT NULL DEFAULT 0,
  invite_sms_sent_at   timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  extra                jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX pending_invites_phone_idx ON pending_invites (phone_number) WHERE status = 'pending';
CREATE INDEX pending_invites_member_idx ON pending_invites (member_id);

-- Uploaded objects stored in Cloudflare R2. Store the key, never a URL.
CREATE TABLE files (
  id            text PRIMARY KEY DEFAULT new_id(),
  business_id   text REFERENCES businesses(id) ON DELETE CASCADE,
  uploaded_by   text REFERENCES users(id) ON DELETE SET NULL,
  kind          text NOT NULL CHECK (kind IN ('logo', 'receipt', 'return_proof', 'product_image', 'document')),
  r2_key        text NOT NULL UNIQUE,       -- e.g. biz/{businessId}/receipt/{id}.jpg
  content_type  text NOT NULL,
  size_bytes    bigint NOT NULL DEFAULT 0,
  legacy_url    text,                       -- original Firebase Storage URL during migration
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX files_business_idx ON files (business_id);

ALTER TABLE businesses
  ADD CONSTRAINT businesses_logo_fk
  FOREIGN KEY (logo_file_id) REFERENCES files(id) ON DELETE SET NULL;

-- =============================================================================
-- 2. CUSTOMERS
-- =============================================================================

CREATE TABLE customers (
  id                     text PRIMARY KEY DEFAULT new_id(),
  business_id            text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name                   text NOT NULL,
  phone                  text NOT NULL DEFAULT '',
  email                  text,
  balance                numeric(14,2) NOT NULL DEFAULT 0,  -- changed by delta, never overwritten
  credit_limit           numeric(14,2) NOT NULL DEFAULT 0,
  last_transaction_date  timestamptz,
  tags                   text[] NOT NULL DEFAULT '{}',
  is_organisation        boolean NOT NULL DEFAULT false,
  tin_number             text,
  address                text,
  created_by             text,
  assigned_to_user_id    text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  version                bigint NOT NULL DEFAULT 1,
  is_deleted             boolean NOT NULL DEFAULT false,
  extra                  jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX customers_business_idx ON customers (business_id, updated_at);
CREATE INDEX customers_phone_idx ON customers (business_id, phone);
CREATE INDEX customers_name_trgm ON customers USING gin (name gin_trgm_ops);

CREATE TABLE customer_notes (
  id             text PRIMARY KEY DEFAULT new_id(),
  business_id    text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  customer_id    text NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  type           text NOT NULL DEFAULT 'note',
  text           text NOT NULL,
  added_by       text,
  added_at       timestamptz NOT NULL DEFAULT now(),
  reminder_sent  boolean NOT NULL DEFAULT false,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  version        bigint NOT NULL DEFAULT 1,
  is_deleted     boolean NOT NULL DEFAULT false,
  extra          jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX customer_notes_customer_idx ON customer_notes (customer_id);

CREATE TABLE customer_payments (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  customer_id  text NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  amount       numeric(14,2) NOT NULL,
  method       text NOT NULL DEFAULT 'cash',
  note         text,
  paid_at      timestamptz NOT NULL DEFAULT now(),
  recorded_by  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX customer_payments_customer_idx ON customer_payments (customer_id);

-- =============================================================================
-- 3. INVENTORY
-- =============================================================================

CREATE TABLE inventory_items (
  id                   text PRIMARY KEY DEFAULT new_id(),
  business_id          text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name                 text NOT NULL,
  sku                  text,
  barcode              text,
  category             text,
  unit                 text NOT NULL DEFAULT 'pcs',
  quantity             numeric(14,3) NOT NULL DEFAULT 0,  -- changed by delta (UPDATE … SET quantity = quantity + $1)
  low_stock_threshold  numeric(14,3) NOT NULL DEFAULT 0,
  unit_price           numeric(14,2) NOT NULL DEFAULT 0,
  cost_price           numeric(14,2) NOT NULL DEFAULT 0,
  description          text,
  image_file_id        text REFERENCES files(id) ON DELETE SET NULL,
  is_active            boolean NOT NULL DEFAULT true,
  metadata             jsonb NOT NULL DEFAULT '{}',
  created_by           text,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  version              bigint NOT NULL DEFAULT 1,
  is_deleted           boolean NOT NULL DEFAULT false,
  extra                jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX inventory_business_idx ON inventory_items (business_id, updated_at);
CREATE INDEX inventory_barcode_idx ON inventory_items (business_id, barcode) WHERE barcode IS NOT NULL;
CREATE INDEX inventory_name_trgm ON inventory_items USING gin (name gin_trgm_ops);
CREATE INDEX inventory_low_stock_idx ON inventory_items (business_id)
  WHERE is_active AND NOT is_deleted AND quantity <= low_stock_threshold;

-- =============================================================================
-- 4. SALES: invoices, items, payments, returns
-- =============================================================================

CREATE TABLE invoices (
  id                  text PRIMARY KEY DEFAULT new_id(),
  business_id         text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  customer_id         text REFERENCES customers(id) ON DELETE SET NULL,  -- NULL for walk-in sales
  customer_name       text NOT NULL DEFAULT '',                          -- snapshot at time of sale
  customer_phone      text,
  invoice_number      text NOT NULL,
  doc_type            text NOT NULL DEFAULT 'invoice',                   -- invoice | receipt | quotation …
  status              text NOT NULL DEFAULT 'pending',
  issued_at           timestamptz NOT NULL,                              -- Drift: date
  due_at              timestamptz,                                       -- Drift: dueDate
  subtotal            numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount     numeric(14,2) NOT NULL DEFAULT 0,
  tax                 numeric(14,2) NOT NULL DEFAULT 0,
  total               numeric(14,2) NOT NULL DEFAULT 0,
  amount_paid         numeric(14,2) NOT NULL DEFAULT 0,
  payment_method      text,
  payment_account_id  text,                                              -- cash_accounts.id (same business)
  note                text,
  has_return          boolean NOT NULL DEFAULT false,
  returned_amount     numeric(14,2) NOT NULL DEFAULT 0,
  credit_note_number  text,
  created_by          text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  version             bigint NOT NULL DEFAULT 1,
  is_deleted          boolean NOT NULL DEFAULT false,
  extra               jsonb NOT NULL DEFAULT '{}'
);
-- Not UNIQUE: devices number invoices offline, so duplicates can exist.
CREATE INDEX invoices_number_idx ON invoices (business_id, invoice_number);
CREATE INDEX invoices_business_idx ON invoices (business_id, updated_at);
CREATE INDEX invoices_issued_idx ON invoices (business_id, issued_at DESC) WHERE NOT is_deleted;
CREATE INDEX invoices_customer_idx ON invoices (customer_id);

CREATE TABLE invoice_items (
  id           text PRIMARY KEY DEFAULT new_id(),
  invoice_id   text NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  product_id   text REFERENCES inventory_items(id) ON DELETE SET NULL,
  name         text NOT NULL,
  description  text,
  quantity     numeric(14,3) NOT NULL,
  unit_price   numeric(14,2) NOT NULL,
  total        numeric(14,2) NOT NULL,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX invoice_items_invoice_idx ON invoice_items (invoice_id);
CREATE INDEX invoice_items_product_idx ON invoice_items (product_id);

-- Fields below are inferred: the app writes these collections with dynamic
-- maps. Unmapped Firestore fields land in `extra` during backfill.
CREATE TABLE invoice_payments (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  invoice_id   text NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount       numeric(14,2) NOT NULL,
  method       text NOT NULL DEFAULT 'cash',
  account_id   text,
  paid_at      timestamptz NOT NULL DEFAULT now(),
  recorded_by  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX invoice_payments_invoice_idx ON invoice_payments (invoice_id);

CREATE TABLE credit_notes (
  id                  text PRIMARY KEY DEFAULT new_id(),
  business_id         text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  invoice_id          text REFERENCES invoices(id) ON DELETE SET NULL,
  credit_note_number  text NOT NULL,
  amount              numeric(14,2) NOT NULL DEFAULT 0,
  reason              text,
  items               jsonb NOT NULL DEFAULT '[]',
  proof_file_id       text REFERENCES files(id) ON DELETE SET NULL,  -- sales-return photo
  created_by          text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  version             bigint NOT NULL DEFAULT 1,
  is_deleted          boolean NOT NULL DEFAULT false,
  extra               jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX credit_notes_invoice_idx ON credit_notes (invoice_id);

-- =============================================================================
-- 5. DEBTS (receivables & payables)
-- =============================================================================

CREATE TABLE debts (
  id                     text PRIMARY KEY DEFAULT new_id(),
  business_id            text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  party_name             text NOT NULL,
  party_phone            text,
  party_id               text,                       -- customer/supplier id when linked
  type                   text NOT NULL CHECK (type IN ('receivable', 'payable')),
  original_amount        numeric(14,2) NOT NULL,
  paid_amount            numeric(14,2) NOT NULL DEFAULT 0,
  due_at                 timestamptz,
  status                 text NOT NULL DEFAULT 'current',
  invoice_ref            text,
  note                   text,
  debt_created_at        timestamptz,                -- business date the debt started
  loan_date              timestamptz,
  interest_rate_percent  numeric(7,4) NOT NULL DEFAULT 0,
  interest_period        text NOT NULL DEFAULT 'monthly',
  interest_type          text NOT NULL DEFAULT 'simple',
  is_written_off         boolean NOT NULL DEFAULT false,
  write_off_reason       text,
  written_off_by         text,
  written_off_at         timestamptz,
  created_by             text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  version                bigint NOT NULL DEFAULT 1,
  is_deleted             boolean NOT NULL DEFAULT false,
  extra                  jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX debts_business_idx ON debts (business_id, updated_at);
CREATE INDEX debts_open_idx ON debts (business_id, type, due_at)
  WHERE NOT is_deleted AND NOT is_written_off AND paid_amount < original_amount;

CREATE TABLE debt_payments (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  debt_id      text NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  amount       numeric(14,2) NOT NULL,
  paid_at      timestamptz NOT NULL,                 -- Drift: date
  method       text NOT NULL DEFAULT 'cash',
  account_id   text,
  note         text,
  recorded_by  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX debt_payments_debt_idx ON debt_payments (debt_id);
CREATE INDEX debt_payments_business_idx ON debt_payments (business_id, updated_at);

-- =============================================================================
-- 6. EXPENSES
-- =============================================================================

CREATE TABLE expense_categories (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name         text NOT NULL,
  name_sw      text,
  icon         text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX expense_categories_business_idx ON expense_categories (business_id);

CREATE TABLE expense_templates (
  id               text PRIMARY KEY DEFAULT new_id(),
  business_id      text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category         text NOT NULL,
  amount           numeric(14,2) NOT NULL DEFAULT 0,
  recipient        text,
  note             text,
  recurrence_type  text,                              -- daily | weekly | monthly …
  next_due_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  version          bigint NOT NULL DEFAULT 1,
  is_deleted       boolean NOT NULL DEFAULT false,
  extra            jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX expense_templates_business_idx ON expense_templates (business_id);

CREATE TABLE expenses (
  id                  text PRIMARY KEY DEFAULT new_id(),
  business_id         text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category            text NOT NULL,
  amount              numeric(14,2) NOT NULL,
  spent_at            timestamptz NOT NULL,           -- Drift: date
  note                text,
  recipient           text,
  is_recurring        boolean NOT NULL DEFAULT false,
  recurrence_type     text,
  next_due_at         timestamptz,
  template_id         text REFERENCES expense_templates(id) ON DELETE SET NULL,
  receipt_file_id     text REFERENCES files(id) ON DELETE SET NULL,
  payment_method      text NOT NULL DEFAULT 'cash',
  payment_account_id  text,
  status              text NOT NULL DEFAULT 'approved',  -- pending | approved | rejected
  approved_by         text,
  created_by          text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  version             bigint NOT NULL DEFAULT 1,
  is_deleted          boolean NOT NULL DEFAULT false,
  extra               jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX expenses_business_idx ON expenses (business_id, updated_at);
CREATE INDEX expenses_spent_idx ON expenses (business_id, spent_at DESC) WHERE NOT is_deleted;

CREATE TABLE budgets (
  id           text PRIMARY KEY DEFAULT new_id(),
  business_id  text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category     text NOT NULL,
  amount       numeric(14,2) NOT NULL,
  period       text NOT NULL DEFAULT 'monthly',
  starts_on    date,
  ends_on      date,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  version      bigint NOT NULL DEFAULT 1,
  is_deleted   boolean NOT NULL DEFAULT false,
  extra        jsonb NOT NULL DEFAULT '{}'
);
CREATE INDEX budgets_business_idx ON budgets (business_id);

-- =============================================================================
-- 7. CASH MANAGEMENT
-- Account IDs are only unique within a business in the app (Drift primary
-- key is businessId + id), so the keys here are composite too.
-- =============================================================================

CREATE TABLE cash_accounts (
  business_id      text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  id               text NOT NULL DEFAULT new_id(),
  name             text NOT NULL,
  type             text NOT NULL,                     -- Cash | Mobile Money | Bank
  balance          numeric(14,2) NOT NULL DEFAULT 0,
  account_number   text,
  currency         text NOT NULL DEFAULT 'TZS',
  last_reconciled  timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  version          bigint NOT NULL DEFAULT 1,
  is_deleted       boolean NOT NULL DEFAULT false,
  extra            jsonb NOT NULL DEFAULT '{}',
  PRIMARY KEY (business_id, id)
);

CREATE TABLE cash_transactions (
  id                 text PRIMARY KEY DEFAULT new_id(),
  business_id        text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  type               text NOT NULL,                   -- deposit | withdrawal | transfer
  amount             numeric(14,2) NOT NULL,
  from_account_id    text,
  to_account_id      text,
  description        text,
  occurred_at        timestamptz NOT NULL,            -- Drift: date
  reference          text,
  activity_category  text NOT NULL DEFAULT 'operating',  -- operating | investing | financing
  created_by         text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  version            bigint NOT NULL DEFAULT 1,
  is_deleted         boolean NOT NULL DEFAULT false,
  extra              jsonb NOT NULL DEFAULT '{}',
  FOREIGN KEY (business_id, from_account_id) REFERENCES cash_accounts (business_id, id),
  FOREIGN KEY (business_id, to_account_id)   REFERENCES cash_accounts (business_id, id)
);
CREATE INDEX cash_transactions_business_idx ON cash_transactions (business_id, updated_at);
CREATE INDEX cash_transactions_occurred_idx ON cash_transactions (business_id, occurred_at DESC) WHERE NOT is_deleted;

CREATE TABLE daily_reconciliations (
  business_id        text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  id                 text NOT NULL DEFAULT new_id(),
  account_id         text NOT NULL,
  day                date NOT NULL,
  opening_balance    numeric(14,2) NOT NULL DEFAULT 0,
  closing_balance    numeric(14,2) NOT NULL DEFAULT 0,
  total_deposits     numeric(14,2) NOT NULL DEFAULT 0,
  total_withdrawals  numeric(14,2) NOT NULL DEFAULT 0,
  notes              text,
  reconciled_by      text,
  is_reconciled      boolean NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  version            bigint NOT NULL DEFAULT 1,
  is_deleted         boolean NOT NULL DEFAULT false,
  extra              jsonb NOT NULL DEFAULT '{}',
  PRIMARY KEY (business_id, id),
  FOREIGN KEY (business_id, account_id) REFERENCES cash_accounts (business_id, id)
);
CREATE INDEX daily_reconciliations_day_idx ON daily_reconciliations (business_id, account_id, day);

-- =============================================================================
-- 8. AUDIT LOG (append-only)
-- =============================================================================

CREATE TABLE audit_logs (
  id                 text PRIMARY KEY DEFAULT new_id(),
  business_id        text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  action             text NOT NULL,                  -- memberInvited, invoiceDeleted, …
  performed_by       text,
  performed_by_name  text,
  performed_by_role  text,
  entity_type        text,
  entity_id          text,
  entity_name        text,
  target_member_id   text,
  target_name        text,
  previous_value     text,
  new_value          text,
  amount             numeric(14,2),
  details            jsonb NOT NULL DEFAULT '{}',
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_business_idx ON audit_logs (business_id, created_at DESC);

CREATE OR REPLACE FUNCTION forbid_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME;
END $$;

CREATE TRIGGER audit_logs_append_only
  BEFORE UPDATE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_change();

-- =============================================================================
-- 9. SYNC PROTOCOL (see BACKEND_MIGRATION_PLAN.md §5)
-- =============================================================================

-- Change feed for GET /sync/pull?cursor=<seq>. Filled by triggers below, so
-- no write path can forget it. A sequence number, unlike a timestamp, never
-- skips rows when clocks disagree.
CREATE TABLE sync_changes (
  seq          bigserial PRIMARY KEY,
  business_id  text NOT NULL,
  entity_type  text NOT NULL,          -- matches the app's sync_queue entityType
  entity_id    text NOT NULL,
  op           text NOT NULL CHECK (op IN ('upsert', 'delete')),
  changed_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sync_changes_business_seq_idx ON sync_changes (business_id, seq);

-- Idempotency: the app's sync_queue.operationId. A retried push whose
-- operation is already here returns the stored result instead of re-applying
-- it (no double-counted sale or stock movement).
CREATE TABLE processed_operations (
  operation_id  text PRIMARY KEY,
  business_id   text NOT NULL,
  user_id       text,
  entity_type   text NOT NULL,
  entity_id     text NOT NULL,
  result        jsonb NOT NULL DEFAULT '{}',
  processed_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX processed_operations_age_idx ON processed_operations (processed_at);  -- for pruning

CREATE OR REPLACE FUNCTION log_sync_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO sync_changes (business_id, entity_type, entity_id, op)
  VALUES (NEW.business_id, TG_ARGV[0], NEW.id,
          CASE WHEN NEW.is_deleted THEN 'delete' ELSE 'upsert' END);
  RETURN NULL;
END $$;

-- Attach touch_row (updated_at/version) and log_sync_change to every synced
-- table. The second element is the entity type the app's SyncService uses.
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN SELECT * FROM (VALUES
    ('customers',             'customer'),
    ('customer_notes',        'customer_note'),
    ('customer_payments',     'customer_payment'),
    ('inventory_items',       'inventory_item'),
    ('invoices',              'invoice'),
    ('invoice_payments',      'invoice_payment'),
    ('credit_notes',          'credit_note'),
    ('debts',                 'debt'),
    ('debt_payments',         'debt_payment'),
    ('expense_categories',    'expense_category'),
    ('expense_templates',     'expense_template'),
    ('expenses',              'expense'),
    ('budgets',               'budget'),
    ('cash_accounts',         'cash_account'),
    ('cash_transactions',     'cash_transaction'),
    ('daily_reconciliations', 'reconciliation'),
    ('business_members',      'team_member'),
    ('custom_roles',          'custom_role')
  ) AS v(tbl, entity)
  LOOP
    EXECUTE format(
      'CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION touch_row()',
      t.tbl || '_touch', t.tbl);
    EXECUTE format(
      'CREATE TRIGGER %I AFTER INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION log_sync_change(%L)',
      t.tbl || '_sync_log', t.tbl, t.entity);
  END LOOP;
END $$;

CREATE TRIGGER users_touch BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION touch_row();
CREATE TRIGGER businesses_touch BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION touch_row();

-- =============================================================================
-- 10. BILLING
-- =============================================================================

CREATE TABLE clickpesa_payments (
  order_reference  text PRIMARY KEY,
  business_id      text NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id          text REFERENCES users(id) ON DELETE SET NULL,
  plan_id          text NOT NULL,
  billing_cycle    text NOT NULL,                  -- cycle | monthly | yearly
  amount           numeric(14,2) NOT NULL,
  currency         text NOT NULL DEFAULT 'TZS',
  phone_number     text,
  channel          text,
  clickpesa_id     text,
  status           text NOT NULL DEFAULT 'pending', -- pending | success | failed
  raw_response     jsonb NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now(),
  completed_at     timestamptz,
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX clickpesa_payments_business_idx ON clickpesa_payments (business_id, created_at DESC);

CREATE TABLE plan_requests (
  id              text PRIMARY KEY DEFAULT new_id(),
  user_id         text REFERENCES users(id) ON DELETE CASCADE,
  business_id     text REFERENCES businesses(id) ON DELETE CASCADE,
  business_name   text,
  name            text,
  phone           text,
  type            text,
  requested_tier  text,
  payment_ref     text,
  note            text,
  status          text NOT NULL DEFAULT 'pending',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX plan_requests_status_idx ON plan_requests (status, created_at DESC);

-- =============================================================================
-- 11. REFERENCE DATA (read-only for the app, managed from admin)
-- =============================================================================

-- Key/value config: version_gate, feature flags, etc. (was platform_config/*).
CREATE TABLE app_config (
  key         text PRIMARY KEY,
  value       jsonb NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Business types, cities, districts … (was lookups).
CREATE TABLE lookups (
  id          text PRIMARY KEY,
  data        jsonb NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE master_categories (
  id                text NOT NULL,
  business_type     text NOT NULL,
  category_name     text NOT NULL,
  category_name_sw  text,
  category_slug     text,
  icon              text,
  display_order     int NOT NULL DEFAULT 0,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id, business_type)
);

CREATE TABLE master_products (
  id                     text NOT NULL,
  business_type          text NOT NULL,
  category_slug          text,
  product_name           text NOT NULL,
  product_name_sw        text,
  product_slug           text,
  generic_name           text,
  brand_names            text[] NOT NULL DEFAULT '{}',
  unit                   text NOT NULL DEFAULT 'Piece',
  unit_alternatives      text[] NOT NULL DEFAULT '{}',
  common_barcodes        text[] NOT NULL DEFAULT '{}',
  search_keywords        text[] NOT NULL DEFAULT '{}',
  tags                   text[] NOT NULL DEFAULT '{}',
  prescription_required  boolean NOT NULL DEFAULT false,
  cold_storage           boolean NOT NULL DEFAULT false,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id, business_type)
);
CREATE INDEX master_products_category_idx ON master_products (business_type, category_slug);
CREATE INDEX master_products_name_trgm ON master_products USING gin (product_name gin_trgm_ops);
CREATE INDEX master_products_barcodes_idx ON master_products USING gin (common_barcodes);
CREATE INDEX master_products_keywords_idx ON master_products USING gin (search_keywords);

CREATE TABLE catalog_submissions (           -- was catalog_community_submissions
  id            text PRIMARY KEY DEFAULT new_id(),
  business_id   text REFERENCES businesses(id) ON DELETE SET NULL,
  submitted_by  text REFERENCES users(id) ON DELETE SET NULL,
  data          jsonb NOT NULL,
  status        text NOT NULL DEFAULT 'pending',
  created_at    timestamptz NOT NULL DEFAULT now(),
  reviewed_at   timestamptz
);

-- =============================================================================
-- 12. PLATFORM / ADMIN DASHBOARD
-- =============================================================================

CREATE TABLE platform_admins (
  user_id     text PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  role        text NOT NULL DEFAULT 'admin',
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE admin_audit_log (
  id          bigserial PRIMARY KEY,
  admin_id    text,
  action      text NOT NULL,
  target      text,
  details     jsonb NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX admin_audit_log_created_idx ON admin_audit_log (created_at DESC);

CREATE TRIGGER admin_audit_log_append_only
  BEFORE UPDATE ON admin_audit_log
  FOR EACH ROW EXECUTE FUNCTION forbid_change();

CREATE TABLE admin_notes (
  id           text PRIMARY KEY DEFAULT new_id(),
  subject_type text NOT NULL,              -- user | business
  subject_id   text NOT NULL,
  author_id    text,
  body         text NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX admin_notes_subject_idx ON admin_notes (subject_type, subject_id);

CREATE TABLE admin_broadcasts (            -- push notifications to users
  id           text PRIMARY KEY DEFAULT new_id(),
  title        text NOT NULL,
  body         text NOT NULL,
  audience     jsonb NOT NULL DEFAULT '{}',
  status       text NOT NULL DEFAULT 'queued',  -- queued | sending | sent | failed
  sent_count   int NOT NULL DEFAULT 0,
  created_by   text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  sent_at      timestamptz
);

CREATE TABLE sms_campaigns (               -- was beem_sms_campaigns
  id               text PRIMARY KEY DEFAULT new_id(),
  name             text NOT NULL DEFAULT '',
  message          text NOT NULL,
  sender_id        text,
  audience         jsonb NOT NULL DEFAULT '{}',
  status           text NOT NULL DEFAULT 'draft',  -- draft | scheduled | sending | sent | failed
  scheduled_at     timestamptz,
  recipient_count  int NOT NULL DEFAULT 0,
  sent_count       int NOT NULL DEFAULT 0,
  auto_rule_id     text,
  created_by       text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  sent_at          timestamptz
);
CREATE INDEX sms_campaigns_due_idx ON sms_campaigns (scheduled_at) WHERE status = 'scheduled';

CREATE TABLE sms_auto_campaigns (          -- was beem_sms_auto_campaigns (yearly greetings)
  id             text PRIMARY KEY DEFAULT new_id(),
  name           text NOT NULL DEFAULT '',
  message        text NOT NULL,
  sender_id      text,
  audience       jsonb NOT NULL DEFAULT '{}',
  month          int NOT NULL CHECK (month BETWEEN 1 AND 12),
  day            int NOT NULL CHECK (day BETWEEN 1 AND 31),
  hour           int NOT NULL DEFAULT 9 CHECK (hour BETWEEN 0 AND 23),
  enabled        boolean NOT NULL DEFAULT true,
  last_run_year  int,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE support_tickets (             -- was platform_tickets
  id           text PRIMARY KEY DEFAULT new_id(),
  user_id      text REFERENCES users(id) ON DELETE SET NULL,
  business_id  text REFERENCES businesses(id) ON DELETE SET NULL,
  subject      text NOT NULL DEFAULT '',
  body         text NOT NULL DEFAULT '',
  status       text NOT NULL DEFAULT 'open',
  data         jsonb NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE refunds (                     -- was platform_refunds
  id               text PRIMARY KEY DEFAULT new_id(),
  order_reference  text REFERENCES clickpesa_payments(order_reference),
  business_id      text REFERENCES businesses(id) ON DELETE SET NULL,
  amount           numeric(14,2) NOT NULL,
  reason           text,
  status           text NOT NULL DEFAULT 'pending',
  data             jsonb NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE website_requests (            -- was websiteRequests
  id          text PRIMARY KEY DEFAULT new_id(),
  user_id     text REFERENCES users(id) ON DELETE CASCADE,
  data        jsonb NOT NULL DEFAULT '{}',
  status      text NOT NULL DEFAULT 'pending',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 13. SEED DATA
-- Prices are the fallback defaults from functions/src/clickpesa.ts; the live
-- values are in Firestore platform_config/plans — the backfill overwrites these.
-- =============================================================================

INSERT INTO plans (id, name, price_per_cycle, cycle_months, price_monthly, price_yearly) VALUES
  ('trial',    'Trial',    0,     1, 0,    0),
  ('starter',  'Starter',  0,     1, 0,    0),
  ('growth',   'Growth',   30000, 6, 6000, 60000),
  ('business', 'Business', 40000, 6, 8000, 80000);

COMMIT;
