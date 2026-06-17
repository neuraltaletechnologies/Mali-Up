import type {
  AdminUser, Business, Subscription, LifetimeSubscription, RefundRequest,
  SupportTicket, AuditEntry, ServiceHealth, FeatureFlag, MasterProduct,
  CommunitySubmission, PlatformConfig
} from '@/types'

// ─── Users ───────────────────────────────────────────────────────────────────

export const mockUsers: AdminUser[] = [
  { id: 'u1', name: 'Amina Juma', phone: '+255712345001', status: 'active', businessCount: 2, lastLogin: '2026-06-17T07:22:00Z', joinedAt: '2025-01-15T09:00:00Z' },
  { id: 'u2', name: 'Mohamed Hassan', phone: '+255712345002', status: 'active', businessCount: 1, lastLogin: '2026-06-16T18:45:00Z', joinedAt: '2025-02-20T10:30:00Z' },
  { id: 'u3', name: 'Grace Mwangi', phone: '+255712345003', status: 'suspended', businessCount: 1, lastLogin: '2026-05-30T11:00:00Z', joinedAt: '2025-03-10T08:00:00Z' },
  { id: 'u4', name: 'Joseph Kimaro', phone: '+255712345004', status: 'active', businessCount: 3, lastLogin: '2026-06-17T06:00:00Z', joinedAt: '2024-11-05T14:00:00Z' },
  { id: 'u5', name: 'Fatuma Rashid', phone: '+255712345005', status: 'active', businessCount: 1, lastLogin: '2026-06-15T20:10:00Z', joinedAt: '2025-04-22T11:00:00Z' },
  { id: 'u6', name: 'Peter Moshi', phone: '+255712345006', status: 'pending', businessCount: 0, lastLogin: '2026-06-17T08:00:00Z', joinedAt: '2026-06-17T07:55:00Z' },
  { id: 'u7', name: 'Zainab Ahmed', phone: '+255712345007', status: 'active', businessCount: 1, lastLogin: '2026-06-14T15:30:00Z', joinedAt: '2025-06-01T09:00:00Z' },
  { id: 'u8', name: 'David Ndunguru', phone: '+255712345008', status: 'active', businessCount: 2, lastLogin: '2026-06-17T05:45:00Z', joinedAt: '2025-01-30T10:00:00Z' },
  { id: 'u9', name: 'Halima Ally', phone: '+255712345009', status: 'active', businessCount: 1, lastLogin: '2026-06-16T12:00:00Z', joinedAt: '2025-07-15T08:30:00Z' },
  { id: 'u10', name: 'Emmanuel Mwamba', phone: '+255712345010', status: 'suspended', businessCount: 1, lastLogin: '2026-04-01T09:00:00Z', joinedAt: '2025-02-14T10:00:00Z' },
]

// ─── Businesses ──────────────────────────────────────────────────────────────

