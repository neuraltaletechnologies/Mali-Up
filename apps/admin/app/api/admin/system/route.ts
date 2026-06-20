import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import type { ServiceHealth } from '@/types'

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

// Default services when no overrides exist in Firestore.
// These reflect Firebase platform services the mobile app relies on.
const DEFAULT_SERVICES: Omit<ServiceHealth, 'uptime' | 'p95Latency' | 'sparkline'>[] = [
  { name: 'firestore',      displayName: 'Firestore',         status: 'healthy' },
  { name: 'auth',           displayName: 'Firebase Auth',     status: 'healthy' },
  { name: 'storage',        displayName: 'Cloud Storage',     status: 'healthy' },
  { name: 'functions',      displayName: 'Cloud Functions',   status: 'healthy' },
  { name: 'sync-engine',    displayName: 'Sync Engine',       status: 'healthy' },
  { name: 'invoicing',      displayName: 'Invoicing',         status: 'healthy' },
  { name: 'inventory',      displayName: 'Inventory',         status: 'healthy' },
  { name: 'customers',      displayName: 'Customers',         status: 'healthy' },
  { name: 'expenses',       displayName: 'Expenses',          status: 'healthy' },
  { name: 'notifications',  displayName: 'Notifications',     status: 'healthy' },
  { name: 'admin-api',      displayName: 'Admin API',         status: 'healthy' },
]

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    // Measure Firestore round-trip latency
    const start = Date.now()
    const healthDoc = await adminFirestore.collection('platform_system_health').doc('current').get()
    const latency = Date.now() - start

    // Load any manual status overrides stored by admins
    const overrides: Record<string, Partial<ServiceHealth>> = {}
    if (healthDoc.exists) {
      const stored = healthDoc.data()!
      if (Array.isArray(stored.services)) {
        for (const svc of stored.services as Partial<ServiceHealth>[]) {
          if (svc.name) overrides[svc.name] = svc
        }
      }
    }

    const firestoreStatus: ServiceHealth['status'] =
      latency < 500 ? 'healthy' : latency < 2000 ? 'degraded' : 'down'

    const services: ServiceHealth[] = DEFAULT_SERVICES.map((defaults) => {
      const override = overrides[defaults.name] ?? {}
      const status =
        defaults.name === 'firestore' ? firestoreStatus :
        (override.status ?? defaults.status)

      return {
        ...defaults,
        status,
        uptime:     override.uptime      ?? 99.99,
        p95Latency: defaults.name === 'firestore' ? latency :
                    (override.p95Latency ?? 25),
        sparkline:  override.sparkline   ?? [25, 25, 25, 25, 25, 25, 25],
      }
    })

    return NextResponse.json({
      services,
      updatedAt: new Date().toISOString(),
      firestoreLatencyMs: latency,
      manualOverrideAt: healthDoc.exists ? toIso(healthDoc.data()!.updatedAt) : null,
    })
  } catch (err) {
    console.error('[GET /api/admin/system]', err)
    return NextResponse.json({ error: 'Failed to fetch system health' }, { status: 500 })
  }
}
