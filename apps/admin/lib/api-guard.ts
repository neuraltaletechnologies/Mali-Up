import { auth } from '@/lib/auth'
import { NextResponse } from 'next/server'

/**
 * Call at the top of every admin API route.
 * Returns null when authenticated, or a 401 Response to return immediately.
 */
export async function requireAdminSession(): Promise<NextResponse | null> {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorised' }, { status: 401 })
  }
  return null
}
