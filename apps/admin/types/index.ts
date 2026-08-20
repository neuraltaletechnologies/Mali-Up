export type PlanTier = 'starter' | 'growth' | 'business' | 'enterprise' | 'lifetime'
// Distinguishes a plan set manually from admin (plans/assign — no money
// actually changed hands) from one activated by a real ClickPesa payment.
// Absent/undefined on businesses that predate this field or are on Starter.
export type PlanSource = 'admin_grant' | 'clickpesa'
export type DurationUnit = 'days' | 'weeks' | 'months' | 'years'
export type UserStatus = 'active' | 'suspended' | 'pending'
export type BusinessStatus = 'active' | 'suspended' | 'pending' | 'inactive'
export type SubscriptionStatus = 'active' | 'past_due' | 'cancelled' | 'trialing'
export type RefundStatus = 'requested' | 'processing' | 'completed'
export type LifetimeStatus = 'active' | 'refund_requested' | 'refund_processing' | 'refunded'
export type TicketPriority = 'urgent' | 'normal' | 'low'
export type TicketStatus = 'open' | 'in_progress' | 'resolved' | 'closed'

export interface AdminUser {
  id: string
  name: string
  phone: string
  email?: string
  status: UserStatus
  businessCount: number
  businessName?: string
  lastLogin: string
  joinedAt: string
}

export interface StaffMember {
  id: string
  name: string
  phone: string
  role: string
  status: string
  invitedAt: string
}

export interface Business {
  id: string
  name: string
  ownerId: string
  ownerName: string
  ownerPhone: string
  plan: PlanTier
  status: BusinessStatus
  staffCount: number
  lastActive: string
  createdAt: string
  mrr: number
  industry: string
  location?: string
  invoiceCount?: number
  customerCount?: number
  totalRevenue?: number
  receivables?: number
  expenseTotal?: number
  notes?: AdminNote[]
  staffMembers?: StaffMember[]
  enterpriseOverrides?: EnterpriseOverride
  planSource?: PlanSource
  planExpiresAt?: string
}

// Per-business negotiated terms for the Enterprise tier — a partial override
// of PlanDefinition. Absent/empty fields fall back to the shared
// platform_config/plans.enterprise definition.
export type EnterpriseOverride = Partial<PlanDefinition> & {
  notes?: string
  setAt?: string
  setBy?: string
}

export interface AdminNote {
  id: string
  author: string
  content: string
  createdAt: string
}

export interface Subscription {
  id: string
  businessId: string
  businessName: string
  plan: PlanTier
  status: SubscriptionStatus
  amount: number
  nextBillingDate: string
  paymentMethod: string
  startedAt: string
  planSource?: PlanSource
}

export interface LifetimeSubscription {
  id: string
  businessId: string
  businessName: string
  ownerName: string
  tier: 'growth' | 'business'
  principal: number
  activatedAt: string
  monthsActive: number
  uttAMISBalance: number
  thisMonthReturn: number
  status: LifetimeStatus
  uttAMISReference?: string
  monthlyFee: number
}

export interface RefundRequest {
  id: string
  businessId: string
  businessName: string
  tier: 'growth' | 'business'
  principal: number
  monthsHeld: number
  monthlyFee: number
  requestedAt: string
  status: RefundStatus
  processedAt?: string
  completedAt?: string
}

export interface SupportTicket {
  id: string
  businessId: string
  businessName: string
  ownerName: string
  priority: TicketPriority
  status: TicketStatus
  issueType: string
  assignedAdmin?: string
  createdAt: string
  updatedAt: string
  messages?: TicketMessage[]
}

export interface TicketMessage {
  id: string
  author: string
  isAdmin: boolean
  content: string
  createdAt: string
}

export interface AuditEntry {
  id: string
  adminId: string
  adminName: string
  action: string
  resourceType: string
  resourceId: string
  resourceName: string
  before?: Record<string, unknown>
  after?: Record<string, unknown>
  isDestructive: boolean
  createdAt: string
  ip?: string
}

export type BroadcastCategory = 'reminder' | 'promotion' | 'update' | 'general'
export type BroadcastStatus = 'pending' | 'sent' | 'failed'
export type BroadcastAudience =
  | { kind: 'all' }
  | { kind: 'businesses'; businessIds: string[]; businessNames: string[] }

export interface PushBroadcast {
  id: string
  titleEn: string
  bodyEn: string
  titleSw?: string
  bodySw?: string
  category: BroadcastCategory
  audience: BroadcastAudience
  route?: string
  status: BroadcastStatus
  targetCount: number
  sentCount: number
  failureCount: number
  createdAt: string
  sentAt?: string
  createdByAdminId: string
  createdByAdminName: string
}

export interface ServiceHealth {
  name: string
  displayName: string
  status: 'healthy' | 'degraded' | 'down'
  uptime: number
  p95Latency: number
  sparkline: number[]
}

export interface FeatureFlag {
  id: string
  name: string
  description: string
  enabled: boolean
  rolloutPercent: number
  overrides: { id: string; type: 'user' | 'business'; label: string; enabled: boolean }[]
}

export interface MasterProduct {
  id: string
  productName: string
  genericName?: string
  brandNames: string[]
  businessType: string
  category: string
  unit: string
  unitAlternatives: string[]
  commonBarcodes: string[]
  searchKeywords: string[]
  tags: string[]
  prescriptionRequired: boolean
  coldStorage: boolean
  createdAt: string
  updatedAt: string
}

/** Real Firestore master catalog product (master_products collection) */
export interface CatalogProduct {
  id: string
  businessTypes: string[]
  categorySlug: string
  productName: string
  productNameSw: string
  productSlug: string
  genericName: string
  brandNames: string[]
  unit: string
  unitAlternatives: string[]
  commonBarcodes: string[]
  searchKeywords: string[]
  prescriptionRequired: boolean
  coldStorage: boolean
  tags: string[]
  // legacy fields kept for read compatibility during transition
  categoryName?: string
}

