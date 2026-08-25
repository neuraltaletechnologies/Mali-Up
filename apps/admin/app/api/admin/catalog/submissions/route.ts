import { NextResponse } from 'next/server'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { withCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'
import type { CommunitySubmission } from '@/types'

function toIso(value: unknown): string {
  if (!value) return new Date().toISOString()
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null) {
    const s = (value as Record<string, number>)._seconds ?? (value as Record<string, number>).seconds
    if (typeof s === 'number') return new Date(s * 1000).toISOString()
  }
  return new Date().toISOString()
}

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { searchParams } = new URL(request.url)
  const statusFilter = searchParams.get('status') // optional: pending|approved|rejected|pushed

  try {
    const submissions = await withCache(CACHE_KEYS.catalogSubmissions, 20_000, fetchSubmissions)
    const filtered = statusFilter
      ? submissions.filter((s) => s.status === statusFilter)
      : submissions

    return NextResponse.json({ submissions: filtered })
  } catch (err) {
    console.error('[GET /api/admin/catalog/submissions]', err)
    return NextResponse.json({ error: 'Failed to fetch submissions' }, { status: 500 })
  }
}

async function fetchSubmissions(): Promise<CommunitySubmission[]> {
  // Fetch all, sort + filter in memory to avoid composite index requirement
  const snap = await adminFirestore
    .collection('catalog_community_submissions')
    .orderBy('submissionCount', 'desc')
    .limit(500)
    .get()

  return snap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:                    doc.id,
        type:                  (d.type as CommunitySubmission['type']) || 'product',
        productName:           (d.productName  as string) || '',
        categoryName:          (d.categoryName as string) || (d.productName as string) || '',
        businessType:          (d.businessType as string) || '',
        businessTypeName:      (d.businessTypeName as string) || (d.businessType as string) || '',
        categorySlug:          (d.categorySlug as string) || '',
        unit:                  (d.unit as string) || 'Piece',
        description:           (d.description as string) || '',
        submittedByUid:        (d.submittedByUid as string) || '',
        submittedByBusinessId: (d.submittedByBusinessId as string) || '',
        businessName:          (d.businessName as string) || '',
        submissionCount:       (d.submissionCount as number) || 1,
        firstSeenAt:           toIso(d.firstSeenAt ?? d.createdAt),
        lastSeenAt:            toIso(d.lastSeenAt  ?? d.createdAt),
        status:                (d.status as CommunitySubmission['status']) || 'pending',
        adminNotes:            (d.adminNotes as string) || '',
        masterDocId:           (d.masterDocId as string) || '',
        pushedAt:              toIso(d.pushedAt),
      }
    })
}
