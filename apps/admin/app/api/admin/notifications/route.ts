import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import type { AdminNotification } from '@/types'

function toIso(value: unknown): string {
  if (!value) return ''
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return ''
}

// Aggregates every request/submission type that needs admin action into one
// feed for the topbar bell. Each source collection already has its own page;
// this route only surfaces "status is still pending" items from each,
// filtering in memory (like the individual routes) to avoid composite
// Firestore indexes.
export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { notifications, count } = await withCache('notifications', 10_000, fetchNotifications)
    return NextResponse.json({ notifications, count })
  } catch (err) {
    console.error('[GET /api/admin/notifications]', err)
    return NextResponse.json({ error: 'Failed to fetch notifications' }, { status: 500 })
  }
}

// The topbar bell polls this often — 4 collection scans per call otherwise —
// and each source has its own page for anything that needs to be fresh to
// the second, so a short TTL (not manual invalidation from every one of
// those pages' write routes) is the right trade here.
async function fetchNotifications(): Promise<{ notifications: AdminNotification[]; count: number }> {
  const [planRequestsSnap, refundsSnap, submissionsSnap, ticketsSnap] = await Promise.all([
      adminFirestore.collection('plan_requests').orderBy('createdAt', 'desc').limit(50).get(),
      adminFirestore.collection('platform_refunds').orderBy('requestedAt', 'desc').limit(50).get(),
      adminFirestore.collection('catalog_community_submissions').orderBy('lastSeenAt', 'desc').limit(50).get(),
      adminFirestore.collection('platform_tickets').orderBy('createdAt', 'desc').limit(50).get(),
    ])

    const notifications: AdminNotification[] = []

    for (const doc of planRequestsSnap.docs) {
      const d = doc.data()
      if (((d.status as string) || 'pending') !== 'pending') continue
      const kind = d.type === 'enterprise_inquiry' ? 'Enterprise inquiry' : 'Payment claim'
      notifications.push({
        id:        `plan_request:${doc.id}`,
        source:    'plan_request',
        title:     `${kind} — ${(d.businessName as string) || (d.name as string) || 'Unknown business'}`,
        subtitle:  `Requesting ${(d.requestedTier as string) || 'a'} plan`,
        createdAt: toIso(d.createdAt),
        href:      '/admin/plan-requests',
      })
    }

    for (const doc of refundsSnap.docs) {
      const d = doc.data()
      if (((d.status as string) || 'requested') !== 'requested') continue
      notifications.push({
        id:        `refund:${doc.id}`,
        source:    'refund',
        title:     `Refund request — ${(d.businessName as string) || 'Unknown business'}`,
        subtitle:  `${(d.tier as string) || 'Plan'} · ${(d.monthsHeld as number) || 0} months held`,
        createdAt: toIso(d.requestedAt),
        href:      '/admin/plan-requests?tab=refunds',
      })
    }

    for (const doc of submissionsSnap.docs) {
      const d = doc.data()
      if (((d.status as string) || 'pending') !== 'pending') continue
      notifications.push({
        id:        `submission:${doc.id}`,
        source:    'submission',
        title:     `Catalog submission — ${(d.productName as string) || 'Unnamed item'}`,
        subtitle:  `Seen ${(d.submissionCount as number) || 1}x · ${(d.businessTypeName as string) || 'multiple business types'}`,
        createdAt: toIso(d.lastSeenAt ?? d.firstSeenAt),
        href:      '/admin/catalog/submissions',
      })
    }

    for (const doc of ticketsSnap.docs) {
      const d = doc.data()
      if (((d.status as string) || 'open') !== 'open') continue
      notifications.push({
        id:        `ticket:${doc.id}`,
        source:    'ticket',
        title:     `Support ticket — ${(d.businessName as string) || 'Unknown business'}`,
        subtitle:  (d.issueType as string) || 'General issue',
        createdAt: toIso(d.createdAt),
        href:      '/admin/support',
      })
    }

    notifications.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''))

    return { notifications: notifications.slice(0, 50), count: notifications.length }
}
