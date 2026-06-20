import type {
  AdminUser, Business, AnalyticsOverview, CatalogProduct, CatalogCategory,
  Subscription, LifetimeSubscription, RefundRequest, SupportTicket, AuditEntry,
  ServiceHealth, FeatureFlag, CommunitySubmission, PlatformConfig,
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

// ─── Analytics ───────────────────────────────────────────────────────────────

export async function fetchAnalytics(): Promise<AnalyticsOverview> {
  return apiFetch('/api/admin/analytics')
}

// ─── Catalog ──────────────────────────────────────────────────────────────────

export async function fetchCatalog(businessTypeId?: string): Promise<{
  categories: CatalogCategory[]
  products: CatalogProduct[]
  businessTypeIds: string[]
  total: number
}> {
  const qs = businessTypeId ? `?businessTypeId=${encodeURIComponent(businessTypeId)}` : ''
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
