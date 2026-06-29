import type {
  AdminUser, Business, AnalyticsOverview, CatalogProduct, CatalogCategory,
  Subscription, LifetimeSubscription, RefundRequest, SupportTicket, AuditEntry,
  ServiceHealth, FeatureFlag, CommunitySubmission, PlatformConfig,
  PlanDefinition, PlanDefinitions, PlanTier, AppLookups,
} from '@/types'

// ─── shared fetch wrapper ────────────────────────────────────────────────────

async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error((body as { error?: string }).error ?? `HTTP ${res.status}`)
  }
  return res.json() as Promise<T>
}

// ─── Users ───────────────────────────────────────────────────────────────────

export async function fetchUsers(limit = 200): Promise<{ users: AdminUser[]; total: number }> {
  return apiFetch(`/api/admin/users?limit=${limit}`)
}

export async function fetchUser(uid: string): Promise<{ user: AdminUser; businesses: Business[] }> {
  return apiFetch(`/api/admin/users/${uid}`)
}

export async function patchUser(uid: string, isActive: boolean): Promise<void> {
  await apiFetch(`/api/admin/users/${uid}`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  })
}

export async function editUser(
  uid: string,
  data: { name?: string; phone?: string; email?: string },
): Promise<void> {
  await apiFetch(`/api/admin/users/${uid}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

// ─── Businesses ──────────────────────────────────────────────────────────────

export async function fetchBusinesses(limit = 300): Promise<{ businesses: Business[]; total: number }> {
  return apiFetch(`/api/admin/businesses?limit=${limit}`)
}

export async function fetchBusiness(uid: string, businessId: string): Promise<{ business: Business }> {
  return apiFetch(`/api/admin/businesses/${uid}/${businessId}`)
}

export async function patchBusiness(uid: string, businessId: string, isActive: boolean): Promise<void> {
  await apiFetch(`/api/admin/businesses/${uid}/${businessId}`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  })
}

export async function editBusiness(
  uid: string,
  businessId: string,
  data: { businessName?: string; businessCategory?: string; placeOfBusiness?: string; plan?: string },
): Promise<void> {
  await apiFetch(`/api/admin/businesses/${uid}/${businessId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

// ─── Analytics ───────────────────────────────────────────────────────────────

export async function fetchAnalytics(): Promise<AnalyticsOverview> {
  return apiFetch('/api/admin/analytics')
}

// ─── Catalog ──────────────────────────────────────────────────────────────────

export async function fetchCatalog(businessType?: string): Promise<{
  categories: CatalogCategory[]
  products: CatalogProduct[]
  businessTypes: string[]
  total: number
}> {
  const qs = businessType ? `?businessType=${encodeURIComponent(businessType)}` : ''
  return apiFetch(`/api/admin/catalog${qs}`)
}

export async function postCatalogProduct(data: Record<string, unknown>): Promise<{ id: string }> {
  return apiFetch('/api/admin/catalog', { method: 'POST', body: JSON.stringify(data) })
}

// ─── Subscriptions ────────────────────────────────────────────────────────────

export async function fetchSubscriptions(): Promise<{ subscriptions: Subscription[]; total: number }> {
  return apiFetch('/api/admin/subscriptions')
}

// ─── Lifetime ─────────────────────────────────────────────────────────────────

export async function fetchLifetime(): Promise<{ lifetime: LifetimeSubscription[]; total: number }> {
  return apiFetch('/api/admin/lifetime')
}

// ─── Refunds ──────────────────────────────────────────────────────────────────

export async function fetchRefunds(): Promise<{ refunds: RefundRequest[] }> {
  return apiFetch('/api/admin/refunds')
}

export async function patchRefund(id: string, status: 'processing' | 'completed'): Promise<void> {
  await apiFetch(`/api/admin/refunds/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  })
}

// ─── Support ──────────────────────────────────────────────────────────────────

export async function fetchTickets(): Promise<{ tickets: SupportTicket[] }> {
  return apiFetch('/api/admin/support')
}

export async function patchTicket(
  id: string,
  update: { status?: SupportTicket['status']; assignedAdmin?: string },
): Promise<void> {
  await apiFetch(`/api/admin/support/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(update),
  })
}

// ─── Audit Log ────────────────────────────────────────────────────────────────

export async function fetchAudit(): Promise<{ entries: AuditEntry[] }> {
  return apiFetch('/api/admin/audit')
}

// ─── Feature Flags ────────────────────────────────────────────────────────────

export async function fetchFlags(): Promise<{ flags: FeatureFlag[] }> {
  return apiFetch('/api/admin/features')
}

export async function patchFlag(
  id: string,
  update: { enabled?: boolean; rolloutPercent?: number },
): Promise<void> {
  await apiFetch(`/api/admin/features/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(update),
  })
}

// ─── Platform Config ──────────────────────────────────────────────────────────

export async function fetchConfig(): Promise<PlatformConfig> {
  return apiFetch('/api/admin/config')
}

export async function saveConfig(config: PlatformConfig): Promise<void> {
  await apiFetch('/api/admin/config', {
    method: 'PATCH',
    body: JSON.stringify(config),
  })
}

// ─── System Health ────────────────────────────────────────────────────────────

export async function fetchSystemHealth(): Promise<{ services: ServiceHealth[]; updatedAt: string; firestoreLatencyMs: number }> {
  return apiFetch('/api/admin/system')
}

// ─── Catalog Submissions ──────────────────────────────────────────────────────

export async function fetchSubmissions(): Promise<{ submissions: CommunitySubmission[] }> {
  return apiFetch('/api/admin/catalog/submissions')
}

export async function patchSubmission(id: string, status: 'approved' | 'rejected'): Promise<void> {
  await apiFetch(`/api/admin/catalog/submissions/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  })
}

// ─── Catalog Product Edit / Delete ────────────────────────────────────────────

export async function patchCatalogProduct(id: string, data: Partial<CatalogProduct>): Promise<void> {
  await apiFetch(`/api/admin/catalog/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  })
}

export async function deleteCatalogProduct(id: string): Promise<void> {
  await apiFetch(`/api/admin/catalog/${id}`, { method: 'DELETE' })
}

// ─── Catalog Categories ───────────────────────────────────────────────────────

export async function postCatalogCategory(data: Record<string, unknown>): Promise<{ id: string }> {
  return apiFetch('/api/admin/catalog/categories', { method: 'POST', body: JSON.stringify(data) })
}

export async function patchCatalogCategory(id: string, data: Record<string, unknown>): Promise<void> {
  await apiFetch(`/api/admin/catalog/categories/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  })
}

