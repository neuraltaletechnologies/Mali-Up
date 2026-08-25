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

  // Batch-fetch primary business name for each user
  const primaryBizIds = rawDocs.map((doc) => {
    const d = doc.data()
    return (d.selectedBusinessId as string | undefined)
      ?? (Array.isArray(d.businesses) ? (d.businesses[0] as string | undefined) : undefined)
  })
  const uniqueBizIds = [...new Set(primaryBizIds.filter((id): id is string => !!id))]
  const bizNameMap = new Map<string, string>()
  if (uniqueBizIds.length > 0) {
    const refs = uniqueBizIds.map((id) => adminFirestore.collection('businesses').doc(id))
    const bizDocs = await adminFirestore.getAll(...refs)
    bizDocs.forEach((d) => {
      if (d.exists) bizNameMap.set(d.id, (d.data()?.businessName as string) || '')
    })
  }

  return users.map((u, i) => {
    const bizId = primaryBizIds[i]
    return bizId ? { ...u, businessName: bizNameMap.get(bizId) || '' } : u
  })
}

// ── POST — create a new user + optional business ──────────────────────────────
export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      name: string
      phone: string          // Tanzanian format without country code, e.g. "712345678"
      email?: string
      password?: string      // optional; a temp one is generated if omitted
      businessName?: string
      businessCategory?: string
      placeOfBusiness?: string
    }

    if (!body.name?.trim()) {
      return NextResponse.json({ error: 'name is required' }, { status: 400 })
    }
    if (!body.phone?.trim()) {
      return NextResponse.json({ error: 'phone is required' }, { status: 400 })
    }

    const normalizedPhone = body.phone.replace(/\D/g, '')
    const e164 = `+255${normalizedPhone.replace(/^0/, '').replace(/^255/, '')}`

    // Generate a temporary password if not provided
    const password = body.password?.trim() || Math.random().toString(36).slice(-10) + 'A1!'

    // Create Firebase Auth user
    const userRecord = await adminAuth.createUser({
      phoneNumber: e164,
      email: body.email || undefined,
      displayName: body.name.trim(),
      password,
    })

    const uid = userRecord.uid
    const now = FieldValue.serverTimestamp()

    // Create business document if businessName provided
    let businessId: string | null = null
    if (body.businessName?.trim()) {
      const bizRef = adminFirestore.collection('businesses').doc()
      businessId = bizRef.id
      await bizRef.set({
        businessName:     body.businessName.trim(),
        businessCategory: body.businessCategory?.trim() || 'retail',
        businessType:     body.businessCategory?.trim() || 'retail',
        placeOfBusiness:  body.placeOfBusiness?.trim() || '',
        city:             body.placeOfBusiness?.trim() || '',
        ownerName:        body.name.trim(),
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
      displayName:       body.name.trim(),
      name:              body.name.trim(),
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
      resourceName: body.name.trim(),
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
