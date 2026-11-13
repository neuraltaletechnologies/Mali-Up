import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'

const CACHE_KEY = 'beem-sms-campaigns'

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { id } = await params
    const doc = await adminFirestore.collection('beem_sms_campaigns').doc(id).get()
    if (!doc.exists) {
      return NextResponse.json({ error: 'Campaign not found' }, { status: 404 })
    }

    return NextResponse.json({ id: doc.id, ...doc.data() })
  } catch (err) {
    console.error('[GET /api/admin/beem/campaigns/[id]]', err)
    return NextResponse.json({ error: 'Failed to fetch campaign' }, { status: 500 })
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
    const ref = adminFirestore.collection('beem_sms_campaigns').doc(id)
    const snap = await ref.get()
    if (!snap.exists) {
      return NextResponse.json({ error: 'Campaign not found' }, { status: 404 })
    }

    const before = snap.data()!
    // Drop the recipients/{phone} subcollection 500 docs per commit. Not
    // recursiveDelete: it makes two requests per recipient doc, which runs a
    // big campaign into the Worker's per-request subrequest cap.
    const recSnap = await ref.collection('recipients').limit(2000).get()
    for (let i = 0; i < recSnap.docs.length; i += 500) {
      const batch = adminFirestore.batch()
      for (const doc of recSnap.docs.slice(i, i + 500)) batch.delete(doc.ref)
      await batch.commit()
    }
    await ref.delete()

    await writeAudit({
      action: 'delete_sms_campaign',
      resourceType: 'sms_campaign',
      resourceId: id,
      resourceName: (before.name as string) || 'SMS Campaign',
      isDestructive: true,
      before,
    })

    invalidateCache(CACHE_KEY)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('[DELETE /api/admin/beem/campaigns/[id]]', err)
    return NextResponse.json({ error: 'Failed to delete campaign' }, { status: 500 })
  }
}
