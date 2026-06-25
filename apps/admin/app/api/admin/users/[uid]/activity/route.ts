import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'

export interface ActivityEntry {
  id: string
  action: string
  entityType?: string
  entityId?: string
  entityName?: string
  performedByName?: string
  amount?: number
  details?: string
  previousValue?: unknown
  newValue?: unknown
  businessId: string
  businessName: string
  timestamp: string
  source: 'business_log' | 'admin_log'
}

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds
      ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ uid: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid } = await params

  try {
    // 1. Find all businesses owned by this user
    const bizSnap = await adminFirestore
      .collection('businesses')
      .where('ownerUid', '==', uid)
      .get()

    const entries: ActivityEntry[] = []

    // 2. For each business, fetch last 30 audit_log entries
    await Promise.all(
      bizSnap.docs.map(async (bizDoc) => {
        const bizData = bizDoc.data()
        const bizName = (bizData.businessName as string) || bizDoc.id

        const logsSnap = await bizDoc.ref
          .collection('audit_logs')
          .orderBy('timestamp', 'desc')
          .limit(30)
          .get()

        for (const log of logsSnap.docs) {
          const d = log.data()
          entries.push({
            id:              `${bizDoc.id}-${log.id}`,
            action:          (d.action as string) || 'unknown',
            entityType:      d.entityType as string | undefined,
            entityId:        d.entityId as string | undefined,
            entityName:      (d.entityName as string) || (d.targetName as string) || undefined,
            performedByName: (d.performedByName as string) || undefined,
            amount:          typeof d.amount === 'number' ? d.amount : undefined,
            details:         d.details as string | undefined,
            previousValue:   d.previousValue,
            newValue:        d.newValue,
            businessId:      bizDoc.id,
            businessName:    bizName,
            timestamp:       toIso(d.timestamp),
            source:          'business_log',
          })
        }
      })
    )

    // 3. Fetch admin-level actions on this user from the global audit log
    try {
      const adminLogSnap = await adminFirestore
        .collection('admin_audit_log')
        .where('resourceId', '==', uid)
        .orderBy('timestamp', 'desc')
        .limit(20)
        .get()

      for (const log of adminLogSnap.docs) {
        const d = log.data()
        entries.push({
          id:              `admin-${log.id}`,
          action:          (d.action as string) || 'admin_action',
          entityType:      'user',
          performedByName: (d.adminName as string) || (d.performedByName as string) || 'Admin',
          businessId:      '',
          businessName:    '',
          timestamp:       toIso(d.timestamp),
          source:          'admin_log',
        })
      }
    } catch { /* admin_audit_log may not have composite index yet — skip */ }

    // Sort all entries newest-first, cap at 100
    entries.sort((a, b) => b.timestamp.localeCompare(a.timestamp))
    const limited = entries.slice(0, 100)

    return NextResponse.json({ entries: limited, total: entries.length })
  } catch (err) {
    console.error(`[GET /api/admin/users/${uid}/activity]`, err)
    return NextResponse.json({ error: 'Failed to fetch activity' }, { status: 500 })
  }
}