export const mockBusinesses: Business[] = [
  {
    id: 'b1', name: 'Karibu Duka la Dawa', ownerId: 'u1', ownerName: 'Amina Juma',
    ownerPhone: '+255712345001', plan: 'lifetime', status: 'active',
    staffCount: 4, lastActive: '2026-06-17T07:10:00Z', createdAt: '2025-01-20T09:00:00Z',
    mrr: 0, industry: 'Pharmacy', location: 'Dar es Salaam',
    invoiceCount: 312, totalRevenue: 48_500_000, receivables: 2_100_000, expenseTotal: 18_000_000,
  },
  {
    id: 'b2', name: 'Hassan Supermarket', ownerId: 'u2', ownerName: 'Mohamed Hassan',
    ownerPhone: '+255712345002', plan: 'business', status: 'active',
    staffCount: 12, lastActive: '2026-06-16T19:00:00Z', createdAt: '2025-02-25T10:00:00Z',
    mrr: 120_000, industry: 'Supermarket', location: 'Arusha',
    invoiceCount: 580, totalRevenue: 125_000_000, receivables: 8_500_000, expenseTotal: 72_000_000,
  },
  {
    id: 'b3', name: 'Biashara Vifaa', ownerId: 'u4', ownerName: 'Joseph Kimaro',
    ownerPhone: '+255712345004', plan: 'growth', status: 'active',
    staffCount: 3, lastActive: '2026-06-17T06:15:00Z', createdAt: '2024-11-10T08:00:00Z',
    mrr: 49_000, industry: 'Hardware', location: 'Mwanza',
    invoiceCount: 145, totalRevenue: 32_000_000, receivables: 4_200_000, expenseTotal: 22_000_000,
  },
  {
    id: 'b4', name: 'Zawadi Fashion', ownerId: 'u5', ownerName: 'Fatuma Rashid',
    ownerPhone: '+255712345005', plan: 'starter', status: 'active',
    staffCount: 1, lastActive: '2026-06-15T20:30:00Z', createdAt: '2025-04-25T11:00:00Z',
    mrr: 0, industry: 'Boutique', location: 'Dodoma',
    invoiceCount: 28, totalRevenue: 4_500_000, receivables: 300_000, expenseTotal: 3_200_000,
  },
  {
    id: 'b5', name: 'Kipaji Electronics', ownerId: 'u7', ownerName: 'Zainab Ahmed',
    ownerPhone: '+255712345007', plan: 'enterprise', status: 'active',
    staffCount: 8, lastActive: '2026-06-14T16:00:00Z', createdAt: '2025-06-05T09:00:00Z',
    mrr: 350_000, industry: 'Electronics', location: 'Dar es Salaam',
    invoiceCount: 94, totalRevenue: 58_000_000, receivables: 6_000_000, expenseTotal: 40_000_000,
  },
  {
    id: 'b6', name: 'Mwangaza Restaurant', ownerId: 'u8', ownerName: 'David Ndunguru',
    ownerPhone: '+255712345008', plan: 'growth', status: 'active',
    staffCount: 6, lastActive: '2026-06-17T06:00:00Z', createdAt: '2025-02-01T10:00:00Z',
    mrr: 49_000, industry: 'Restaurant', location: 'Zanzibar',
    invoiceCount: 890, totalRevenue: 38_000_000, receivables: 0, expenseTotal: 28_000_000,
  },
  {
    id: 'b7', name: 'Salama Pharmacy', ownerId: 'u9', ownerName: 'Halima Ally',
    ownerPhone: '+255712345009', plan: 'lifetime', status: 'active',
    staffCount: 2, lastActive: '2026-06-16T12:30:00Z', createdAt: '2025-07-20T08:00:00Z',
    mrr: 0, industry: 'Pharmacy', location: 'Moshi',
    invoiceCount: 204, totalRevenue: 28_000_000, receivables: 1_200_000, expenseTotal: 18_500_000,
  },
  {
    id: 'b8', name: 'Imani Hardware', ownerId: 'u4', ownerName: 'Joseph Kimaro',
    ownerPhone: '+255712345004', plan: 'business', status: 'suspended',
    staffCount: 5, lastActive: '2026-05-10T09:00:00Z', createdAt: '2025-03-15T09:00:00Z',
    mrr: 120_000, industry: 'Hardware', location: 'Dar es Salaam',
    invoiceCount: 88, totalRevenue: 15_000_000, receivables: 2_800_000, expenseTotal: 12_000_000,
  },
]

// ─── Subscriptions ────────────────────────────────────────────────────────────

export const mockSubscriptions: Subscription[] = [
  { id: 's1', businessId: 'b2', businessName: 'Hassan Supermarket', plan: 'business', status: 'active', amount: 120_000, nextBillingDate: '2026-07-25T00:00:00Z', paymentMethod: 'M-Pesa', startedAt: '2025-02-25T00:00:00Z' },
  { id: 's2', businessId: 'b3', businessName: 'Biashara Vifaa', plan: 'growth', status: 'active', amount: 49_000, nextBillingDate: '2026-07-10T00:00:00Z', paymentMethod: 'Airtel Money', startedAt: '2024-11-10T00:00:00Z' },
  { id: 's3', businessId: 'b5', businessName: 'Kipaji Electronics', plan: 'enterprise', status: 'active', amount: 350_000, nextBillingDate: '2026-07-05T00:00:00Z', paymentMethod: 'Bank Transfer', startedAt: '2025-06-05T00:00:00Z' },
  { id: 's4', businessId: 'b6', businessName: 'Mwangaza Restaurant', plan: 'growth', status: 'active', amount: 49_000, nextBillingDate: '2026-07-01T00:00:00Z', paymentMethod: 'M-Pesa', startedAt: '2025-02-01T00:00:00Z' },
  { id: 's5', businessId: 'b8', businessName: 'Imani Hardware', plan: 'business', status: 'past_due', amount: 120_000, nextBillingDate: '2026-06-15T00:00:00Z', paymentMethod: 'Airtel Money', startedAt: '2025-03-15T00:00:00Z' },
]

