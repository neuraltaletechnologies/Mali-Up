import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapBusiness } from '@/lib/firestore-mappers'

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { searchParams } = new URL(request.url)
    const limitParam = Math.min(Number(searchParams.get('limit') ?? '300'), 1000)

    // collectionGroup query — hits every `businesses` sub-collection across all tenants
    const snapshot = await adminFirestore
      .collectionGroup('businesses')
      .orderBy('createdAt', 'desc')
      .limit(limitParam)
      .get()

    const businesses = await Promise.all(
      snapshot.docs.map(async (doc) => {
        // Parent path: tenants/{uid}/businesses/{bizId}
        const uid = doc.ref.parent.parent?.id ?? ''
        const data = doc.data() as Record<string, unknown>
        // Staff count via sub-collection count (cheap aggregate)
        let staffCount = 0
        try {
          const countSnap = await doc.ref.collection('team_members').count().get()
          staffCount = countSnap.data().count ?? 0
        } catch {
          // team_members may not exist yet
        }
        return mapBusiness(uid, doc.id, data, staffCount)
      })
    )

    return NextResponse.json({ businesses, total: businesses.length })
  } catch (err) {
    console.error('[GET /api/admin/businesses]', err)
    return NextResponse.json({ error: 'Failed to fetch businesses' }, { status: 500 })
  }
}
