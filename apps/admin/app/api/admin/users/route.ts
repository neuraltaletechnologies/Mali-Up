import { NextResponse } from 'next/server'
import { adminAuth } from '@/lib/firebase-admin'
import { restFirestore as adminFirestore } from '@/lib/firestore-rest'
import { requireAdminSession } from '@/lib/api-guard'
import { mapUser } from '@/lib/firestore-mappers'
import { writeAudit } from '@/lib/write-audit'
import { withCache, invalidateCache } from '@/lib/api-cache'
import { CACHE_KEYS } from '@/lib/cache-keys'
import { FieldValue } from '@/lib/firestore-rest'

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { searchParams } = new URL(request.url)
    const limitParam = Math.min(Number(searchParams.get('limit') ?? '200'), 500)

    const result = await withCache(CACHE_KEYS.users(limitParam), 30_000, () => fetchUsers(limitParam))
    return NextResponse.json({ users: result, total: result.length })
  } catch (err) {
    console.error('[GET /api/admin/users]', err)
    return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 })
  }
}

async function fetchUsers(limitParam: number) {
  const snapshot = await adminFirestore
    .collection('users')
    .orderBy('createdAt', 'desc')
    .limit(limitParam)
    .get()

  const rawDocs = snapshot.docs
  const users = rawDocs.map((doc) =>
    mapUser(doc.id, doc.data() as Record<string, unknown>)
  )

  // The `businesses` array on the user doc isn't kept up to date by the app
  // (onboarding only writes ownerUid on the business doc, and team members
  // carry a single `businessId`), so it under-counted — users showed 0
  // businesses and no name. The businesses collection's ownerUid is the
  // source of truth; query it for these users ('in' caps at 30 values).
  const uids = rawDocs.map((doc) => doc.id)
  const ownedByUser = new Map<string, Map<string, string>>()
  for (let i = 0; i < uids.length; i += 30) {
    const snap = await adminFirestore
      .collection('businesses')
      .where('ownerUid', 'in', uids.slice(i, i + 30))
      .get()
    snap.docs.forEach((d) => {
      const data = d.data()
      const owner = data.ownerUid as string
      if (!ownedByUser.has(owner)) ownedByUser.set(owner, new Map())
      ownedByUser.get(owner)!.set(d.id, (data.businessName as string) || '')
    })
  }

  // Businesses a user is linked to without owning (team members, or ids
  // only listed on the user doc) — names fetched in one batch, and only
  // ones that still exist are counted.
  const linkedIds = rawDocs.map((doc) => {
    const d = doc.data()
    const ids = new Set<string>(Array.isArray(d.businesses) ? (d.businesses as string[]) : [])
    if (typeof d.businessId === 'string' && d.businessId) ids.add(d.businessId)
    if (typeof d.selectedBusinessId === 'string' && d.selectedBusinessId) ids.add(d.selectedBusinessId)
    return ids
  })
  const bizNames = new Map<string, string>()
  ownedByUser.forEach((m) => m.forEach((name, id) => bizNames.set(id, name)))
  const unknownIds = [...new Set(linkedIds.flatMap((s) => [...s]))].filter((id) => !bizNames.has(id))
  if (unknownIds.length > 0) {
    const bizDocs = await adminFirestore.getAll(
      ...unknownIds.map((id) => adminFirestore.collection('businesses').doc(id)),
    )
    bizDocs.forEach((d) => {
      if (d.exists) bizNames.set(d.id, (d.data()?.businessName as string) || '')
    })
  }

  return users.map((u, i) => {
    const d = rawDocs[i].data()
    const ids = new Set<string>(ownedByUser.get(u.id)?.keys() ?? [])
    linkedIds[i].forEach((id) => { if (bizNames.has(id)) ids.add(id) })
    const preferred = [d.selectedBusinessId, d.businessId].find(
      (id): id is string => typeof id === 'string' && ids.has(id),
    )
    const primary = preferred ?? [...ids][0]
    return {
      ...u,
      businessCount: ids.size,
      businessName: primary ? bizNames.get(primary) || '' : '',
    }
  })
}

