import { NextResponse } from 'next/server'
import { adminAuth } from '@/lib/firebase-admin'
import { auth } from '@/lib/auth'
import { requireAdminSession } from '@/lib/api-guard'
import { writeAudit } from '@/lib/write-audit'

export async function PATCH(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  const session = await auth()
  const uid = session!.user!.id!

  try {
    const body = (await request.json()) as { name?: string }

    if (!body.name?.trim()) {
      return NextResponse.json({ error: 'name is required' }, { status: 400 })
    }

    const trimmedName = body.name.trim()
    await adminAuth.updateUser(uid, { displayName: trimmedName })

    await writeAudit({
      action: 'update_admin_profile',
      resourceType: 'admin',
      resourceId: uid,
      resourceName: trimmedName,
      isDestructive: false,
      after: { displayName: trimmedName },
    })

    return NextResponse.json({ ok: true, name: trimmedName })
  } catch (err) {
    console.error('[PATCH /api/admin/me]', err)
    return NextResponse.json({ error: 'Failed to update profile' }, { status: 500 })
  }
}
