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
    const body = (await request.json()) as {
      status?: 'open' | 'in_progress' | 'resolved' | 'closed'
      assignedAdmin?: string
    }

    const ref = adminFirestore.collection('platform_tickets').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Ticket not found' }, { status: 404 })

    const before = doc.data()!
    const update: Record<string, unknown> = { updatedAt: new Date() }
    if (body.status)        update.status        = body.status
    if (body.assignedAdmin) update.assignedAdmin = body.assignedAdmin

    await ref.update(update)
    invalidateCache(CACHE_KEYS.support)

    await writeAudit({
      action: 'update_ticket',
      resourceType: 'ticket',
      resourceId: id,
      resourceName: (before.businessName as string) || id,
      isDestructive: false,
      before: { status: before.status, assignedAdmin: before.assignedAdmin },
      after:  { status: body.status ?? before.status,
                assignedAdmin: body.assignedAdmin ?? before.assignedAdmin },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/support/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update ticket' }, { status: 500 })
  }
}
