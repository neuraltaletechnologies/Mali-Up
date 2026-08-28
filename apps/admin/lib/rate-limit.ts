import { NextResponse } from 'next/server'

/**
 * Fixed-window rate limiter for the admin API, backed by the `RATE_LIMIT_KV`
 * Cloudflare KV namespace (see wrangler.toml). Called from lib/api-guard.ts
 * so every /api/admin/* route gets it automatically — no per-route wiring.
 *
 * KV's get-then-put is NOT atomic: two requests landing in the same
 * sub-second window can both read the same counter and both increment from
 * it, under-counting by a request or two under heavy concurrency. That's an
 * accepted trade-off for blunting runaway polling/scripts against an
 * internal admin console, not a security boundary — anything money- or
 * SMS-cost-adjacent (e.g. OTP sends) uses a Firestore *transaction* instead,
 * see apps/mobile-app/functions/src/otp_rate_limit.ts.
 *
 * Local `next dev` has no Cloudflare bindings unless
 * initOpenNextCloudflareForDev() is wired up, so this falls back to an
 * in-memory per-isolate Map — same caveat already accepted by
 * lib/api-cache.ts's withCache().
 */

// Minimal shape of the binding this file actually uses — avoids pulling in
// @cloudflare/workers-types just for one interface.
interface KvLike {
  get(key: string): Promise<string | null>
  put(key: string, value: string, opts?: { expirationTtl?: number }): Promise<void>
}

interface RateLimitResult {
  allowed: boolean
  retryAfterSeconds: number
}

// Cloudflare KV rejects any expirationTtl below 60 seconds. Our fixed-window
// logic already re-checks `now - windowStart >= windowMs` on read, so letting a
// spent counter linger a few extra seconds past the window is harmless — it's
// treated as expired on the next read regardless of when KV actually evicts it.
const KV_MIN_TTL_SECONDS = 60

const memoryStore = new Map<string, { count: number; windowStart: number }>()

async function getKv(): Promise<KvLike | null> {
  try {
    // Dynamic import: this package only resolves bindings when actually
    // running under the Cloudflare Workers runtime (wrangler dev / deployed).
    // `next dev` doesn't have them, and dynamic import lets that fail softly
    // instead of blowing up module init for every route on every request.
    const { getCloudflareContext } = await import('@opennextjs/cloudflare')
    const { env } = await getCloudflareContext({ async: true })
    return (env as Record<string, unknown>)?.RATE_LIMIT_KV as KvLike | undefined ?? null
  } catch {
    return null
  }
}

async function checkRateLimit(
  key: string,
  limit: number,
  windowSeconds: number,
): Promise<RateLimitResult> {
  const now = Date.now()
  const windowMs = windowSeconds * 1000
  const kv = await getKv()

  if (!kv) {
    const hit = memoryStore.get(key)
    if (!hit || now - hit.windowStart >= windowMs) {
      memoryStore.set(key, { count: 1, windowStart: now })
      return { allowed: true, retryAfterSeconds: 0 }
    }
    hit.count += 1
    if (hit.count > limit) {
      return { allowed: false, retryAfterSeconds: Math.ceil((hit.windowStart + windowMs - now) / 1000) }
    }
    return { allowed: true, retryAfterSeconds: 0 }
  }

  const raw = await kv.get(key)
  const parsed = raw ? (JSON.parse(raw) as { count: number; windowStart: number }) : null

  if (!parsed || now - parsed.windowStart >= windowMs) {
    await kv.put(key, JSON.stringify({ count: 1, windowStart: now }), {
      expirationTtl: Math.max(windowSeconds, KV_MIN_TTL_SECONDS),
    })
    return { allowed: true, retryAfterSeconds: 0 }
  }

  if (parsed.count + 1 > limit) {
    return { allowed: false, retryAfterSeconds: Math.ceil((parsed.windowStart + windowMs - now) / 1000) }
  }

  const remainingTtl = Math.max(
    Math.ceil((parsed.windowStart + windowMs - now) / 1000),
    KV_MIN_TTL_SECONDS,
  )
  await kv.put(
    key,
    JSON.stringify({ count: parsed.count + 1, windowStart: parsed.windowStart }),
    { expirationTtl: remainingTtl },
  )
  return { allowed: true, retryAfterSeconds: 0 }
}

function tooManyRequests(retryAfterSeconds: number): NextResponse {
  return NextResponse.json(
    { error: 'Too many requests. Please slow down and try again shortly.' },
    { status: 429, headers: { 'Retry-After': String(retryAfterSeconds) } },
  )
}

/**
 * Per-admin budget: generous enough for normal dashboard use (including
 * tab-focus refetches — see lib/api-cache.ts) while still catching a runaway
 * polling loop or a leaked session being scripted against.
 */
export async function rateLimitAdmin(uid: string): Promise<NextResponse | null> {
  const result = await checkRateLimit(`admin:${uid}`, 300, 60)
  return result.allowed ? null : tooManyRequests(result.retryAfterSeconds)
}

/**
 * Per-IP budget applied before an admin session even exists — e.g. hitting
 * /api/admin/* with no cookie, or repeated failed sign-ins. Looser than the
 * per-admin budget since it can sit behind a shared NAT, but tight enough to
 * blunt a credential-stuffing / probing script.
 */
export async function rateLimitIp(ip: string, opts?: { limit?: number; windowSeconds?: number }): Promise<NextResponse | null> {
  const limit = opts?.limit ?? 60
  const windowSeconds = opts?.windowSeconds ?? 60
  const result = await checkRateLimit(`ip:${ip}`, limit, windowSeconds)
  return result.allowed ? null : tooManyRequests(result.retryAfterSeconds)
}

/** Best-effort real client IP behind Cloudflare. */
export function clientIp(headers: Headers): string {
  return headers.get('cf-connecting-ip') ?? headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
}
