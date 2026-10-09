import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { auth } from '@/lib/auth'
import { writeAudit } from '@/lib/write-audit'
import { withCache, invalidateCache } from '@/lib/api-cache'
import { calculateSmsParts, getBeemCredentials, sendBeemSmsBatch } from '@/lib/beem'
import { resolveSmsRecipients } from '@/lib/sms-recipients'
import type { BeemSmsCampaign, SmsCampaignAudience, SmsCampaignType } from '@/types'

const CACHE_KEY = 'beem-sms-campaigns'

function toIso(value: unknown): string | undefined {
  if (!value) return undefined
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return undefined
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const data = await withCache(CACHE_KEY, 10_000, fetchCampaigns)
    return NextResponse.json(data)
  } catch (err) {
    console.error('[GET /api/admin/beem/campaigns]', err)
    return NextResponse.json({ error: 'Failed to fetch Beem SMS campaigns' }, { status: 500 })
  }
}

async function fetchCampaigns() {
  const snap = await adminFirestore
    .collection('beem_sms_campaigns')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get()

  const campaigns: BeemSmsCampaign[] = snap.docs.map((doc) => {
    const d = doc.data()
    return {
      id: doc.id,
      name: (d.name as string) || 'Untitled Campaign',
      campaignType: (d.campaignType as SmsCampaignType) || 'custom',
      senderId: (d.senderId as string) || 'INFO',
      message: (d.message as string) || '',
      messageSw: (d.messageSw as string) || undefined,
      audience: (d.audience as SmsCampaignAudience) || { kind: 'all' },
      status: (d.status as BeemSmsCampaign['status']) || 'draft',
      targetCount: Number(d.targetCount) || 0,
      sentCount: Number(d.sentCount) || 0,
      failedCount: Number(d.failedCount) || 0,
      smsPartsCount: Number(d.smsPartsCount) || 1,
      estimatedCredits: Number(d.estimatedCredits) || 0,
      scheduledAt: toIso(d.scheduledAt),
      sentAt: toIso(d.sentAt),
      createdAt: toIso(d.createdAt) || new Date().toISOString(),
      createdByAdminId: (d.createdByAdminId as string) || '',
      createdByAdminName: (d.createdByAdminName as string) || 'Admin',
      failedRecipients: (d.failedRecipients as { phone: string; reason: string }[]) || undefined,
    }
  })

  return { campaigns, total: campaigns.length }
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      name: string
      campaignType: SmsCampaignType
      senderId?: string
      message: string
      messageSw?: string
      audience: SmsCampaignAudience
      isScheduled?: boolean
      scheduledAt?: string // ISO string or YYYY-MM-DD HH:mm:ss
    }

    const name = body.name?.trim() || ''
    const message = body.message?.trim() || ''
    const messageSw = body.messageSw?.trim() || ''
    const campaignType = body.campaignType || 'custom'
    const audience = body.audience

    if (!name) return NextResponse.json({ error: 'Campaign name is required' }, { status: 400 })
    if (!message) return NextResponse.json({ error: 'Message content is required' }, { status: 400 })
    if (!audience || !audience.kind) {
      return NextResponse.json({ error: 'Audience target is required' }, { status: 400 })
    }

    const creds = await getBeemCredentials()
    const senderId = body.senderId?.trim() || creds.senderId || 'INFO'

    const session = await auth()
    const adminId = session?.user?.id ?? 'unknown'
    const adminName = session?.user?.name ?? session?.user?.email ?? 'Admin'

    // Resolve recipients
    const recipients = await resolveSmsRecipients(audience)
    if (recipients.length === 0) {
      return NextResponse.json(
        { error: 'No recipients match the selected audience criteria' },
        { status: 400 }
      )
    }

    const partsInfo = calculateSmsParts(message)
    const estimatedCredits = recipients.length * partsInfo.parts

    const campaignRef = adminFirestore.collection('beem_sms_campaigns').doc()
    const now = FieldValue.serverTimestamp()

    const isScheduled = Boolean(body.isScheduled && body.scheduledAt)

    // Initial save
    await campaignRef.set({
      name,
      campaignType,
      senderId,
      message,
      messageSw: messageSw || null,
      audience,
      status: isScheduled ? 'scheduled' : 'sending',
      targetCount: recipients.length,
      sentCount: 0,
      failedCount: 0,
      smsPartsCount: partsInfo.parts,
      estimatedCredits,
      scheduledAt: isScheduled ? body.scheduledAt : null,
      sentAt: null,
      createdAt: now,
      createdByAdminId: adminId,
      createdByAdminName: adminName,
    })

    // If not scheduled, dispatch immediately
    if (!isScheduled) {
      try {
        const dispatchResult = await sendBeemSmsBatch({
          recipients,
          message,
          senderId,
        })

        const finalStatus =
          dispatchResult.totalSent === recipients.length
            ? 'sent'
            : dispatchResult.totalSent > 0
            ? 'partially_failed'
            : 'failed'

        await campaignRef.update({
          status: finalStatus,
          sentCount: dispatchResult.totalSent,
          failedCount: dispatchResult.totalFailed,
          sentAt: FieldValue.serverTimestamp(),
          failedRecipients: dispatchResult.failedNumbers.slice(0, 50),
        })
      } catch (sendErr) {
        console.error('[Beem Campaigns] Send error:', sendErr)
        await campaignRef.update({
          status: 'failed',
          failedCount: recipients.length,
          sentAt: FieldValue.serverTimestamp(),
        })
      }
    }

    await writeAudit({
      action: isScheduled ? 'schedule_sms_campaign' : 'send_sms_campaign',
      resourceType: 'sms_campaign',
      resourceId: campaignRef.id,
      resourceName: name,
      isDestructive: false,
      after: {
        name,
        campaignType,
        targetCount: recipients.length,
        isScheduled,
        scheduledAt: body.scheduledAt,
      },
    })

    invalidateCache(CACHE_KEY)

    return NextResponse.json({ id: campaignRef.id, recipientCount: recipients.length }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/admin/beem/campaigns]', err)
    return NextResponse.json({ error: 'Failed to create SMS campaign' }, { status: 500 })
  }
}
