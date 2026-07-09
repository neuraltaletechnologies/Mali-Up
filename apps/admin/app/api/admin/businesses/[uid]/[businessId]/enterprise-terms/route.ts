import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { auth } from '@/lib/auth'
import type { EnterpriseOverride } from '@/types'

type Params = { uid: string; businessId: string }

// PATCH — set (or clear, with `{}`) a business's negotiated Enterprise terms.
// Full replace, not merge: the admin UI always sends the whole override
// object, same as EditPlanDrawer does for the shared plan definitions.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<Params> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid, businessId } = await params

  try {
    const bizRef = adminFirestore.collection('businesses').doc(businessId)
    const bizDoc = await bizRef.get()
    if (!bizDoc.exists) {
      return NextResponse.json({ error: 'Business not found' }, { status: 404 })
    }

    const raw = bizDoc.data() as Record<string, unknown>
    if (raw.plan !== 'enterprise') {
      return NextResponse.json(
        { error: 'Business must be on the Enterprise plan to set custom terms' },
        { status: 400 },
      )
    }

    const body = (await request.json()) as Partial<EnterpriseOverride>
    const session = await auth()

    const override: EnterpriseOverride = {
      ...body,
      setAt: new Date().toISOString(),
      setBy: session?.user?.name ?? session?.user?.email ?? 'Admin',
    }

    const ownerUid = (raw.ownerUid as string) || uid

    // mergeFields (not a plain merge:true) so the whole enterpriseOverrides
    // object is replaced wholesale — a plain merge would deep-merge the
    // nested map and leave stale fields the admin meant to clear behind.
    await bizRef.set({ enterpriseOverrides: override }, { mergeFields: ['enterpriseOverrides'] })
    await adminFirestore.collection('users').doc(ownerUid).set(
      { enterpriseOverrides: override },
      { mergeFields: ['enterpriseOverrides'] },
    )

    await writeAudit({
      action: 'set_enterprise_terms',
      resourceType: 'business',
      resourceId: businessId,
      resourceName: (raw.businessName as string) || businessId,
      isDestructive: false,
      before: { enterpriseOverrides: raw.enterpriseOverrides ?? null },
      after: { enterpriseOverrides: override },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/businesses/${uid}/${businessId}/enterprise-terms]`, err)
    return NextResponse.json({ error: 'Failed to set enterprise terms' }, { status: 500 })
  }
}
