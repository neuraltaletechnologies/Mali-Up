import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
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
    const body = (await request.json()) as {
      enabled?: boolean
      rolloutPercent?: number
    }

    const ref = adminFirestore.collection('platform_feature_flags').doc(id)
    const before = (await ref.get()).data() ?? {}

    const update: Record<string, unknown> = { updatedAt: new Date() }
    if (typeof body.enabled === 'boolean')       update.enabled       = body.enabled
    if (typeof body.rolloutPercent === 'number') update.rolloutPercent = body.rolloutPercent

    await ref.update(update)

    await writeAudit({
      action: 'update_feature_flag',
      resourceType: 'feature_flag',
      resourceId: id,
      resourceName: (before.name as string) || id,
      isDestructive: false,
      before: { enabled: before.enabled, rolloutPercent: before.rolloutPercent },
      after:  { enabled: update.enabled  ?? before.enabled,
                rolloutPercent: update.rolloutPercent ?? before.rolloutPercent },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/features/${id}]`, err)
    return NextResponse.json({ error: 'Failed to update feature flag' }, { status: 500 })
  }
}
