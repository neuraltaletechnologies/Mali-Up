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

    // Mobile app stores businesses in the top-level `businesses` collection.
    const snapshot = await adminFirestore
      .collection('businesses')
      .limit(limitParam)
      .get()

    const businesses = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data() as Record<string, unknown>
        // ownerUid is stored as a field in the business document
        const uid = (data.ownerUid as string) || ''

        // Staff are stored in the `staff` sub-collection (not team_members)
        let staffCount = 0
        try {
          const countSnap = await doc.ref.collection('staff').count().get()
          staffCount = countSnap.data().count ?? 0
        } catch {
          // staff sub-collection may not exist yet
        }
        return mapBusiness(uid, doc.id, data, staffCount)
      })
    )

    businesses.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

    return NextResponse.json({ businesses, total: businesses.length })
  } catch (err) {
    console.error('[GET /api/admin/businesses]', err)
    return NextResponse.json({ error: 'Failed to fetch businesses' }, { status: 500 })
  }
}
