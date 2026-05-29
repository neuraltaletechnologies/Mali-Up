import type {
  PlatformUser,
  Business,
  Subscription,
  AuditLog,
  PlatformKPIs,
  ServiceHealth,
  ActivityEvent,
  SupportTicket,
  FeatureFlag,
  RevenueDataPoint,
} from "@/types/admin";

export const mockKPIs: PlatformKPIs = {
  totalUsers: 3_847,
  activeBusinesses: 1_203,
  mrr: 28_470_000,
  arr: 341_640_000,
  mrrGrowth: 12.4,
  churnRate: 2.1,
  dau: 892,
  mau: 2_104,
  dauMauRatio: 42.4,
  newUsersToday: 23,
  conversionRate: 31.3,
  avgRevenuePerUser: 23_665,
  tierBreakdown: { starter: 612, growth: 389, business: 158, enterprise: 44 },
};

export const mockRevenueData: RevenueDataPoint[] = [
  { month: "Jun 2025", total: 18_200_000, growth: 6_400_000, business: 4_200_000 },
  { month: "Jul 2025", total: 19_500_000, growth: 7_100_000, business: 4_800_000 },
  { month: "Aug 2025", total: 20_800_000, growth: 7_500_000, business: 5_200_000 },
  { month: "Sep 2025", total: 21_400_000, growth: 7_900_000, business: 5_600_000 },
  { month: "Oct 2025", total: 22_100_000, growth: 8_200_000, business: 6_000_000 },
  { month: "Nov 2025", total: 23_300_000, growth: 8_700_000, business: 6_400_000 },
  { month: "Dec 2025", total: 24_800_000, growth: 9_200_000, business: 7_100_000 },
  { month: "Jan 2026", total: 24_200_000, growth: 8_900_000, business: 6_900_000 },
  { month: "Feb 2026", total: 25_100_000, growth: 9_400_000, business: 7_300_000 },
  { month: "Mar 2026", total: 26_400_000, growth: 9_800_000, business: 7_800_000 },
  { month: "Apr 2026", total: 27_200_000, growth: 10_100_000, business: 8_200_000 },
  { month: "May 2026", total: 28_470_000, growth: 10_600_000, business: 8_700_000 },
];

