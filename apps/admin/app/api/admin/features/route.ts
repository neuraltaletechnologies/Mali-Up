import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'
import type { FeatureFlag } from '@/types'

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const flags = await withCache(CACHE_KEYS.features, 30_000, fetchFlags)
    return NextResponse.json({ flags })
  } catch (err) {
    console.error('[GET /api/admin/features]', err)
    return NextResponse.json({ error: 'Failed to fetch feature flags' }, { status: 500 })
  }
}

async function fetchFlags(): Promise<FeatureFlag[]> {
  const snap = await adminFirestore
    .collection('platform_feature_flags')
    .orderBy('name')
    .get()

  return snap.docs.map((doc) => {
    const d = doc.data()
    return {
      id:             doc.id,
      name:           (d.name as string)        || '',
      description:    (d.description as string) || '',
      enabled:        !!d.enabled,
      rolloutPercent: typeof d.rolloutPercent === 'number' ? d.rolloutPercent : 100,
      overrides:      Array.isArray(d.overrides) ? d.overrides : [],
    }
  })
}
