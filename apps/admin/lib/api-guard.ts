import { auth } from '@/lib/auth'
import { isAdminUser } from '@/lib/firebase-admin'
import { NextResponse } from 'next/server'

/**
 * Call at the top of every admin API route.
 * Returns null when authenticated, or a 401 Response to return immediately.
 *
 * Re-checks the admin custom claim + `/platform_admins` doc on every call
 * instead of trusting the NextAuth session alone — the claim is only
 * verified once, at login, when the session JWT is minted. Without this,
 * revoking an admin (set-admin-claim.ts --revoke) invalidates their Firebase
 * tokens but not their already-issued NextAuth session cookie, leaving them
 * with full API access until that cookie's ~30-day expiry.
 */
export async function requireAdminSession(): Promise<NextResponse | null> {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorised' }, { status: 401 })
  }
  const stillAdmin = await isAdminUser(session.user.id)
  if (!stillAdmin) {
    return NextResponse.json({ error: 'Unauthorised' }, { status: 401 })
  }
  return null
}
