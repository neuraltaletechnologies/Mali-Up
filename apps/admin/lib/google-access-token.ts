import { importPKCS8, SignJWT } from 'jose'

/**
 * OAuth2 access tokens for a Google service account, via the JWT-bearer grant
 * (`urn:ietf:params:oauth:grant-type:jwt-bearer`) — a plain `fetch` POST to
 * Google's token endpoint, no googleapis SDK, works on Cloudflare Workers.
 *
 * `lib/firestore-rest.ts` uses a *self-signed* JWT (no token round-trip) because
 * the Firestore REST API accepts one directly. Cloud Storage's JSON API does
 * not reliably accept self-signed JWTs for object reads, so scoped access
 * tokens are fetched here instead. Tokens are cached per-isolate, per-scope,
 * and refreshed a minute before expiry.
 */

interface ServiceAccountKey {
  clientEmail: string
  privateKey: string
}

/**
 * Play report access can use a dedicated service account (PLAY_SA_*) or fall
 * back to the same Firebase Admin credentials the rest of the app uses — the
 * latter only works if that SA has been granted access to the Play report
 * bucket (see docs/play-console-reports.md).
 */
export function playServiceAccount(): ServiceAccountKey | null {
  const clientEmail = process.env.PLAY_SA_CLIENT_EMAIL ?? process.env.FIREBASE_CLIENT_EMAIL
  const rawKey = process.env.PLAY_SA_PRIVATE_KEY ?? process.env.FIREBASE_PRIVATE_KEY
  if (!clientEmail || !rawKey) return null
  return { clientEmail, privateKey: rawKey.replace(/\\n/g, '\n') }
}

const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token'
const cache = new Map<string, { token: string; exp: number }>()

export async function getAccessToken(sa: ServiceAccountKey, scope: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const cacheKey = `${sa.clientEmail}|${scope}`
  const hit = cache.get(cacheKey)
  if (hit && hit.exp - 60 > now) return hit.token

  const key = await importPKCS8(sa.privateKey, 'RS256')
  const assertion = await new SignJWT({ scope })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(sa.clientEmail)
    .setSubject(sa.clientEmail)
    .setAudience(TOKEN_ENDPOINT)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key)

  const res = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })

  if (!res.ok) {
    throw new Error(`Google token exchange failed: ${res.status} ${await res.text()}`)
  }

  const body = (await res.json()) as { access_token: string; expires_in: number }
  cache.set(cacheKey, { token: body.access_token, exp: now + body.expires_in })
  return body.access_token
}
