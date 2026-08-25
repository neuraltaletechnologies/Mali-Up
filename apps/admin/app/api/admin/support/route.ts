import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'
import type { SupportTicket } from '@/types'

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
    const tickets = await withCache(CACHE_KEYS.support, 20_000, fetchTickets)
    return NextResponse.json({ tickets })
  } catch (err) {
    console.error('[GET /api/admin/support]', err)
    return NextResponse.json({ error: 'Failed to fetch tickets' }, { status: 500 })
  }
}

async function fetchTickets(): Promise<SupportTicket[]> {
  const snap = await adminFirestore
    .collection('platform_tickets')
    .orderBy('createdAt', 'desc')
    .limit(200)
    .get()

  return snap.docs.map((doc) => {
    const d = doc.data()
    return {
      id:            doc.id,
      businessId:    (d.businessId as string)    || '',
      businessName:  (d.businessName as string)  || 'Unknown Business',
      ownerName:     (d.ownerName as string)     || '',
      priority:      (d.priority as SupportTicket['priority']) || 'normal',
      status:        (d.status as SupportTicket['status'])     || 'open',
      issueType:     (d.issueType as string)     || '',
      assignedAdmin: (d.assignedAdmin as string | undefined),
      createdAt:     toIso(d.createdAt),
      updatedAt:     toIso(d.updatedAt),
    }
  })
}