// ─── Lifetime Subscriptions ────────────────────────────────────────────────────

export const mockLifetime: LifetimeSubscription[] = [
  {
    id: 'l1', businessId: 'b1', businessName: 'Karibu Duka la Dawa', ownerName: 'Amina Juma',
    tier: 'growth', principal: 4_900_000, activatedAt: '2025-01-20T00:00:00Z',
    monthsActive: 17, uttAMISBalance: 5_633_000, thisMonthReturn: 49_000, status: 'active',
    uttAMISReference: 'UTT-2025-00124', monthlyFee: 49_000,
  },
  {
    id: 'l2', businessId: 'b7', businessName: 'Salama Pharmacy', ownerName: 'Halima Ally',
    tier: 'growth', principal: 4_900_000, activatedAt: '2025-07-20T00:00:00Z',
    monthsActive: 11, uttAMISBalance: 5_390_000, thisMonthReturn: 49_000, status: 'active',
    uttAMISReference: 'UTT-2025-00287', monthlyFee: 49_000,
  },
  {
    id: 'l3', businessId: 'bx', businessName: 'Kilimanjaro Trading Co.', ownerName: 'Rashid Omari',
    tier: 'business', principal: 12_000_000, activatedAt: '2024-10-01T00:00:00Z',
    monthsActive: 20, uttAMISBalance: 14_400_000, thisMonthReturn: 120_000, status: 'refund_requested',
    uttAMISReference: 'UTT-2024-00891', monthlyFee: 120_000,
  },
]

// ─── Refunds ──────────────────────────────────────────────────────────────────

export const mockRefunds: RefundRequest[] = [
  {
    id: 'r1', businessId: 'bx', businessName: 'Kilimanjaro Trading Co.',
    tier: 'business', principal: 12_000_000, monthsHeld: 20, monthlyFee: 120_000,
    requestedAt: '2026-06-10T09:00:00Z', status: 'requested',
  },
  {
    id: 'r2', businessId: 'by', businessName: 'Jua Kali Supplies',
    tier: 'growth', principal: 4_900_000, monthsHeld: 8, monthlyFee: 49_000,
    requestedAt: '2026-05-28T11:00:00Z', status: 'processing', processedAt: '2026-06-01T14:00:00Z',
  },
  {
    id: 'r3', businessId: 'bz', businessName: 'Msaada Electronics',
    tier: 'growth', principal: 4_900_000, monthsHeld: 30, monthlyFee: 49_000,
    requestedAt: '2026-04-15T08:00:00Z', status: 'completed',
    processedAt: '2026-04-18T10:00:00Z', completedAt: '2026-04-22T16:00:00Z',
  },
]

// ─── Support Tickets ──────────────────────────────────────────────────────────