export async function deleteCatalogCategory(id: string): Promise<void> {
  await apiFetch(`/api/admin/catalog/categories/${id}`, { method: 'DELETE' })
}

// ─── Plans ────────────────────────────────────────────────────────────────────

export async function fetchPlans(): Promise<{ plans: PlanDefinitions }> {
  return apiFetch('/api/admin/plans')
}

export async function patchPlan(tier: PlanTier, data: Partial<PlanDefinition>): Promise<void> {
  await apiFetch(`/api/admin/plans/${tier}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  })
}

export async function assignPlan(
  uid: string,
  businessId: string,
  tier: PlanTier,
  cycleMonths: number,
): Promise<{ tier: PlanTier; expiresAt: string | null }> {
  return apiFetch('/api/admin/plans/assign', {
    method: 'POST',
    body: JSON.stringify({ uid, businessId, tier, cycleMonths }),
  })
}

// ─── Lookups ──────────────────────────────────────────────────────────────────

export async function fetchLookups(): Promise<AppLookups> {
  return apiFetch('/api/admin/lookups')
}

export async function saveLookupBusinessTypes(items: AppLookups['businessTypes']): Promise<void> {
  await apiFetch('/api/admin/lookups?type=business_types', {
    method: 'PATCH',
    body: JSON.stringify({ items }),
  })
}

export async function saveLookupCities(items: AppLookups['cities']): Promise<void> {
  await apiFetch('/api/admin/lookups?type=cities', {
    method: 'PATCH',
    body: JSON.stringify({ items }),
  })
}

export async function saveLookupDistricts(items: AppLookups['districts']): Promise<void> {
  await apiFetch('/api/admin/lookups?type=districts', {
    method: 'PATCH',
    body: JSON.stringify({ items }),
  })
}

// ─── User Activity ────────────────────────────────────────────────────────────

export interface ActivityEntry {
  id: string
  action: string
  entityType?: string
  entityId?: string
  entityName?: string
  performedByName?: string
  amount?: number
  details?: string
  previousValue?: unknown
  newValue?: unknown
  businessId: string
  businessName: string
  timestamp: string
  source: 'business_log' | 'admin_log'
}

export async function fetchUserActivity(uid: string): Promise<{ entries: ActivityEntry[]; total: number }> {
  return apiFetch(`/api/admin/users/${uid}/activity`)
}

// ─── Create User + Business ───────────────────────────────────────────────────

export async function createUser(data: {
  name: string
  phone: string
  email?: string
  businessName?: string
  businessCategory?: string
  placeOfBusiness?: string
}): Promise<{ uid: string; businessId: string | null }> {
  return apiFetch('/api/admin/users', { method: 'POST', body: JSON.stringify(data) })
}

// ─── Business Notes ───────────────────────────────────────────────────────────

export async function postBusinessNote(
  uid: string,
  businessId: string,
  content: string,
  author: string,
): Promise<{ id: string }> {
  return apiFetch(`/api/admin/businesses/${uid}/${businessId}`, {
    method: 'POST',
    body: JSON.stringify({ content, author }),
  })
}
