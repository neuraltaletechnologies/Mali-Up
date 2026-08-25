import { headers } from 'next/headers'
import { auth } from '@/lib/auth'
import { NextResponse } from 'next/server'
import { clientIp, rateLimitAdmin, rateLimitIp } from '@/lib/rate-limit'

/**
 * Call at the top of every admin API route.
 * Returns null when authenticated, or a 401/429 Response to return immediately.
 *
 * The admin custom claim + `/platform_admins` doc are re-checked by the
 * `jwt` callback in lib/auth.ts on a timer (ADMIN_RECHECK_INTERVAL_MS,
 * currently 5 min) instead of on every single API call — revoking an admin
 * (set-admin-claim.ts --revoke) now takes effect within that window rather
 * than instantly, but every request no longer pays 2 sequential Firebase
 * round trips just to check who's asking.
 *
 * Also rate-limits every call (see lib/rate-limit.ts) — an unauthenticated
 * caller is throttled per IP before `auth()` even runs, and an authenticated
 * one is throttled per admin uid, so this one change covers every
 * /api/admin/* route without touching each of them individually.
 */
export async function requireAdminSession(): Promise<NextResponse | null> {
  const session = await auth()
  if (!session?.user?.id || !session.user.isAdmin) {
    const ip = clientIp(await headers())
    const throttled = await rateLimitIp(ip)
    if (throttled) return throttled
    return NextResponse.json({ error: 'Unauthorised' }, { status: 401 })
  }

  const throttled = await rateLimitAdmin(session.user.id)
  if (throttled) return throttled

  return null
}
