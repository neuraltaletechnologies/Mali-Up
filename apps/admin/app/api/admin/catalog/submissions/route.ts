import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
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

export async function GET() {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const snap = await adminFirestore
      .collection('catalog_community_submissions')
      .orderBy('submissionCount', 'desc')
      .limit(200)
      .get()

    const submissions: CommunitySubmission[] = snap.docs.map((doc) => {
      const d = doc.data()
      return {
        id:              doc.id,
        productName:     (d.productName as string)    || '',
        businessName:    (d.businessName as string)   || '',
        businessType:    (d.businessType as string)   || '',
        submissionCount: (d.submissionCount as number) || 1,
        firstSeenAt:     toIso(d.firstSeenAt ?? d.createdAt),
        status:          (d.status as CommunitySubmission['status']) || 'pending',
      }
    })

    return NextResponse.json({ submissions })
  } catch (err) {
    console.error('[GET /api/admin/catalog/submissions]', err)
    return NextResponse.json({ error: 'Failed to fetch submissions' }, { status: 500 })
  }
}