export const mockUsers: PlatformUser[] = [
  { userId: "usr_001", name: "Amina Hassan", phone: "+255712345678", email: "amina@gmail.com", status: "active", createdAt: "2024-03-15T10:00:00Z", lastLoginAt: "2026-05-28T08:30:00Z", deviceInfo: "Android 14 / Samsung Galaxy A54", businessCount: 2, defaultBusinessId: "biz_001" },
  { userId: "usr_002", name: "Mohamed Juma", phone: "+255754321987", status: "active", createdAt: "2024-04-02T14:00:00Z", lastLoginAt: "2026-05-27T16:00:00Z", deviceInfo: "iOS 17 / iPhone 13", businessCount: 1, defaultBusinessId: "biz_002" },
  { userId: "usr_003", name: "Grace Mwangi", phone: "+255765432109", email: "grace.mwangi@outlook.com", status: "suspended", createdAt: "2024-05-10T09:00:00Z", lastLoginAt: "2026-04-15T11:00:00Z", deviceInfo: "Android 13 / Tecno Spark", businessCount: 1, defaultBusinessId: "biz_003" },
  { userId: "usr_004", name: "David Kimani", phone: "+255723456789", status: "active", createdAt: "2024-06-20T12:00:00Z", lastLoginAt: "2026-05-29T07:15:00Z", deviceInfo: "Android 14 / Redmi Note 12", businessCount: 3, defaultBusinessId: "biz_004" },
  { userId: "usr_005", name: "Fatuma Said", phone: "+255745678901", email: "fatuma@yahoo.com", status: "active", createdAt: "2024-07-08T08:00:00Z", lastLoginAt: "2026-05-28T14:20:00Z", deviceInfo: "iOS 16 / iPhone 12", businessCount: 1, defaultBusinessId: "biz_005" },
  { userId: "usr_006", name: "John Msemwa", phone: "+255789012345", status: "pending", createdAt: "2026-05-27T06:00:00Z", lastLoginAt: "2026-05-27T06:05:00Z", deviceInfo: "Android 12 / Infinix Hot 20", businessCount: 0, defaultBusinessId: "" },
  { userId: "usr_007", name: "Aisha Bakari", phone: "+255734567890", status: "active", createdAt: "2024-08-14T11:00:00Z", lastLoginAt: "2026-05-29T09:00:00Z", deviceInfo: "Android 13 / Xiaomi Redmi 10", businessCount: 2, defaultBusinessId: "biz_007" },
  { userId: "usr_008", name: "Peter Ochieng", phone: "+255756789012", status: "active", createdAt: "2024-09-01T15:00:00Z", lastLoginAt: "2026-05-26T13:00:00Z", deviceInfo: "iOS 17 / iPhone 14", businessCount: 1, defaultBusinessId: "biz_008" },
  { userId: "usr_009", name: "Zawadi Nyerere", phone: "+255701234567", status: "suspended", createdAt: "2024-10-22T10:00:00Z", lastLoginAt: "2026-03-10T10:00:00Z", deviceInfo: "Android 11 / Samsung A22", businessCount: 1, defaultBusinessId: "biz_009" },
  { userId: "usr_010", name: "Emmanuel Tarimo", phone: "+255718901234", status: "active", createdAt: "2024-11-05T09:00:00Z", lastLoginAt: "2026-05-28T17:00:00Z", deviceInfo: "Android 14 / Tecno Camon 20", businessCount: 1, defaultBusinessId: "biz_010" },
];

