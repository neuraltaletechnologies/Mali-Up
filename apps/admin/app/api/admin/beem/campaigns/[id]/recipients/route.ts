import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import type { SmsCampaignRecipient, SmsDeliveryStatus } from '@/types'

// Matches the sender's audience cap (MAX_DOCS in functions/src/sms_campaigns.ts).
const MAX_RECIPIENTS = 2000

function toIso(value: unknown): string | undefined {
  if (!value) return undefined
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return undefined
}

/**
 * Per-recipient send + delivery results for one campaign, written by the
 * sender (functions/src/sms_campaigns.ts). Only fetched when an admin opens
 * the campaign drawer, never polled: one read per recipient.
 */
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { id } = await params
    const snap = await adminFirestore
      .collection('beem_sms_campaigns')
      .doc(id)
      .collection('recipients')
      .limit(MAX_RECIPIENTS)
      .get()

    const recipients: SmsCampaignRecipient[] = snap.docs.map((doc) => {
      const d = doc.data()
      return {
        phone: (d.phone as string) || doc.id,
        name: (d.name as string) || '',
        businessName: (d.businessName as string) || '',
        status: d.status === 'accepted' ? 'accepted' : 'failed',
        reason: (d.reason as string) || null,
        dlrStatus: (d.dlrStatus as SmsDeliveryStatus) || null,
        sentAt: toIso(d.sentAt),
      }
    })

    return NextResponse.json({ recipients })
  } catch (err) {
    console.error('[GET /api/admin/beem/campaigns/[id]/recipients]', err)
    return NextResponse.json({ error: 'Failed to fetch campaign recipients' }, { status: 500 })
  }
}