export const mockTickets: SupportTicket[] = [
  {
    id: 't1', businessId: 'b2', businessName: 'Hassan Supermarket', ownerName: 'Mohamed Hassan',
    priority: 'urgent', status: 'open', issueType: 'Sync failure',
    createdAt: '2026-06-17T06:30:00Z', updatedAt: '2026-06-17T06:30:00Z',
  },
  {
    id: 't2', businessId: 'b3', businessName: 'Biashara Vifaa', ownerName: 'Joseph Kimaro',
    priority: 'normal', status: 'in_progress', issueType: 'Invoice export', assignedAdmin: 'Admin',
    createdAt: '2026-06-16T14:00:00Z', updatedAt: '2026-06-16T18:00:00Z',
  },
  {
    id: 't3', businessId: 'b5', businessName: 'Kipaji Electronics', ownerName: 'Zainab Ahmed',
    priority: 'low', status: 'resolved', issueType: 'Billing question',
    createdAt: '2026-06-14T10:00:00Z', updatedAt: '2026-06-15T09:00:00Z',
  },
  {
    id: 't4', businessId: 'b7', businessName: 'Salama Pharmacy', ownerName: 'Halima Ally',
    priority: 'urgent', status: 'open', issueType: 'Login blocked',
    createdAt: '2026-06-17T07:45:00Z', updatedAt: '2026-06-17T07:45:00Z',
  },
]

// ─── Audit Log ────────────────────────────────────────────────────────────────

export const mockAuditLog: AuditEntry[] = [
  { id: 'a1', adminId: 'admin1', adminName: 'Julius Ntale', action: 'suspend_business', resourceType: 'business', resourceId: 'b8', resourceName: 'Imani Hardware', isDestructive: true, createdAt: '2026-06-15T11:30:00Z', ip: '196.13.0.1' },
  { id: 'a2', adminId: 'admin1', adminName: 'Julius Ntale', action: 'update_feature_flag', resourceType: 'feature_flag', resourceId: 'ff2', resourceName: 'catalog_v2', before: { enabled: false }, after: { enabled: true }, isDestructive: false, createdAt: '2026-06-14T09:00:00Z', ip: '196.13.0.1' },
  { id: 'a3', adminId: 'admin1', adminName: 'Julius Ntale', action: 'initiate_refund', resourceType: 'refund', resourceId: 'r2', resourceName: 'Jua Kali Supplies', isDestructive: false, createdAt: '2026-06-01T14:00:00Z', ip: '196.13.0.1' },
  { id: 'a4', adminId: 'admin1', adminName: 'Julius Ntale', action: 'update_config', resourceType: 'config', resourceId: 'pricing', resourceName: 'Platform Pricing', before: { growth: 45000 }, after: { growth: 49000 }, isDestructive: false, createdAt: '2026-05-30T10:00:00Z', ip: '196.13.0.1' },
  { id: 'a5', adminId: 'admin1', adminName: 'Julius Ntale', action: 'delete_product', resourceType: 'catalog', resourceId: 'p44', resourceName: 'Aspirin 500mg (duplicate)', isDestructive: true, createdAt: '2026-05-28T16:00:00Z', ip: '196.13.0.1' },
]

// ─── System Health ────────────────────────────────────────────────────────────

export const mockServices: ServiceHealth[] = [
  { name: 'api-gateway',   displayName: 'API Gateway',        status: 'healthy',  uptime: 99.98, p95Latency: 32,  sparkline: [28, 30, 35, 32, 29, 31, 32] },
  { name: 'auth',          displayName: 'Auth Service',        status: 'healthy',  uptime: 99.99, p95Latency: 18,  sparkline: [15, 18, 17, 20, 18, 16, 18] },
  { name: 'invoicing',     displayName: 'Invoicing',           status: 'healthy',  uptime: 99.95, p95Latency: 45,  sparkline: [40, 42, 48, 55, 50, 45, 45] },
  { name: 'inventory',     displayName: 'Inventory',           status: 'degraded', uptime: 98.20, p95Latency: 340, sparkline: [42, 50, 60, 340, 280, 310, 340] },
  { name: 'customers',     displayName: 'Customers',           status: 'healthy',  uptime: 99.97, p95Latency: 28,  sparkline: [24, 26, 28, 30, 28, 27, 28] },
  { name: 'expenses',      displayName: 'Expenses',            status: 'healthy',  uptime: 99.96, p95Latency: 35,  sparkline: [30, 32, 38, 35, 33, 35, 35] },
  { name: 'cashflow',      displayName: 'Cash Flow',           status: 'healthy',  uptime: 99.94, p95Latency: 52,  sparkline: [45, 48, 55, 60, 52, 50, 52] },
  { name: 'suppliers',     displayName: 'Suppliers',           status: 'healthy',  uptime: 99.99, p95Latency: 22,  sparkline: [20, 21, 22, 24, 22, 21, 22] },
  { name: 'reports',       displayName: 'Reports',             status: 'healthy',  uptime: 99.90, p95Latency: 180, sparkline: [150, 160, 200, 180, 170, 175, 180] },
  { name: 'notifications', displayName: 'Notifications',       status: 'healthy',  uptime: 99.97, p95Latency: 15,  sparkline: [12, 14, 16, 15, 14, 15, 15] },
  { name: 'admin-api',     displayName: 'Admin API',           status: 'healthy',  uptime: 99.99, p95Latency: 25,  sparkline: [22, 24, 26, 25, 24, 25, 25] },
]

