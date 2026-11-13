import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { auth } from '@/lib/auth'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import { calculateSmsParts } from '@/lib/beem'

const CACHE_KEY = 'beem-sms-campaigns'

/**
 * "Resend to not delivered": queues a new campaign with the same message for
 * every recipient of this one that Beem rejected (`status: failed`) or that
 * Beem reported UNDELIVERED. Numbers still PENDING are left out, since they
 * may yet arrive and resending would text them twice.
 *
 * The new campaign is a plain `custom_numbers` campaign with status `queued`,
 * so it goes through the normal sender (onSmsCampaignCreated), and names and
 * business names are resolved again from users by phone.
 */
export async function POST(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { id } = await params
    const sourceRef = adminFirestore.collection('beem_sms_campaigns').doc(id)
    const source = await sourceRef.get()
    if (!source.exists) {
      return NextResponse.json({ error: 'Campaign not found' }, { status: 404 })
    }
    const c = source.data()!

    if (c.status === 'queued' || c.status === 'scheduled' || c.status === 'sending') {
      return NextResponse.json({ error: 'This campaign has not finished sending yet' }, { status: 409 })
    }
    if (c.recipientsTracked !== true) {
      return NextResponse.json(
        { error: 'This campaign was sent before per-recipient tracking, so there is no record of who missed it' },
        { status: 400 }
      )
    }

    const recSnap = await sourceRef.collection('recipients').limit(2000).get()
    const phones = recSnap.docs
      .map((d) => d.data())
      .filter((r) => r.status === 'failed' || r.dlrStatus === 'UNDELIVERED')
      .map((r) => String(r.phone))
      .filter(Boolean)

    if (phones.length === 0) {
      return NextResponse.json({ error: 'Every recipient was delivered or is still pending — nothing to resend' }, { status: 400 })
    }

    const session = await auth()
    const message = String(c.message || '')
    const parts = calculateSmsParts(message).parts
    const name = `${String(c.name || 'SMS Campaign')} (resend)`

    const newRef = adminFirestore.collection('beem_sms_campaigns').doc()
    await newRef.set({
      name,
      campaignType: c.campaignType || 'custom',
      senderId: c.senderId || 'Mali Up',
      message,
      messageSw: c.messageSw || null,
      audience: { kind: 'custom_numbers', customNumbers: phones },
      status: 'queued',
      targetCount: phones.length,
      sentCount: 0,
      failedCount: 0,
      smsPartsCount: parts,
      estimatedCredits: phones.length * parts,
      scheduledAt: null,
      scheduledAtMs: null,
      sentAt: null,
      createdAt: FieldValue.serverTimestamp(),
      createdByAdminId: session?.user?.id ?? 'unknown',
      createdByAdminName: session?.user?.name ?? session?.user?.email ?? 'Admin',
      resendOf: id,
    })
    await sourceRef.update({ resendCampaignIds: FieldValue.arrayUnion(newRef.id) })

    await writeAudit({
      action: 'resend_sms_campaign',
      resourceType: 'sms_campaign',
      resourceId: newRef.id,
      resourceName: name,
      isDestructive: false,
      after: { resendOf: id, targetCount: phones.length },
    })

    invalidateCache(CACHE_KEY)

    return NextResponse.json({ id: newRef.id, recipientCount: phones.length }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/admin/beem/campaigns/[id]/resend]', err)
    return NextResponse.json({ error: 'Failed to queue resend' }, { status: 500 })
  }
}
