import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import type { LifetimeSubscription } from '@/types'

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const lifetime = await withCache('lifetime', 60_000, fetchLifetime)
    return NextResponse.json({ lifetime, total: lifetime.length })
  } catch (err) {
    console.error('[GET /api/admin/lifetime]', err)
    return NextResponse.json({ error: 'Failed to fetch lifetime subscriptions' }, { status: 500 })
  }
}

// No admin write route touches platform_lifetime today — those docs are
// written outside this app — so a TTL is all that's needed, no invalidation.
async function fetchLifetime(): Promise<LifetimeSubscription[]> {
  const snap = await adminFirestore
    .collection('platform_lifetime')
    .orderBy('activatedAt', 'desc')
    .get()

  return snap.docs.map((doc) => {
    const d = doc.data()
    return {
      id:                doc.id,
      businessId:        (d.businessId as string)       || '',
      businessName:      (d.businessName as string)     || 'Unknown Business',
      ownerName:         (d.ownerName as string)        || '',
      tier:              (d.tier as 'growth' | 'business') || 'growth',
      principal:         (d.principal as number)        || 0,
      activatedAt:       toIso(d.activatedAt),
      monthsActive:      (d.monthsActive as number)     || 0,
      uttAMISBalance:    (d.uttAMISBalance as number)   || 0,
      thisMonthReturn:   (d.thisMonthReturn as number)  || 0,
      status:            (d.status as LifetimeSubscription['status']) || 'active',
      uttAMISReference:  (d.uttAMISReference as string | undefined),
      monthlyFee:        (d.monthlyFee as number)       || 0,
    }
  })
}
