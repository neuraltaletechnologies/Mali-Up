import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import type { VersionGateConfig } from '@/types'

// Defaults to a no-op gate (min/recommended = 1) so an unconfigured doc never
// blocks or nags anyone — an admin opts in by raising these numbers.
const DEFAULT_CONFIG: VersionGateConfig = {
  minSupportedBuildNumber: 1,
  recommendedBuildNumber: 1,
  updateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.neuraltale.maliup',
  updateUrlIOS: '',
  messageEn: '',
  messageSw: '',
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const doc = await adminFirestore.collection('platform_config').doc('version_gate').get()
    const config = doc.exists ? { ...DEFAULT_CONFIG, ...doc.data() } : DEFAULT_CONFIG
    return NextResponse.json(config)
  } catch (err) {
    console.error('[GET /api/admin/version-gate]', err)
    return NextResponse.json({ error: 'Failed to fetch version gate config' }, { status: 500 })
  }
}

export async function PATCH(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as VersionGateConfig
    const toStore = { ...body, updatedAt: new Date() }

    const ref = adminFirestore.collection('platform_config').doc('version_gate')
    const before = (await ref.get()).data() ?? DEFAULT_CONFIG

    await ref.set(toStore)

    await writeAudit({
      action: 'update_version_gate',
      resourceType: 'config',
      resourceId: 'version_gate',
      resourceName: 'Version Gate Config',
      isDestructive: false,
      before: before as Record<string, unknown>,
      after: toStore as Record<string, unknown>,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('[PATCH /api/admin/version-gate]', err)
    return NextResponse.json({ error: 'Failed to save version gate config' }, { status: 500 })
  }
}