// ─── Feature Flags ────────────────────────────────────────────────────────────

export const mockFlags: FeatureFlag[] = [
  { id: 'ff1', name: 'offline_sync_v2', description: 'New conflict resolution engine for offline sync', enabled: true, rolloutPercent: 100, overrides: [] },
  { id: 'ff2', name: 'catalog_v2', description: 'Enhanced master catalog with community submissions', enabled: true, rolloutPercent: 30, overrides: [{ id: 'b1', type: 'business', label: 'Karibu Duka la Dawa', enabled: true }] },
  { id: 'ff3', name: 'reports_module', description: 'Financial reports and analytics for businesses', enabled: false, rolloutPercent: 0, overrides: [] },
  { id: 'ff4', name: 'sms_invoices', description: 'Send invoices via SMS to customers without smartphones', enabled: true, rolloutPercent: 50, overrides: [] },
  { id: 'ff5', name: 'multi_currency', description: 'Support for USD and KES alongside TZS', enabled: false, rolloutPercent: 0, overrides: [{ id: 'b5', type: 'business', label: 'Kipaji Electronics', enabled: true }] },
]

// ─── Master Catalog ────────────────────────────────────────────────────────────

export const mockProducts: MasterProduct[] = [
  { id: 'p1', productName: 'Paracetamol 500mg', genericName: 'Paracetamol', brandNames: ['Panadol', 'Hedex'], businessType: 'Pharmacy', category: 'Analgesics', unit: 'tablet', unitAlternatives: ['strip', 'box'], commonBarcodes: ['5010119013458'], searchKeywords: ['paracetamol', 'panadol', 'pain relief', 'fever'], tags: ['otc', 'analgesic'], prescriptionRequired: false, coldStorage: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
  { id: 'p2', productName: 'Amoxicillin 250mg', genericName: 'Amoxicillin', brandNames: ['Amoxil', 'Trimox'], businessType: 'Pharmacy', category: 'Antibiotics', unit: 'capsule', unitAlternatives: ['strip', 'bottle'], commonBarcodes: [], searchKeywords: ['amoxicillin', 'antibiotic'], tags: ['prescription', 'antibiotic'], prescriptionRequired: true, coldStorage: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
  { id: 'p3', productName: 'Unga wa Semolina 1kg', genericName: 'Semolina Flour', brandNames: ['Bakhresa', 'Saruji'], businessType: 'Supermarket', category: 'Flour & Grains', unit: 'pack', unitAlternatives: ['kg'], commonBarcodes: ['6902265868645'], searchKeywords: ['semolina', 'unga', 'flour'], tags: ['staple', 'grain'], prescriptionRequired: false, coldStorage: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
  { id: 'p4', productName: 'Saruji ya Portland 50kg', genericName: 'Portland Cement', brandNames: ['Tanga Cement', 'ARM Cement'], businessType: 'Hardware', category: 'Building Materials', unit: 'bag', unitAlternatives: [], commonBarcodes: [], searchKeywords: ['cement', 'saruji', 'building'], tags: ['construction', 'bulk'], prescriptionRequired: false, coldStorage: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
]

// ─── Community Submissions ────────────────────────────────────────────────────

export const mockSubmissions: CommunitySubmission[] = [
  { id: 'cs1', productName: 'Dawa ya Malaria (AL 20/120)', businessName: 'Karibu Duka la Dawa', businessType: 'Pharmacy', submissionCount: 156, firstSeenAt: '2026-05-01T00:00:00Z', status: 'pending' },
  { id: 'cs2', productName: 'Mafuta ya Alizeti 2L', businessName: 'Hassan Supermarket', businessType: 'Supermarket', submissionCount: 89, firstSeenAt: '2026-05-15T00:00:00Z', status: 'pending' },
  { id: 'cs3', productName: 'Wire Mesh 2m x 1m', businessName: 'Biashara Vifaa', businessType: 'Hardware', submissionCount: 34, firstSeenAt: '2026-06-01T00:00:00Z', status: 'pending' },
]

// ─── Platform Config ──────────────────────────────────────────────────────────

export const mockConfig: PlatformConfig = {
  pricing: {
    starter: 0, growth: 49_000, business: 120_000, enterprise: 350_000,
    lifetimeMultiplier: 100, smsCreditPrice: 100, exportBundlePrice: 5_000,
  },
  planLimits: {
    starter: { users: 1 }, growth: { users: 3 }, business: { users: 10 },
    enterprise: { users: 50 }, lifetime: { users: 10 },
  },
  tax: { vatRate: 18, vatEnabled: true },
  lifetimeProgram: {
    uttAMISMonthlyRate: 1,
    cancellationFees: {
      growth:   [[3, 200_000], [12, 150_000], [24, 100_000], [36, 75_000], [Infinity, 50_000]],
      business: [[3, 500_000], [12, 350_000], [24, 250_000], [36, 175_000], [Infinity, 150_000]],
    },
  },
  platform: { maintenanceMode: false, maintenanceBanner: '' },
}

// ─── Dashboard KPIs ────────────────────────────────────────────────────────────

export const mockDashboardKPIs = {
  totalBusinesses: 847,
  activeToday: 312,
  mrr: 14_050_000,
  lifetimeAUM: 1_240_000_000,
  openTickets: 4,
  mrrTrend: [
    { month: 'Jul 25', value: 8_200_000 },
    { month: 'Aug 25', value: 8_900_000 },
    { month: 'Sep 25', value: 9_400_000 },
    { month: 'Oct 25', value: 10_100_000 },
    { month: 'Nov 25', value: 10_800_000 },
    { month: 'Dec 25', value: 11_500_000 },
    { month: 'Jan 26', value: 11_200_000 },
    { month: 'Feb 26', value: 11_900_000 },
    { month: 'Mar 26', value: 12_400_000 },
    { month: 'Apr 26', value: 13_100_000 },
    { month: 'May 26', value: 13_700_000 },
    { month: 'Jun 26', value: 14_050_000 },
  ],
  planDistribution: [
    { name: 'Starter',    value: 410, color: '#94A3B8' },
    { name: 'Growth',     value: 280, color: '#1A6E8A' },
    { name: 'Business',   value: 95,  color: '#0D1B3E' },
    { name: 'Enterprise', value: 12,  color: '#D97706' },
    { name: 'Lifetime',   value: 50,  color: '#16244D' },
  ],
  recentActivity: [
    { id: 'act1', text: 'New signup — Peter Moshi (Pending)', time: '2026-06-17T08:00:00Z' },
    { id: 'act2', text: 'Upgrade — Halima Ally to Lifetime', time: '2026-06-17T07:10:00Z' },
    { id: 'act3', text: 'Support ticket opened — Hassan Supermarket (Sync failure)', time: '2026-06-17T06:30:00Z' },
    { id: 'act4', text: 'New lifetime subscriber — Karibu Duka la Dawa', time: '2026-06-16T22:00:00Z' },
    { id: 'act5', text: 'Refund requested — Kilimanjaro Trading Co.', time: '2026-06-16T15:30:00Z' },
    { id: 'act6', text: 'New signup — Zainab Ahmed (Kipaji Electronics)', time: '2026-06-14T09:00:00Z' },
    { id: 'act7', text: 'Payment failed — Imani Hardware (Business plan, past due)', time: '2026-06-13T11:00:00Z' },
    { id: 'act8', text: 'Config updated — VAT rate changed to 18%', time: '2026-06-12T14:00:00Z' },
  ],
}
