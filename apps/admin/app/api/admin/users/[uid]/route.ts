import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
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
    // User profile
    const userDoc = await adminFirestore.collection('users').doc(uid).get()
    if (!userDoc.exists) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }
    const user = mapUser(uid, userDoc.data() as Record<string, unknown>)

    // Businesses owned by this user
    const bizSnap = await adminFirestore
      .collection('tenants')
      .doc(uid)
      .collection('businesses')
      .get()

    const businesses = await Promise.all(
      bizSnap.docs.map(async (doc) => {
        const staffSnap = await doc.ref.collection('team_members').count().get()
        const staffCount = staffSnap.data().count ?? 0
        return mapBusiness(uid, doc.id, doc.data() as Record<string, unknown>, staffCount)
      })
    )

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
