import { NextResponse } from 'next/server'
import { adminAuth, adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapUser, mapBusiness } from '@/lib/firestore-mappers'
import { writeAudit } from '@/lib/write-audit'

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ uid: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid } = await params

  try {
    const userDoc = await adminFirestore.collection('users').doc(uid).get()
    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }
    const user = mapUser(uid, userDoc.data() as Record<string, unknown>)

    // Mobile app stores businesses in the top-level `businesses` collection
    // with an `ownerUid` field — not under tenants/{uid}/businesses.
    const bizSnap = await adminFirestore
      .collection('businesses')
      .where('ownerUid', '==', uid)
      .get()

    // staffCount is denormalized onto the business doc by addTeamMember /
    // deleteTeamMember (mobile app) — no per-business sub-collection read needed.
    const businesses = bizSnap.docs.map((doc) => {
      const data = doc.data() as Record<string, unknown>
      const staffCount = typeof data.staffCount === 'number' ? data.staffCount : 0
      return mapBusiness(uid, doc.id, data, staffCount)
    })

    return NextResponse.json({ user, businesses })
  } catch (err) {
    console.error(`[GET /api/admin/users/${uid}]`, err)
    return NextResponse.json({ error: 'Failed to fetch user' }, { status: 500 })
  }
}

// ── PATCH — suspend / unsuspend ──────────────────────────────────────────────
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ uid: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid } = await params

  try {
    const body = (await request.json()) as { isActive: boolean }
    if (typeof body.isActive !== 'boolean') {
      return NextResponse.json({ error: 'isActive (boolean) required' }, { status: 400 })
    }

    const userRef = adminFirestore.collection('users').doc(uid)
    const userDoc = await userRef.get()
    const userName = (userDoc.data()?.displayName as string) || (userDoc.data()?.name as string) || uid

    await userRef.update({ isActive: body.isActive, updatedAt: new Date() })

    await writeAudit({
      action: body.isActive ? 'unsuspend_user' : 'suspend_user',
      resourceType: 'user',
      resourceId: uid,
      resourceName: userName,
      isDestructive: !body.isActive,
      before: { isActive: !body.isActive },
      after:  { isActive:  body.isActive },
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PATCH /api/admin/users/${uid}]`, err)
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 })
  }
}

// ── PUT — edit user profile fields ───────────────────────────────────────────
export async function PUT(
  request: Request,
  { params }: { params: Promise<{ uid: string }> },
) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const { uid } = await params

  try {
    const body = (await request.json()) as {
      name?: string
      phone?: string
      email?: string
    }

    const updates: Record<string, unknown> = { updatedAt: new Date() }

    if (body.name?.trim()) {
      updates.displayName = body.name.trim()
      updates.name        = body.name.trim()
    }
    if (body.phone?.trim()) {
      const normalized = body.phone.trim().replace(/\D/g, '').replace(/^0/, '').replace(/^255/, '')
      updates.phone = normalized
    }
    if (body.email !== undefined) {
      updates.email = body.email.trim().toLowerCase() || null
    }

    const userRef = adminFirestore.collection('users').doc(uid)
    const snap    = await userRef.get()
    if (!snap.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    await userRef.update(updates)

    // Sync name, email and phone number to Firebase Auth
    try {
      const authUpdate: { displayName?: string; email?: string; phoneNumber?: string } = {}
      if (updates.displayName)                               authUpdate.displayName = updates.displayName as string
      if (updates.email && typeof updates.email === 'string') authUpdate.email      = updates.email
      if (updates.phone  && typeof updates.phone === 'string') authUpdate.phoneNumber = `+255${updates.phone}`
      if (Object.keys(authUpdate).length > 0) {
        await adminAuth.updateUser(uid, authUpdate)
      }
    } catch { /* auth update is best-effort */ }

    const before: Record<string, unknown> = {}
    const after:  Record<string, unknown> = {}
    if (updates.displayName) { before.name = snap.data()?.displayName; after.name = updates.displayName }
    if (updates.phone)       { before.phone = snap.data()?.phone;       after.phone = updates.phone }
    if (updates.email !== undefined) { before.email = snap.data()?.email; after.email = updates.email }

    await writeAudit({
      action: 'edit_user',
      resourceType: 'user',
      resourceId: uid,
      resourceName: (updates.displayName as string) || (snap.data()?.displayName as string) || uid,
      isDestructive: false,
      before,
      after,
    })

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error(`[PUT /api/admin/users/${uid}]`, err)
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 })
  }
}
