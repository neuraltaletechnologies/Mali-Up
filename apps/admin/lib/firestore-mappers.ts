import type { AdminUser, Business, PlanTier, BusinessStatus, UserStatus } from '@/types'

// ─── helpers ─────────────────────────────────────────────────────────────────

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  // Firestore Timestamp-like: { _seconds, _nanoseconds } or { seconds, nanoseconds }
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds
      ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

function normalisePlan(raw: string | undefined | null): PlanTier {
  switch ((raw ?? '').toLowerCase()) {
    case 'growth':     return 'growth'
    case 'business':   return 'business'
    case 'enterprise': return 'enterprise'
    case 'lifetime':   return 'lifetime'
    default:           return 'starter'   // 'trial', 'starter', or unknown
  }
}

function normaliseUserStatus(data: Record<string, unknown>): UserStatus {
  if (data.isActive === false) return 'suspended'
  if (data.profileComplete === false) return 'pending'
  return 'active'
}

function normaliseBusinessStatus(data: Record<string, unknown>): BusinessStatus {
  if (data.isActive === false) return 'suspended'
  const sub = (data.subscriptionStatus as string | undefined)?.toLowerCase()
  if (sub === 'cancelled') return 'inactive'
  if (sub === 'past_due')  return 'suspended'
  return 'active'
}

// ─── User ─────────────────────────────────────────────────────────────────────

export function mapUser(uid: string, data: Record<string, unknown>): AdminUser {
  const businesses = Array.isArray(data.businesses) ? data.businesses : []
  return {
    id:            uid,
    name:          (data.displayName as string) || (data.name as string) || 'Unknown',
    phone:         (data.phone as string) ? `+255${data.phone}` : '',
    email:         (data.email as string) || undefined,
    status:        normaliseUserStatus(data),
    businessCount: businesses.length,
    lastLogin:     toIso(data.lastLoginAt),
    joinedAt:      toIso(data.createdAt),
  }
}

// ─── Business ─────────────────────────────────────────────────────────────────

export function mapBusiness(
  uid: string,
  businessId: string,
  data: Record<string, unknown>,
  staffCount = 0,
): Business {
  return {
    id:           businessId,
    name:         (data.businessName as string) || 'Unnamed Business',
    ownerId:      (data.ownerUid as string) || uid,
    ownerName:    (data.ownerName as string) || '',
    ownerPhone:   (data.ownerPhone as string)
                    ? `+255${data.ownerPhone}`
                    : '',
    plan:         normalisePlan(data.plan as string),
    status:       normaliseBusinessStatus(data),
    staffCount,
    lastActive:   toIso(data.updatedAt),
    createdAt:    toIso(data.createdAt),
    mrr:          mrrForPlan(normalisePlan(data.plan as string)),
    industry:     (data.businessType as string) || (data.businessCategory as string) || 'Other',
    location:     (data.placeOfBusiness as string) || undefined,
  }
}

/** Monthly fee in TZS based on plan — matches platform config. */
function mrrForPlan(plan: PlanTier): number {
  switch (plan) {
    case 'growth':     return 49_000
    case 'business':   return 120_000
    case 'enterprise': return 350_000
    case 'lifetime':   return 0
    default:           return 0
  }
}
