import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { withCache, invalidateCache } from '@/lib/api-cache'
import {
  AUTO_CAMPAIGNS_CACHE_KEY,
  AUTO_CAMPAIGNS_COLLECTION,
  mapAutoCampaign,
  parseAutoCampaignInput,
} from '@/lib/auto-campaigns'
import type { BeemAutoCampaignInput } from '@/types'

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const data = await withCache(AUTO_CAMPAIGNS_CACHE_KEY, 10_000, async () => {
      const snap = await adminFirestore.collection(AUTO_CAMPAIGNS_COLLECTION).limit(100).get()
      const rules = snap.docs
        .map((doc) => mapAutoCampaign(doc.id, doc.data()))
        .sort((a, b) => a.month - b.month || a.day - b.day)
      return { rules }
    })
    return NextResponse.json(data)
  } catch (err) {
    console.error('[GET /api/admin/beem/auto-campaigns]', err)
    return NextResponse.json({ error: 'Failed to fetch auto campaigns' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const parsed = parseAutoCampaignInput((await request.json()) as Partial<BeemAutoCampaignInput>, false)
    if ('error' in parsed) return NextResponse.json({ error: parsed.error }, { status: 400 })

    const ref = adminFirestore.collection(AUTO_CAMPAIGNS_COLLECTION).doc()
    await ref.set({
      ...parsed.data,
      senderId: parsed.data.senderId ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    })

    await writeAudit({
      action: 'create_sms_auto_campaign',
      resourceType: 'sms_campaign',
      resourceId: ref.id,
      resourceName: parsed.data.name ?? 'Auto campaign',
      isDestructive: false,
      after: parsed.data,
    })
    invalidateCache(AUTO_CAMPAIGNS_CACHE_KEY)

    return NextResponse.json({ id: ref.id }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/admin/beem/auto-campaigns]', err)
    return NextResponse.json({ error: 'Failed to create auto campaign' }, { status: 500 })
  }
}
