import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { auth } from '@/lib/auth'
import { writeAudit } from '@/lib/write-audit'
import { withCache, invalidateCache } from '@/lib/api-cache'
import { FieldValue } from 'firebase-admin/firestore'
import type { BroadcastAudience, BroadcastCategory, PushBroadcast } from '@/types'

const CACHE_KEY = 'push-notifications'
const CATEGORIES: BroadcastCategory[] = ['reminder', 'promotion', 'update', 'general']

function toIso(value: unknown): string | undefined {
  if (!value) return undefined
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return undefined
}

// Admin composes a notification here; the actual push fan-out happens in the
// `sendAdminBroadcast` Cloud Function (functions/src/notifications.ts),
// triggered by this doc's creation — this route never calls
// admin.messaging() directly, so retries/resends can be added later without
// touching the admin app.
export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = await withCache(CACHE_KEY, 15_000, fetchBroadcasts)
    return NextResponse.json(body)
  } catch (err) {
    console.error('[GET /api/admin/push-notifications]', err)
    return NextResponse.json({ error: 'Failed to fetch notifications' }, { status: 500 })
  }
}

async function fetchBroadcasts() {
  const snap = await adminFirestore
    .collection('admin_broadcasts')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get()

  const broadcasts: PushBroadcast[] = snap.docs.map((doc) => {
    const d = doc.data()
    return {
      id:                doc.id,
      titleEn:           (d.titleEn as string) || '',
      bodyEn:            (d.bodyEn as string) || '',
      titleSw:           (d.titleSw as string) || undefined,
      bodySw:            (d.bodySw as string) || undefined,
      category:          (d.category as BroadcastCategory) || 'general',
      audience:          (d.audience as BroadcastAudience) || { kind: 'all' },
      route:             (d.route as string) || undefined,
      status:            (d.status as PushBroadcast['status']) || 'pending',
      targetCount:       (d.targetCount as number) || 0,
      sentCount:         (d.sentCount as number) || 0,
      failureCount:      (d.failureCount as number) || 0,
      createdAt:         toIso(d.createdAt) || new Date().toISOString(),
      sentAt:            toIso(d.sentAt),
      createdByAdminId:  (d.createdByAdminId as string) || '',
      createdByAdminName: (d.createdByAdminName as string) || 'Admin',
    }
  })

  return { broadcasts, total: broadcasts.length }
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      titleEn?: string
      bodyEn?: string
      titleSw?: string
      bodySw?: string
      category?: string
      route?: string
      audience?: BroadcastAudience
    }

    const titleEn = body.titleEn?.trim() || ''
    const bodyEn = body.bodyEn?.trim() || ''
    if (!titleEn) return NextResponse.json({ error: 'titleEn is required' }, { status: 400 })
    if (!bodyEn) return NextResponse.json({ error: 'bodyEn is required' }, { status: 400 })

    const category = CATEGORIES.includes(body.category as BroadcastCategory)
      ? (body.category as BroadcastCategory)
      : 'general'

    const audience = body.audience
    if (!audience || (audience.kind !== 'all' && audience.kind !== 'businesses')) {
      return NextResponse.json({ error: 'audience is required' }, { status: 400 })
    }
    if (audience.kind === 'businesses' && (!audience.businessIds || audience.businessIds.length === 0)) {
      return NextResponse.json({ error: 'Select at least one business' }, { status: 400 })
    }

    const session = await auth()
    const adminId = session?.user?.id ?? 'unknown'
    const adminName = session?.user?.name ?? session?.user?.email ?? 'Admin'

    const now = FieldValue.serverTimestamp()
    const ref = adminFirestore.collection('admin_broadcasts').doc()
    await ref.set({
      titleEn,
      bodyEn,
      titleSw:            body.titleSw?.trim() || null,
      bodySw:             body.bodySw?.trim() || null,
      category,
      route:              body.route?.trim() || null,
      audience,
      status:             'pending',
      targetCount:        0,
      sentCount:          0,
      failureCount:       0,
      createdAt:          now,
      sentAt:             null,
      createdByAdminId:   adminId,
      createdByAdminName: adminName,
    })

    await writeAudit({
      action:       'send_push_notification',
      resourceType: 'broadcast',
      resourceId:   ref.id,
      resourceName: titleEn,
      isDestructive: false,
      after: {
        category,
        audience,
        titleEn,
        bodyEn,
      },
    })

    invalidateCache(CACHE_KEY)

    return NextResponse.json({ id: ref.id }, { status: 201 })
  } catch (err) {
    console.error('[POST /api/admin/push-notifications]', err)
    return NextResponse.json({ error: 'Failed to send notification' }, { status: 500 })
  }
}
