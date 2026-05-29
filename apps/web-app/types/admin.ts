export type AdminRole = "super_admin" | "ops_manager" | "support_agent" | "developer";
export type PlanTier = "starter" | "growth" | "business" | "enterprise";
export type UserStatus = "active" | "suspended" | "pending" | "deleted";
export type BusinessStatus = "active" | "trial" | "suspended" | "churned";
export type SubscriptionStatus = "active" | "overdue" | "cancelled" | "trial";

export interface AdminUser {
  adminId: string;
  name: string;
  email: string;
  role: AdminRole;
}

export interface PlatformUser {
  userId: string;
  name: string;
  phone: string;
  email?: string;
  status: UserStatus;
  createdAt: string;
  lastLoginAt: string;
  deviceInfo: string;
  businessCount: number;
  defaultBusinessId: string;
}

export interface Business {
  bizId: string;
  name: string;
  type: string;
  ownerName: string;
  ownerPhone: string;
  planTier: PlanTier;
  status: BusinessStatus;
  staffCount: number;
  createdAt: string;
  lastActiveAt: string;
  location: string;
  monthlyRevenue: number;
  invoiceCount: number;
  customerCount: number;
  subscriptionId: string;
}

export interface Subscription {
  subscriptionId: string;
  bizId: string;
  bizName: string;
  planTier: PlanTier;
  status: SubscriptionStatus;
  amount: number;
  currency: "TZS";
  billingCycle: "monthly" | "annual";
  currentPeriodStart: string;
  currentPeriodEnd: string;
  paymentMethod: string;
  lastPaymentAt: string;
  trialEndsAt?: string;
}

export interface AuditLog {
  logId: string;
  adminId: string;
  adminName: string;
  action: string;
  resourceType: string;
  resourceId: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  ipAddress: string;
  timestamp: string;
}

export interface ServiceHealth {
  serviceName: string;
  status: "healthy" | "degraded" | "down";
  uptime: string;
  p95Latency: number;
  requestsPerMin: number;
  errorRate: number;
  containerCount: number;
  lastChecked: string;
}

export interface PlatformKPIs {
  totalUsers: number;
  activeBusinesses: number;
  mrr: number;
  arr: number;
  mrrGrowth: number;
  churnRate: number;
  dau: number;
  mau: number;
  dauMauRatio: number;
  newUsersToday: number;
  conversionRate: number;
  avgRevenuePerUser: number;
  tierBreakdown: { starter: number; growth: number; business: number; enterprise: number };
}

export interface RevenueDataPoint {
  month: string;
  total: number;
  growth: number;
  business: number;
}

export interface ActivityEvent {
  eventId: string;
  type: string;
  description: string;
  userId?: string;
  bizId?: string;
  timestamp: string;
  severity: "info" | "warning" | "error";
}

export interface SupportTicket {
  ticketId: string;
  priority: "low" | "medium" | "high" | "critical";
  bizId: string;
  bizName: string;
  ownerPhone: string;
  issueType: "billing_dispute" | "account_locked" | "data_issue" | "feature_request" | "compliance_flag" | "other";
  status: "open" | "in_progress" | "resolved" | "escalated";
  assignedTo?: string;
  createdAt: string;
  updatedAt: string;
  description: string;
  notes: InternalNote[];
}

export interface InternalNote {
  noteId: string;
  authorId: string;
  authorName: string;
  content: string;
  createdAt: string;
}

export interface FeatureFlag {
  flagId: string;
  name: string;
  displayName: string;
  description: string;
  globalEnabled: boolean;
  rolloutPercentage: number;
  specificUsers: string[];
  specificBusinesses: string[];
  updatedAt: string;
  updatedBy: string;
}

export interface PlatformConfig {
  pricing: {
    growthMonthly: number;
    businessMonthly: number;
    smsCreditsPerPack: number;
    exportBundlePrice: number;
  };
  starterInvoiceLimit: number;
  starterUserLimit: number;
  growthUserLimit: number;
  businessUserLimit: number;
  vatRate: number;
  vatEnabled: boolean;
  maintenanceMode: boolean;
  maintenanceBanner: string;
  onboardingEnabled: boolean;
}
