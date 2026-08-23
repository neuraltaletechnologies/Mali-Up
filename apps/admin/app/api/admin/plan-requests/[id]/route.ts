import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { FieldValue } from '@/lib/firestore-rest'

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = await req.json() as { action?: string; adminNotes?: string; activated?: boolean }
    const action = body.action
    if (action !== 'approve' && action !== 'reject') {
      return NextResponse.json({ error: 'action must be approve or reject' }, { status: 400 })
    }

    const ref = adminFirestore.collection('plan_requests').doc(id)
    const snap = await ref.get()
    if (!snap.exists) {
      return NextResponse.json({ error: 'Request not found' }, { status: 404 })
    }
    const before = snap.data() ?? {}

    const status = action === 'approve' ? 'approved' : 'rejected'
    await ref.set(
      {
        status,
        // Once activated, stays activated — re-approving without re-activating must not erase it.
        activated: Boolean(body.activated) || Boolean(before.activated),
        ...(typeof body.adminNotes === 'string' ? { adminNotes: body.adminNotes } : {}),
        resolvedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    )

    await writeAudit({
      action: `plan_request.${action}`,
      resourceType: 'plan_request',
      resourceId: id,
      resourceName: `${before.requestedTier ?? ''} request — ${before.name || before.phone || before.uid || id}`,
      before: { status: before.status },
      after: {
        status,
        activated: Boolean(body.activated) || Boolean(before.activated),
        ...(typeof body.adminNotes === 'string' ? { adminNotes: body.adminNotes } : {}),
      },
      isDestructive: false,
    })

    return NextResponse.json({ ok: true, status })
  } catch (err) {
    console.error('[PATCH /api/admin/plan-requests/[id]]', err)
    return NextResponse.json({ error: 'Failed to update plan request' }, { status: 500 })
  }
}