export const mockBusinesses: Business[] = [
  { bizId: "biz_001", name: "Amina's Duka", type: "Retail Shop", ownerName: "Amina Hassan", ownerPhone: "+255712345678", planTier: "growth", status: "active", staffCount: 3, createdAt: "2024-03-16T10:00:00Z", lastActiveAt: "2026-05-29T08:30:00Z", location: "Dar es Salaam", monthlyRevenue: 4_200_000, invoiceCount: 87, customerCount: 142, subscriptionId: "sub_001" },
  { bizId: "biz_002", name: "Mohamed Hardware", type: "Hardware Store", ownerName: "Mohamed Juma", ownerPhone: "+255754321987", planTier: "business", status: "active", staffCount: 7, createdAt: "2024-04-03T14:00:00Z", lastActiveAt: "2026-05-27T16:00:00Z", location: "Arusha", monthlyRevenue: 12_800_000, invoiceCount: 213, customerCount: 356, subscriptionId: "sub_002" },
  { bizId: "biz_003", name: "Grace Beauty Salon", type: "Salon & Spa", ownerName: "Grace Mwangi", ownerPhone: "+255765432109", planTier: "starter", status: "suspended", staffCount: 2, createdAt: "2024-05-11T09:00:00Z", lastActiveAt: "2026-04-15T11:00:00Z", location: "Nairobi", monthlyRevenue: 0, invoiceCount: 34, customerCount: 89, subscriptionId: "sub_003" },
  { bizId: "biz_004", name: "Kimani Logistics", type: "Transport & Logistics", ownerName: "David Kimani", ownerPhone: "+255723456789", planTier: "enterprise", status: "active", staffCount: 15, createdAt: "2024-06-21T12:00:00Z", lastActiveAt: "2026-05-29T07:15:00Z", location: "Mombasa", monthlyRevenue: 45_000_000, invoiceCount: 521, customerCount: 78, subscriptionId: "sub_004" },
  { bizId: "biz_005", name: "Fatuma Restaurant", type: "Restaurant & Catering", ownerName: "Fatuma Said", ownerPhone: "+255745678901", planTier: "growth", status: "active", staffCount: 5, createdAt: "2024-07-09T08:00:00Z", lastActiveAt: "2026-05-28T14:20:00Z", location: "Dar es Salaam", monthlyRevenue: 6_500_000, invoiceCount: 312, customerCount: 890, subscriptionId: "sub_005" },
  { bizId: "biz_007", name: "Aisha Fashion House", type: "Clothing & Fashion", ownerName: "Aisha Bakari", ownerPhone: "+255734567890", planTier: "growth", status: "trial", staffCount: 2, createdAt: "2024-08-15T11:00:00Z", lastActiveAt: "2026-05-29T09:00:00Z", location: "Zanzibar", monthlyRevenue: 1_200_000, invoiceCount: 21, customerCount: 54, subscriptionId: "sub_007" },
  { bizId: "biz_008", name: "Ochieng Electronics", type: "Electronics", ownerName: "Peter Ochieng", ownerPhone: "+255756789012", planTier: "business", status: "active", staffCount: 6, createdAt: "2024-09-02T15:00:00Z", lastActiveAt: "2026-05-26T13:00:00Z", location: "Kampala", monthlyRevenue: 18_400_000, invoiceCount: 178, customerCount: 234, subscriptionId: "sub_008" },
  { bizId: "biz_009", name: "Nyerere Pharmacy", type: "Pharmacy", ownerName: "Zawadi Nyerere", ownerPhone: "+255701234567", planTier: "starter", status: "churned", staffCount: 1, createdAt: "2024-10-23T10:00:00Z", lastActiveAt: "2026-03-10T10:00:00Z", location: "Dodoma", monthlyRevenue: 0, invoiceCount: 12, customerCount: 45, subscriptionId: "sub_009" },
  { bizId: "biz_010", name: "Tarimo Agro Supplies", type: "Agriculture", ownerName: "Emmanuel Tarimo", ownerPhone: "+255718901234", planTier: "growth", status: "active", staffCount: 4, createdAt: "2024-11-06T09:00:00Z", lastActiveAt: "2026-05-28T17:00:00Z", location: "Moshi", monthlyRevenue: 8_900_000, invoiceCount: 94, customerCount: 167, subscriptionId: "sub_010" },
];

