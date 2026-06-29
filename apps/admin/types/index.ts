export type PlanTier = 'starter' | 'growth' | 'business' | 'enterprise' | 'lifetime'
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
  businessType: string
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
  businessType: string
  categoryName: string
  categoryNameSw: string
  categorySlug: string
  icon: string
  displayOrder: number
  productCount: number
}

export interface AnalyticsOverview {
  totalUsers: number
  totalBusinesses: number
  activeBusinesses: number
  mrr: number
  planDistribution: { name: string; value: number; color: string }[]
  mrrTrend: { month: string; value: number }[]
  recentSignups: {
    uid: string
    name: string
    phone: string
    businessName: string
    createdAt: string
  }[]
}

export interface CommunitySubmission {
  id: string
  productName: string
  businessName: string
  businessType: string
  submissionCount: number
  firstSeenAt: string
  status: 'pending' | 'approved' | 'rejected'
}

export interface PlanDefinition {
  pricePerCycle: number
  cycleMonths: number
  maxUsers: number       // -1 = unlimited
  monthlyInvoices: number // -1 = unlimited
  fullReports: boolean
  mpesaImport: boolean
  smsReminders: boolean
  multiLocation: boolean
  apiAccess: boolean
  allExports: boolean
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
  cycleMonths: number
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
