import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { invalidateCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'

type Params = { id: string }

export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = (await request.json()) as { status: 'processing' | 'completed' }
    if (!['processing', 'completed'].includes(body.status)) {
      return NextResponse.json({ error: 'status must be "processing" or "completed"' }, { status: 400 })
    }

    const ref = adminFirestore.collection('platform_refunds').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Refund not found' }, { status: 404 })

    const before = doc.data()!
    const update: Record<string, unknown> = { status: body.status, updatedAt: new Date() }
    if (body.status === 'processing') update.processedAt = new Date()
    if (body.status === 'completed')  update.completedAt = new Date()

    await ref.update(update)
    invalidateCache(CACHE_KEYS.refunds)

    await writeAudit({
      action: 'update_refund',
      resourceType: 'refund',
      resourceId: id,
      resourceName: (before.businessName as string) || id,
      isDestructive: false,
      before: { status: before.status },
      after:  { status: body.status },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/refunds/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update refund' }, { status: 500 })
  }
}
