import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import { mergeTrialConfig, type TrialConfig } from '@/lib/trial-config'

// platform_config/trial — free reverse-trial settings and message templates.

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const doc = await adminFirestore.collection('platform_config').doc('trial').get()
    return NextResponse.json(mergeTrialConfig(doc.data()))
  } catch (err) {
    console.error('[GET /api/admin/trial]', err)
    return NextResponse.json({ error: 'Failed to fetch trial config' }, { status: 500 })
  }
}

export async function PATCH(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as Partial<TrialConfig>
    // Normalise through the same merge the functions use, so nothing
    // malformed (negative days, unknown tier, stray keys) gets stored.
    const config = mergeTrialConfig(body as Record<string, unknown>)
    const ref = adminFirestore.collection('platform_config').doc('trial')
    const before = (await ref.get()).data() ?? {}

    await ref.set({ ...config, updatedAt: new Date() })

    await writeAudit({
      action: 'update_trial_config',
      resourceType: 'config',
      resourceId: 'trial',
      resourceName: 'Free Trial Config',
      isDestructive: false,
      before: before as Record<string, unknown>,
      after: config as unknown as Record<string, unknown>,
    })

    return NextResponse.json({ success: true, config })
  } catch (err) {
    console.error('[PATCH /api/admin/trial]', err)
    return NextResponse.json({ error: 'Failed to save trial config' }, { status: 500 })
  }
}
