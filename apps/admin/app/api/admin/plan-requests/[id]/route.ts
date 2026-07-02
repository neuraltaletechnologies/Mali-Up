import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { FieldValue } from 'firebase-admin/firestore'

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = await req.json() as { action?: string; adminNotes?: string }
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
