import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapBusiness } from '@/lib/firestore-mappers'
import { writeAudit } from '@/lib/write-audit'
import { withCache, invalidateCache } from '@/lib/api-cache'
import { FieldValue } from 'firebase-admin/firestore'

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { searchParams } = new URL(request.url)
    const limitParam = Math.min(Number(searchParams.get('limit') ?? '300'), 1000)

    const body = await withCache(`businesses:${limitParam}`, 60_000, () =>
      fetchBusinesses(limitParam),
    )
    return NextResponse.json(body)
  } catch (err) {
    console.error('[GET /api/admin/businesses]', err)
    return NextResponse.json({ error: 'Failed to fetch businesses' }, { status: 500 })
  }
}

async function fetchBusinesses(limitParam: number) {
  // Mobile app stores businesses in the top-level `businesses` collection.
  const snapshot = await adminFirestore
    .collection('businesses')
    .limit(limitParam)
    .get()

  // One collectionGroup scan for every business's staff instead of a
  // per-business count() query (was 1 extra read per business, N+1 total).
  const staffSnap = await adminFirestore.collectionGroup('staff').get()
  const staffCounts = new Map<string, number>()
  for (const staffDoc of staffSnap.docs) {
    const bizId = staffDoc.ref.parent.parent?.id
    if (!bizId) continue
    staffCounts.set(bizId, (staffCounts.get(bizId) ?? 0) + 1)
  }

  const businesses = snapshot.docs.map((doc) => {
    const data = doc.data() as Record<string, unknown>
    // ownerUid is stored as a field in the business document
    const uid = (data.ownerUid as string) || ''
    return mapBusiness(uid, doc.id, data, staffCounts.get(doc.id) ?? 0)
  })

  businesses.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return { businesses, total: businesses.length }
}

// POST — create a business for an existing user
export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      uid: string
      businessName: string
      businessCategory?: string
      city?: string
      district?: string
    }

    if (!body.uid?.trim()) {
      return NextResponse.json({ error: 'uid is required' }, { status: 400 })
    }
    if (!body.businessName?.trim()) {
      return NextResponse.json({ error: 'businessName is required' }, { status: 400 })
    }

    const userDoc = await adminFirestore.collection('users').doc(body.uid).get()
    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }
    const userData = userDoc.data() as Record<string, unknown>

    // Duplicate check — prevent creating a business with the same name for the same owner
    const existingSnap = await adminFirestore
      .collection('businesses')
      .where('ownerUid', '==', body.uid)
      .get()
    const nameNorm = body.businessName.trim().toLowerCase()
    const duplicate = existingSnap.docs.some(
      (d) => ((d.data().businessName as string) ?? '').toLowerCase() === nameNorm,
    )
    if (duplicate) {
      return NextResponse.json(
        { error: `A business named "${body.businessName.trim()}" already exists for this user.` },
        { status: 409 },
      )
    }

    const now = FieldValue.serverTimestamp()
    const bizRef = adminFirestore.collection('businesses').doc()
    const businessId = bizRef.id

    const city     = body.city?.trim() || ''
    const district = body.district?.trim() || ''

    await bizRef.set({
      businessName:       body.businessName.trim(),
      businessCategory:   body.businessCategory?.trim() || 'retail',
      businessType:       body.businessCategory?.trim() || 'retail',
      city,
      district,
      region:             city,
      placeOfBusiness:    district ? `${city}, ${district}` : city,
      ownerName:          (userData.displayName as string) || (userData.name as string) || '',
      ownerUid:           body.uid,
      ownerPhone:         (userData.phone as string) || '',
      plan:               'Trial',
      isActive:           true,
      subscriptionStatus: 'trial',
      createdAt:          now,
      updatedAt:          now,
    })

    // Add business to user — only set selectedBusinessId/defaultContext if user has none yet
    const updatePayload: Record<string, unknown> = {
      businesses: FieldValue.arrayUnion(businessId),
      updatedAt:  now,
    }
    if (!userData.selectedBusinessId) {
      updatePayload.selectedBusinessId = businessId
      updatePayload.defaultContext     = `business:${businessId}`
    }
    await adminFirestore.collection('users').doc(body.uid).update(updatePayload)

    await writeAudit({
      action:       'create_business',
      resourceType: 'business',
      resourceId:   businessId,
      resourceName: body.businessName.trim(),
      isDestructive: false,
      after: { uid: body.uid, businessId },
    })

    invalidateCache('businesses:300')
    invalidateCache('businesses:500')
    invalidateCache('analytics')

    return NextResponse.json({ uid: body.uid, businessId }, { status: 201 })
  } catch (err: unknown) {
    console.error('[POST /api/admin/businesses]', err)
    const msg = err instanceof Error ? err.message : 'Failed to create business'
    return NextResponse.json({ error: msg }, { status: 500 })
  }
}
