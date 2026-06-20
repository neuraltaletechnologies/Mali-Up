import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

type Params = { id: string }

export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { id } = await params

  try {
    const body = (await request.json()) as { status: 'approved' | 'rejected' }
    if (!['approved', 'rejected'].includes(body.status)) {
      return NextResponse.json({ error: 'status must be "approved" or "rejected"' }, { status: 400 })
    }

    const ref = adminFirestore.collection('catalog_community_submissions').doc(id)
    const doc = await ref.get()
    if (!doc.exists) return NextResponse.json({ error: 'Submission not found' }, { status: 404 })

    const data = doc.data()!
    await ref.update({ status: body.status, reviewedAt: new Date() })

    await writeAudit({
      action: body.status === 'approved' ? 'approve_submission' : 'reject_submission',
      resourceType: 'catalog_submission',
      resourceId: id,
      resourceName: (data.productName as string) || id,
      isDestructive: body.status === 'rejected',
      before: { status: 'pending' },
      after:  { status: body.status },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/catalog/submissions/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update submission' }, { status: 500 })
  }
}
