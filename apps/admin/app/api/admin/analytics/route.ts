import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'

// Plan monthly fees in TZS
const PLAN_FEES: Record<string, number> = {
  starter: 0,
  trial: 0,
  growth: 49_000,
  business: 120_000,
  enterprise: 350_000,
  lifetime: 0,
}

const PLAN_COLORS: Record<string, string> = {
  starter: '#94A3B8',
  trial: '#94A3B8',
  growth: '#1A6E8A',
  business: '#0D1B3E',
  enterprise: '#D97706',
  lifetime: '#16244D',
}

function normalisePlan(raw: string | undefined | null): string {
  const p = (raw ?? '').toLowerCase()
  if (p === 'trial') return 'starter'
  if (['starter', 'growth', 'business', 'enterprise', 'lifetime'].includes(p)) return p
  return 'starter'
}

function mrrForPlan(plan: string): number {
  return PLAN_FEES[plan] ?? 0
}

/** Returns the last N months as { label, endMs } pairs, oldest first. */
function lastNMonths(n: number): { label: string; endMs: number }[] {
  const result: { label: string; endMs: number }[] = []
  const now = new Date()
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i + 1, 0) // last day of month
    const label = d.toLocaleString('en-GB', { month: 'short', year: '2-digit' })
    result.push({ label, endMs: d.getTime() })
  }
  return result
}

function toMs(value: unknown): number {
  if (!value) return 0
  if (typeof value === 'string') return new Date(value).getTime()
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return s * 1000
  }
  return 0
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = await withCache('analytics', 2 * 60_000, computeAnalytics)
    return NextResponse.json(body)
  } catch (err) {
    console.error('[GET /api/admin/analytics]', err)
    return NextResponse.json({ error: 'Failed to fetch analytics' }, { status: 500 })
  }
}

async function computeAnalytics() {
  // ── Fetch in parallel ──────────────────────────────────────────────────
  const [userCountSnap, bizSnap, recentUsersSnap] = await Promise.all([
    adminFirestore.collection('users').count().get(),
    adminFirestore
      .collectionGroup('businesses')
      .get(),
    adminFirestore
      .collection('users')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get(),
  ])

  const totalUsers = userCountSnap.data().count

  // ── Process businesses ─────────────────────────────────────────────────
  type BizRow = { plan: string; status: string; createdAtMs: number }
  const bizRows: BizRow[] = bizSnap.docs.map((doc) => {
    const d = doc.data()
    return {
      plan: normalisePlan(d.plan as string),
      status: d.isActive === false ? 'inactive' : (d.subscriptionStatus as string) ?? 'active',
      createdAtMs: toMs(d.createdAt),
    }
  })

  const totalBusinesses = bizRows.length
  const activeBusinesses = bizRows.filter((b) => b.status !== 'inactive' && b.status !== 'suspended').length

  // ── Current MRR ────────────────────────────────────────────────────────
  const mrr = bizRows.reduce((sum, b) => sum + mrrForPlan(b.plan), 0)

  // ── Plan distribution ──────────────────────────────────────────────────
  const planCounts: Record<string, number> = {}
  for (const b of bizRows) {
    planCounts[b.plan] = (planCounts[b.plan] ?? 0) + 1
  }
  const planOrder = ['starter', 'growth', 'business', 'enterprise', 'lifetime']
  const planDistribution = planOrder
    .filter((p) => (planCounts[p] ?? 0) > 0)
    .map((p) => ({
      name: p.charAt(0).toUpperCase() + p.slice(1),
      value: planCounts[p] ?? 0,
      color: PLAN_COLORS[p],
    }))

  // ── MRR trend (last 12 months, cumulative from business creation) ──────
  const months = lastNMonths(12)
  const mrrTrend = months.map(({ label, endMs }) => {
    const value = bizRows
      .filter((b) => b.createdAtMs > 0 && b.createdAtMs <= endMs)
      .reduce((sum, b) => sum + mrrForPlan(b.plan), 0)
    return { month: label, value }
  })

  // ── Recent signups ─────────────────────────────────────────────────────
  const recentSignups = recentUsersSnap.docs.map((doc) => {
    const d = doc.data()
    const businesses = Array.isArray(d.businesses) ? d.businesses : []
    return {
      uid: doc.id,
      name: (d.displayName as string) || (d.name as string) || 'Unknown',
      phone: d.phone ? `+255${d.phone}` : '',
      businessName: (businesses[0]?.name as string) ?? (d.businessName as string) ?? '',
      createdAt: toMs(d.createdAt)
        ? new Date(toMs(d.createdAt)).toISOString()
        : new Date().toISOString(),
    }
  })

  return {
    totalUsers,
    totalBusinesses,
    activeBusinesses,
    mrr,
    planDistribution,
    mrrTrend,
    recentSignups,
  }
}
