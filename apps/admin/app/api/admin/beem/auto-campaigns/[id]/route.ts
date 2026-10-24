import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore, FieldValue } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import {
  AUTO_CAMPAIGNS_CACHE_KEY,
  AUTO_CAMPAIGNS_COLLECTION,
  parseAutoCampaignInput,
} from '@/lib/auto-campaigns'
import type { BeemAutoCampaignInput } from '@/types'

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { id } = await params
    const ref = adminFirestore.collection(AUTO_CAMPAIGNS_COLLECTION).doc(id)
    const snap = await ref.get()
    if (!snap.exists) return NextResponse.json({ error: 'Auto campaign not found' }, { status: 404 })

    const parsed = parseAutoCampaignInput((await request.json()) as Partial<BeemAutoCampaignInput>, true)
    if ('error' in parsed) return NextResponse.json({ error: parsed.error }, { status: 400 })

    const update: Record<string, unknown> = { ...parsed.data, updatedAt: FieldValue.serverTimestamp() }
    if ('senderId' in parsed.data) update.senderId = parsed.data.senderId ?? null
    await ref.update(update)

    await writeAudit({
      action: 'update_sms_auto_campaign',
      resourceType: 'sms_campaign',
      resourceId: id,
      resourceName: (snap.data()?.name as string) || 'Auto campaign',
      isDestructive: false,
      before: snap.data(),
      after: parsed.data,
    })
    invalidateCache(AUTO_CAMPAIGNS_CACHE_KEY)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('[PATCH /api/admin/beem/auto-campaigns/[id]]', err)
    return NextResponse.json({ error: 'Failed to update auto campaign' }, { status: 500 })
  }
}

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { id } = await params
    const ref = adminFirestore.collection(AUTO_CAMPAIGNS_COLLECTION).doc(id)
    const snap = await ref.get()
    if (!snap.exists) return NextResponse.json({ error: 'Auto campaign not found' }, { status: 404 })

    await ref.delete()
    await writeAudit({
      action: 'delete_sms_auto_campaign',
      resourceType: 'sms_campaign',
      resourceId: id,
      resourceName: (snap.data()?.name as string) || 'Auto campaign',
      isDestructive: true,
      before: snap.data(),
    })
    invalidateCache(AUTO_CAMPAIGNS_CACHE_KEY)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('[DELETE /api/admin/beem/auto-campaigns/[id]]', err)
    return NextResponse.json({ error: 'Failed to delete auto campaign' }, { status: 500 })
  }
}
