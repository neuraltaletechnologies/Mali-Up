import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import type { RefundRequest } from '@/types'

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
    const snap = await adminFirestore
      .collection('platform_refunds')
      .orderBy('requestedAt', 'desc')
      .get()

    const refunds: RefundRequest[] = snap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:           doc.id,
        businessId:   (d.businessId as string)   || '',
        businessName: (d.businessName as string) || 'Unknown Business',
        tier:         (d.tier as 'growth' | 'business') || 'growth',
        principal:    (d.principal as number)    || 0,
        monthsHeld:   (d.monthsHeld as number)   || 0,
        monthlyFee:   (d.monthlyFee as number)   || 0,
        requestedAt:  toIso(d.requestedAt),
        status:       (d.status as RefundRequest['status']) || 'requested',
        processedAt:  d.processedAt ? toIso(d.processedAt) : undefined,
        completedAt:  d.completedAt ? toIso(d.completedAt) : undefined,
      }
    })

    return NextResponse.json({ refunds })
  } catch (err) {
    console.error('[GET /api/admin/refunds]', err)
    return NextResponse.json({ error: 'Failed to fetch refunds' }, { status: 500 })
  }
}