export interface CatalogCategory {
  id: string
  businessTypes: string[]
  categoryName: string
  categoryNameSw: string
  categorySlug: string
  icon: string
  displayOrder: number
  productCount: number
}

export interface CatalogImportResult {
  imported: number
  skipped: number
  skippedNames: string[]
}

export interface AnalyticsOverview {
  totalUsers: number
  totalBusinesses: number
  activeBusinesses: number
  // Estimated recurring value (plan count × configured price) — still used
  // by the main dashboard's KPI card. The Revenue page itself no longer
  // shows this; it shows the real clickPesa* fields below instead.
  mrr: number
  mrrTrend: { month: string; value: number }[]
  planDistribution: { name: string; value: number; color: string }[]
  recentSignups: {
    uid: string
    name: string
    phone: string
    businessName: string
    createdAt: string
  }[]
  // Real ClickPesa transaction data (clickpesa_payments collection) — actual
  // money collected, not a plan-count × price projection.
  clickPesaRevenueThisMonth: number
  clickPesaRevenueAllTime: number
  clickPesaRevenueTrend: { month: string; value: number }[]
  clickPesaRevenueByTier: { name: string; value: number; count: number; color: string }[]
  clickPesaSuccessCount: number
  clickPesaFailedCount: number
  clickPesaPendingCount: number
  recentClickPesaPayments: ClickPesaPaymentRecord[]
}

// One row from the clickpesa_payments collection (functions/src/clickpesa.ts
// is the only writer — created by initiateClickPesaPayment, updated by
// verifyClickPesaPayment once ClickPesa confirms a status).
export interface ClickPesaPaymentRecord {
  id: string // orderReference
  uid: string
  tier: string
  amount: number
  currency: string
  channel: string | null
  phoneNumber: string
  status: 'pending' | 'completed' | 'failed'
  createdAt: string
  completedAt: string
}

export interface CommunitySubmission {
  id: string
  type: 'product' | 'category'
  productName: string       // also used for categoryName when type='category'
  categoryName?: string
  businessType: string      // normalised key ("retail", "pharmacy"…)
  businessTypeName: string  // human-readable ("Retail", "Pharmacy & Healthcare"…)
  categorySlug: string
  unit: string
  description: string
  submittedByUid: string
  submittedByBusinessId: string
  businessName: string
  submissionCount: number
  firstSeenAt: string
  lastSeenAt: string
  status: 'pending' | 'approved' | 'rejected' | 'pushed'
  adminNotes: string
  masterDocId: string
  pushedAt: string
}

export interface PlanDefinition {
  pricePerCycle: number
  cycleMonths: number
  maxUsers: number       // -1 = unlimited
  monthlyInvoices: number // -1 = unlimited
  maxBusinesses: number  // -1 = unlimited
  maxCustomers: number   // -1 = unlimited
  cashFlow: boolean
  expenseTracking: boolean
  manualDebt: boolean
  fullReports: boolean
  mpesaImport: boolean
  smsReminders: boolean
  allExports: boolean
  multiLocation: boolean
  apiAccess: boolean
  prioritySupport: boolean
  customIntegrations: boolean
  whiteLabel: boolean
  dedicatedOnboarding: boolean
}

export type PlanDefinitions = Record<PlanTier, PlanDefinition>

export interface PlanAssignment {
  uid: string
  businessId: string
  tier: PlanTier
  durationValue: number
  durationUnit: DurationUnit
}

// Enterprise inquiries submitted from the mobile app (plan_requests
// collection). The manual "payment confirmation" claim type this also used
// to carry was retired once ClickPesa started activating plans
// automatically — see app/api/admin/plan-requests/route.ts.
export interface PlanRequest {
  id: string
  uid: string
  name: string
  phone: string
  businessId: string
  businessName: string
  requestedTier: PlanTier
  type: 'enterprise_inquiry'
  note: string
  status: 'pending' | 'approved' | 'rejected'
  activated: boolean
  adminNotes: string
  createdAt: string
  resolvedAt: string
}

export interface LookupBusinessType {
  value: string
  en: string
  sw: string
  icon: string
}

export interface LookupCity {
  en: string
  sw: string
}

export interface AppLookups {
  businessTypes: LookupBusinessType[]
  cities: LookupCity[]
  districts: Record<string, string[]>
}

// Aggregated feed of pending items requiring admin action (topbar bell)
export interface AdminNotification {
  id: string
  source: 'plan_request' | 'refund' | 'submission' | 'ticket'
  title: string
  subtitle: string
  createdAt: string
  href: string
}

export interface PlatformConfig {
  pricing: {
    starter: number
    growth: number
    business: number
    enterprise: number
    lifetimeMultiplier: number
    smsCreditPrice: number
    exportBundlePrice: number
  }
  planLimits: Record<PlanTier, { users: number }>
  tax: { vatRate: number; vatEnabled: boolean }
  lifetimeProgram: {
    uttAMISMonthlyRate: number
    cancellationFees: {
      growth: [number, number][]
      business: [number, number][]
    }
  }
  platform: { maintenanceMode: boolean; maintenanceBanner: string }
}

// Mirrors the Firestore doc at platform_config/version_gate — kept separate
// from PlatformConfig/platform_config/main since that doc must stay public
// read (checked by the mobile app before sign-in) while main stays private.
export interface VersionGateConfig {
  minSupportedBuildNumber: number
  recommendedBuildNumber: number
  updateUrlAndroid: string
  updateUrlIOS: string
  messageEn: string
  messageSw: string
}
