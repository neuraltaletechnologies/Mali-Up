import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'
import type { PlatformConfig } from '@/types'

// 9999 is used in Firestore storage as a sentinel for "Infinity" bracket in
// cancellation fee tiers, since Firestore/JSON do not support Infinity.
const INF_SENTINEL = 9999

const DEFAULT_CONFIG: Record<string, unknown> = {
  pricing: {
    starter: 0, growth: 49_000, business: 120_000, enterprise: 350_000,
    lifetimeMultiplier: 100, smsCreditPrice: 100, exportBundlePrice: 5_000,
  },
  planLimits: {
    starter: { users: 1 }, growth: { users: 3 }, business: { users: 10 },
    enterprise: { users: 50 }, lifetime: { users: 10 },
  },
  tax: { vatRate: 18, vatEnabled: true },
  lifetimeProgram: {
    uttAMISMonthlyRate: 1,
    cancellationFees: {
      growth:   [[3, 200_000], [12, 150_000], [24, 100_000], [36, 75_000], [INF_SENTINEL, 50_000]],
      business: [[3, 500_000], [12, 350_000], [24, 250_000], [36, 175_000], [INF_SENTINEL, 150_000]],
    },
  },
  platform: { maintenanceMode: false, maintenanceBanner: '' },
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const doc = await adminFirestore.collection('platform_config').doc('main').get()
    const config = doc.exists ? doc.data()! : DEFAULT_CONFIG
    return NextResponse.json(config)
  } catch (err) {
    console.error('[GET /api/admin/config]', err)
    return NextResponse.json({ error: 'Failed to fetch config' }, { status: 500 })
  }
}

export async function PATCH(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as PlatformConfig

    // Normalise Infinity → 9999 before storing
    const toStore = {
      ...body,
      lifetimeProgram: {
        ...body.lifetimeProgram,
        cancellationFees: {
          growth: body.lifetimeProgram.cancellationFees.growth.map(
            ([m, f]) => [m === Infinity || m >= INF_SENTINEL ? INF_SENTINEL : m, f]
          ),
          business: body.lifetimeProgram.cancellationFees.business.map(
            ([m, f]) => [m === Infinity || m >= INF_SENTINEL ? INF_SENTINEL : m, f]
          ),
        },
      },
      updatedAt: new Date(),
    }

    const ref = adminFirestore.collection('platform_config').doc('main')
    const before = (await ref.get()).data() ?? DEFAULT_CONFIG

    await ref.set(toStore)

    await writeAudit({
      action: 'update_config',
      resourceType: 'config',
      resourceId: 'main',
      resourceName: 'Platform Config',
      isDestructive: false,
      before: before as Record<string, unknown>,
      after: toStore as Record<string, unknown>,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error('[PATCH /api/admin/config]', err)
    return NextResponse.json({ error: 'Failed to save config' }, { status: 500 })
  }
}
