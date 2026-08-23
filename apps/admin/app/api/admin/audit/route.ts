import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import type { AuditEntry } from '@/types'

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const snap = await adminFirestore
      .collection('admin_audit_log')
      .orderBy('createdAt', 'desc')
      .limit(500)
      .get()

    const entries: AuditEntry[] = snap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:           doc.id,
        adminId:      (d.adminId as string)      || 'unknown',
        adminName:    (d.adminName as string)    || 'Admin',
        action:       (d.action as string)       || '',
        resourceType: (d.resourceType as string) || '',
        resourceId:   (d.resourceId as string)   || '',
        resourceName: (d.resourceName as string) || '',
        isDestructive: !!d.isDestructive,
        createdAt:    toIso(d.createdAt),
        ip:           (d.ip as string | undefined) || undefined,
        before:       (d.before as Record<string, unknown> | undefined) || undefined,
        after:        (d.after as Record<string, unknown> | undefined) || undefined,
      }
    })

    return NextResponse.json({ entries })
  } catch (err) {
    console.error('[GET /api/admin/audit]', err)
    return NextResponse.json({ error: 'Failed to fetch audit log' }, { status: 500 })
  }
}
