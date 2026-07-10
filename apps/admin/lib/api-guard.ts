import { auth } from '@/lib/auth'
import { NextResponse } from 'next/server'

/**
 * Call at the top of every admin API route.
 * Returns null when authenticated, or a 401 Response to return immediately.
 *
 * The admin custom claim + `/platform_admins` doc are re-checked by the
 * `jwt` callback in lib/auth.ts on a timer (ADMIN_RECHECK_INTERVAL_MS,
 * currently 5 min) instead of on every single API call — revoking an admin
 * (set-admin-claim.ts --revoke) now takes effect within that window rather
 * than instantly, but every request no longer pays 2 sequential Firebase
 * round trips just to check who's asking.
 */
export async function requireAdminSession(): Promise<NextResponse | null> {
  const session = await auth()
  if (!session?.user?.id || !session.user.isAdmin) {
    return NextResponse.json({ error: 'Unauthorised' }, { status: 401 })
  }
  return null
}
