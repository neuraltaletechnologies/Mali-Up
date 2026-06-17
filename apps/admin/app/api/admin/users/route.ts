import { NextResponse } from 'next/server'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'
import { mapUser } from '@/lib/firestore-mappers'

export async function GET(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const { searchParams } = new URL(request.url)
    const limitParam = Math.min(Number(searchParams.get('limit') ?? '200'), 500)

    const snapshot = await adminFirestore
      .collection('users')
      .orderBy('createdAt', 'desc')
      .limit(limitParam)
      .get()

    const users = snapshot.docs.map((doc) =>
      mapUser(doc.id, doc.data() as Record<string, unknown>)
    )

    return NextResponse.json({ users, total: users.length })
  } catch (err) {
    console.error('[GET /api/admin/users]', err)
    return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 })
  }
}
