import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import type { PlanRequest } from '@/types'

function toIso(value: unknown): string {
  if (!value) return ''
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return ''
}

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const statusFilter = searchParams.get('status') // optional: pending|approved|rejected

  try {
    // Fetch recent requests, filter in memory to avoid composite index requirement
    const snap = await adminFirestore
      .collection('plan_requests')
      .orderBy('createdAt', 'desc')
      .limit(500)
      .get()

    const requests: PlanRequest[] = snap.docs
      // The mobile app's manual "payment confirmation" claim flow was
      // retired once ClickPesa started activating plans automatically —
      // any payment_claim docs left over from before that point are
      // historical only and no longer surfaced here. Enterprise inquiries
      // are unrelated to ClickPesa and still go through manual review.
      .filter((doc) => (doc.data().type as string | undefined) !== 'payment_claim')
      .map((doc) => {
        const d = doc.data()
        return {
          id:            doc.id,
          uid:           (d.uid as string) || '',
          name:          (d.name as string) || '',
          phone:         (d.phone as string) || '',
          businessId:    (d.businessId as string) || '',
          businessName:  (d.businessName as string) || '',
          requestedTier: (d.requestedTier as PlanRequest['requestedTier']) || 'growth',
          type:          'enterprise_inquiry' as const,
          note:          (d.note as string) || '',
          status:        (d.status as PlanRequest['status']) || 'pending',
          activated:     Boolean(d.activated),
          adminNotes:    (d.adminNotes as string) || '',
          createdAt:     toIso(d.createdAt),
          resolvedAt:    toIso(d.resolvedAt),
        }
      })

    const filtered = statusFilter
      ? requests.filter((r) => r.status === statusFilter)
      : requests

    return NextResponse.json({ requests: filtered })
  } catch (err) {
    console.error('[GET /api/admin/plan-requests]', err)
    return NextResponse.json({ error: 'Failed to fetch plan requests' }, { status: 500 })
  }
}