export const mockSubscriptions: Subscription[] = [
  { subscriptionId: "sub_001", bizId: "biz_001", bizName: "Amina's Duka", planTier: "growth", status: "active", amount: 30_000, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-05-01", currentPeriodEnd: "2026-05-31", paymentMethod: "M-Pesa", lastPaymentAt: "2026-05-01T08:00:00Z" },
  { subscriptionId: "sub_002", bizId: "biz_002", bizName: "Mohamed Hardware", planTier: "business", status: "active", amount: 70_000, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-05-01", currentPeriodEnd: "2026-05-31", paymentMethod: "Airtel Money", lastPaymentAt: "2026-05-01T09:30:00Z" },
  { subscriptionId: "sub_003", bizId: "biz_003", bizName: "Grace Beauty Salon", planTier: "starter", status: "cancelled", amount: 0, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-04-01", currentPeriodEnd: "2026-04-30", paymentMethod: "M-Pesa", lastPaymentAt: "2026-04-01T00:00:00Z" },
  { subscriptionId: "sub_004", bizId: "biz_004", bizName: "Kimani Logistics", planTier: "enterprise", status: "active", amount: 200_000, currency: "TZS", billingCycle: "annual", currentPeriodStart: "2026-01-01", currentPeriodEnd: "2026-12-31", paymentMethod: "Bank Transfer", lastPaymentAt: "2026-01-02T10:00:00Z" },
  { subscriptionId: "sub_005", bizId: "biz_005", bizName: "Fatuma Restaurant", planTier: "growth", status: "overdue", amount: 30_000, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-04-01", currentPeriodEnd: "2026-04-30", paymentMethod: "M-Pesa", lastPaymentAt: "2026-04-01T00:00:00Z" },
  { subscriptionId: "sub_007", bizId: "biz_007", bizName: "Aisha Fashion House", planTier: "growth", status: "trial", amount: 0, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-05-15", currentPeriodEnd: "2026-06-14", paymentMethod: "N/A", lastPaymentAt: "", trialEndsAt: "2026-06-14" },
  { subscriptionId: "sub_008", bizId: "biz_008", bizName: "Ochieng Electronics", planTier: "business", status: "active", amount: 70_000, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-05-01", currentPeriodEnd: "2026-05-31", paymentMethod: "Bank Transfer", lastPaymentAt: "2026-05-01T11:00:00Z" },
  { subscriptionId: "sub_010", bizId: "biz_010", bizName: "Tarimo Agro Supplies", planTier: "growth", status: "active", amount: 30_000, currency: "TZS", billingCycle: "monthly", currentPeriodStart: "2026-05-01", currentPeriodEnd: "2026-05-31", paymentMethod: "M-Pesa", lastPaymentAt: "2026-05-01T07:00:00Z" },
];

export const mockAuditLogs: AuditLog[] = [
  { logId: "log_001", adminId: "adm_001", adminName: "Derick Mhidze", action: "suspend_account", resourceType: "user", resourceId: "usr_003", before: { status: "active" }, after: { status: "suspended" }, ipAddress: "197.186.12.45", timestamp: "2026-05-28T14:30:00Z" },
  { logId: "log_002", adminId: "adm_001", adminName: "Derick Mhidze", action: "upgrade_plan", resourceType: "subscription", resourceId: "sub_008", before: { planTier: "growth" }, after: { planTier: "business" }, ipAddress: "197.186.12.45", timestamp: "2026-05-27T10:15:00Z" },
  { logId: "log_003", adminId: "adm_002", adminName: "Neema Shirima", action: "extend_trial", resourceType: "subscription", resourceId: "sub_007", before: { trialEndsAt: "2026-06-07" }, after: { trialEndsAt: "2026-06-14" }, ipAddress: "197.186.12.60", timestamp: "2026-05-26T09:00:00Z" },
  { logId: "log_004", adminId: "adm_001", adminName: "Derick Mhidze", action: "add_internal_note", resourceType: "business", resourceId: "biz_005", ipAddress: "197.186.12.45", timestamp: "2026-05-25T16:45:00Z" },
  { logId: "log_005", adminId: "adm_003", adminName: "Joseph Lema", action: "update_feature_flag", resourceType: "feature_flag", resourceId: "flag_mpesa", before: { globalEnabled: false }, after: { globalEnabled: true }, ipAddress: "41.72.144.22", timestamp: "2026-05-24T11:00:00Z" },
  { logId: "log_006", adminId: "adm_001", adminName: "Derick Mhidze", action: "update_config", resourceType: "platform_config", resourceId: "pricing", before: { growthMonthly: 25000 }, after: { growthMonthly: 30000 }, ipAddress: "197.186.12.45", timestamp: "2026-05-20T09:00:00Z" },
];

export const mockServiceHealth: ServiceHealth[] = [
  { serviceName: "api-gateway", status: "healthy", uptime: "99.98%", p95Latency: 45, requestsPerMin: 1243, errorRate: 0.02, containerCount: 3, lastChecked: new Date().toISOString() },
  { serviceName: "auth", status: "healthy", uptime: "99.99%", p95Latency: 38, requestsPerMin: 892, errorRate: 0.01, containerCount: 2, lastChecked: new Date().toISOString() },
  { serviceName: "invoicing", status: "healthy", uptime: "99.95%", p95Latency: 120, requestsPerMin: 456, errorRate: 0.05, containerCount: 2, lastChecked: new Date().toISOString() },
  { serviceName: "inventory", status: "degraded", uptime: "98.72%", p95Latency: 380, requestsPerMin: 234, errorRate: 2.4, containerCount: 1, lastChecked: new Date().toISOString() },
  { serviceName: "customers", status: "healthy", uptime: "99.97%", p95Latency: 67, requestsPerMin: 312, errorRate: 0.03, containerCount: 2, lastChecked: new Date().toISOString() },
  { serviceName: "expenses", status: "healthy", uptime: "99.94%", p95Latency: 89, requestsPerMin: 187, errorRate: 0.06, containerCount: 2, lastChecked: new Date().toISOString() },
  { serviceName: "cashflow", status: "healthy", uptime: "99.96%", p95Latency: 95, requestsPerMin: 143, errorRate: 0.04, containerCount: 1, lastChecked: new Date().toISOString() },
  { serviceName: "suppliers", status: "healthy", uptime: "99.93%", p95Latency: 78, requestsPerMin: 98, errorRate: 0.07, containerCount: 1, lastChecked: new Date().toISOString() },
  { serviceName: "reports", status: "healthy", uptime: "99.89%", p95Latency: 245, requestsPerMin: 67, errorRate: 0.11, containerCount: 1, lastChecked: new Date().toISOString() },
  { serviceName: "notifications", status: "healthy", uptime: "99.91%", p95Latency: 55, requestsPerMin: 412, errorRate: 0.09, containerCount: 2, lastChecked: new Date().toISOString() },
  { serviceName: "admin-api", status: "healthy", uptime: "99.97%", p95Latency: 42, requestsPerMin: 34, errorRate: 0.03, containerCount: 1, lastChecked: new Date().toISOString() },
];

export const mockActivity: ActivityEvent[] = [
  { eventId: "evt_001", type: "new_signup", description: "New user signed up: John Msemwa (+255789012345)", userId: "usr_006", timestamp: "2026-05-29T06:00:00Z", severity: "info" },
  { eventId: "evt_002", type: "payment_received", description: "Payment received: TZS 30,000 from Amina's Duka", bizId: "biz_001", timestamp: "2026-05-29T05:45:00Z", severity: "info" },
  { eventId: "evt_003", type: "payment_overdue", description: "Subscription overdue: Fatuma Restaurant (30 days)", bizId: "biz_005", timestamp: "2026-05-29T05:30:00Z", severity: "warning" },
  { eventId: "evt_004", type: "service_degraded", description: "inventory service p95 latency exceeded 200ms threshold", timestamp: "2026-05-29T05:15:00Z", severity: "warning" },
  { eventId: "evt_005", type: "new_signup", description: "New user signed up: Rehema Mushi (+255712398765)", timestamp: "2026-05-29T04:50:00Z", severity: "info" },
  { eventId: "evt_006", type: "business_churned", description: "Nyerere Pharmacy subscription cancelled", bizId: "biz_009", timestamp: "2026-05-28T22:00:00Z", severity: "warning" },
  { eventId: "evt_007", type: "plan_upgrade", description: "Ochieng Electronics upgraded from Growth to Business", bizId: "biz_008", timestamp: "2026-05-28T16:00:00Z", severity: "info" },
  { eventId: "evt_008", type: "account_suspended", description: "User account suspended: Grace Mwangi (+255765432109)", userId: "usr_003", timestamp: "2026-05-28T14:30:00Z", severity: "warning" },
  { eventId: "evt_009", type: "payment_received", description: "Payment received: TZS 70,000 from Ochieng Electronics", bizId: "biz_008", timestamp: "2026-05-28T11:00:00Z", severity: "info" },
  { eventId: "evt_010", type: "new_business", description: "New business registered: Aisha Fashion House", bizId: "biz_007", timestamp: "2026-05-28T09:20:00Z", severity: "info" },
];

export const mockSupportTickets: SupportTicket[] = [
  { ticketId: "tkt_001", priority: "high", bizId: "biz_005", bizName: "Fatuma Restaurant", ownerPhone: "+255745678901", issueType: "billing_dispute", status: "open", createdAt: "2026-05-28T10:00:00Z", updatedAt: "2026-05-28T10:00:00Z", description: "Customer disputes overdue charge, claims M-Pesa payment was made on May 1st but not reflected.", notes: [] },
  { ticketId: "tkt_002", priority: "critical", bizId: "biz_003", bizName: "Grace Beauty Salon", ownerPhone: "+255765432109", issueType: "account_locked", status: "in_progress", assignedTo: "Neema Shirima", createdAt: "2026-05-27T15:30:00Z", updatedAt: "2026-05-28T09:00:00Z", description: "Account suspended in error. Owner claims all payments are up to date.", notes: [{ noteId: "note_001", authorId: "adm_002", authorName: "Neema Shirima", content: "Investigating payment records. M-Pesa transaction ID: ABC123456", createdAt: "2026-05-28T09:00:00Z" }] },
  { ticketId: "tkt_003", priority: "medium", bizId: "biz_002", bizName: "Mohamed Hardware", ownerPhone: "+255754321987", issueType: "data_issue", status: "resolved", assignedTo: "Derick Mhidze", createdAt: "2026-05-25T08:00:00Z", updatedAt: "2026-05-26T14:00:00Z", description: "Inventory count not syncing properly after recent app update.", notes: [] },
  { ticketId: "tkt_004", priority: "low", bizId: "biz_007", bizName: "Aisha Fashion House", ownerPhone: "+255734567890", issueType: "feature_request", status: "open", createdAt: "2026-05-29T07:30:00Z", updatedAt: "2026-05-29T07:30:00Z", description: "Requesting integration with Instagram for product catalog sync.", notes: [] },
];

export const mockFeatureFlags: FeatureFlag[] = [
  { flagId: "flag_001", name: "mpesa_auto_import", displayName: "M-Pesa Auto Import", description: "Automatically import M-Pesa transactions into cashflow", globalEnabled: true, rolloutPercentage: 100, specificUsers: [], specificBusinesses: [], updatedAt: "2026-05-24T11:00:00Z", updatedBy: "Joseph Lema" },
  { flagId: "flag_002", name: "ai_invoice_suggestions", displayName: "AI Invoice Suggestions", description: "Use AI to suggest line items and pricing based on history", globalEnabled: false, rolloutPercentage: 20, specificUsers: [], specificBusinesses: ["biz_002", "biz_004"], updatedAt: "2026-05-20T09:00:00Z", updatedBy: "Derick Mhidze" },
  { flagId: "flag_003", name: "whatsapp_notifications", displayName: "WhatsApp Notifications", description: "Send payment reminders and invoices via WhatsApp", globalEnabled: true, rolloutPercentage: 85, specificUsers: [], specificBusinesses: [], updatedAt: "2026-05-15T14:00:00Z", updatedBy: "Neema Shirima" },
  { flagId: "flag_004", name: "multi_currency", displayName: "Multi-Currency Support", description: "Allow businesses to invoice in USD and EUR in addition to TZS", globalEnabled: false, rolloutPercentage: 0, specificUsers: [], specificBusinesses: ["biz_004"], updatedAt: "2026-04-30T10:00:00Z", updatedBy: "Joseph Lema" },
  { flagId: "flag_005", name: "advanced_analytics", displayName: "Advanced Analytics", description: "Enhanced business intelligence reports and forecasting", globalEnabled: false, rolloutPercentage: 10, specificUsers: [], specificBusinesses: [], updatedAt: "2026-05-10T08:00:00Z", updatedBy: "Derick Mhidze" },
  { flagId: "flag_006", name: "offline_mode", displayName: "Offline Mode (Beta)", description: "Allow app to function with limited connectivity", globalEnabled: true, rolloutPercentage: 60, specificUsers: [], specificBusinesses: [], updatedAt: "2026-05-18T16:00:00Z", updatedBy: "Joseph Lema" },
];
