import type { AdminUser, Business, AnalyticsOverview, CatalogProduct, CatalogCategory } from '@/types'

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