// ── POST — create a new user + optional business ──────────────────────────────
export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      firstName: string
      lastName: string
      phone: string          // Tanzanian format without country code, e.g. "712345678"
      email?: string
      password?: string      // optional; a temp one is generated if omitted
      businessName?: string
      businessCategory?: string
      // Mirrors the mobile app's onboarding business-location step
      // (country / region "mkoa" / district "wilaya") — see
      // apps/mobile-app/lib/features/onboarding/presentation/screens/business_details_screen.dart
      businessCountry?: string
      businessRegion?: string
      businessDistrict?: string
    }

    const firstName = body.firstName?.trim() || ''
    const lastName = body.lastName?.trim() || ''
    if (!firstName || !lastName) {
      return NextResponse.json({ error: 'First name and last name are required' }, { status: 400 })
    }
    if (!body.phone?.trim()) {
      return NextResponse.json({ error: 'phone is required' }, { status: 400 })
    }

    const fullName = `${firstName} ${lastName}`.trim()
    const normalizedPhone = body.phone.replace(/\D/g, '')
    const e164 = `+255${normalizedPhone.replace(/^0/, '').replace(/^255/, '')}`

    // Generate a temporary password if not provided
    const password = body.password?.trim() || Math.random().toString(36).slice(-10) + 'A1!'

    // Create Firebase Auth user
    const userRecord = await adminAuth.createUser({
      phoneNumber: e164,
      email: body.email || undefined,
      displayName: fullName,
      password,
    })

    const uid = userRecord.uid
    const now = FieldValue.serverTimestamp()

    // Create business document if businessName provided
    let businessId: string | null = null
    if (body.businessName?.trim()) {
      const businessRegion = body.businessRegion?.trim() || ''
      const bizRef = adminFirestore.collection('businesses').doc()
      businessId = bizRef.id
      await bizRef.set({
        businessName:     body.businessName.trim(),
        businessCategory: body.businessCategory?.trim() || 'retail',
        businessType:     body.businessCategory?.trim() || 'retail',
        // The app writes the chosen region into `city` too (its business
        // doc has no separate "city" concept) — mirrored here for parity.
        city:             businessRegion,
        region:           businessRegion,
        district:         body.businessDistrict?.trim() || '',
        country:          body.businessCountry?.trim() || 'TZ',
        ownerName:        fullName,
        ownerUid:         uid,
        ownerPhone:       normalizedPhone,
        plan:             'Trial',
        isActive:         true,
        subscriptionStatus: 'trial',
        createdAt:        now,
        updatedAt:        now,
      })
    }

    // Create user profile in Firestore
    await adminFirestore.collection('users').doc(uid).set({
      uid,
      phone:             normalizedPhone,
      displayName:       fullName,
      name:              fullName,
      firstName,
      lastName,
      email:             body.email?.toLowerCase() || null,
      isActive:          true,
      profileComplete:   true,
      createdAt:         now,
      updatedAt:         now,
      lastLoginAt:       now,
      ...(businessId ? {
        selectedBusinessId: businessId,
        defaultContext:     `business:${businessId}`,
        businesses:         [businessId],
      } : {}),
    })

    invalidateCache(CACHE_KEYS.users(200))

    await writeAudit({
      action: 'create_user',
      resourceType: 'user',
      resourceId: uid,
      resourceName: fullName,
      isDestructive: false,
      after: { uid, phone: e164, businessId },
    })

    return NextResponse.json({ uid, businessId }, { status: 201 })
  } catch (err: unknown) {
    console.error('[POST /api/admin/users]', err)
    const msg = err instanceof Error ? err.message : 'Failed to create user'
    return NextResponse.json({ error: msg }, { status: 500 })
  }
}
