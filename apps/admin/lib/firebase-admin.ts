import admin from 'firebase-admin'
import { createRemoteJWKSet, jwtVerify, importPKCS8, SignJWT } from 'jose'

const GOOGLE_JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
)

// Singleton — safe to call multiple times.
function getAdminApp() {
  if (admin.apps.length) return admin.apps[0]!

  const projectId = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'

  // Production: use explicit service-account credentials from environment.
  // Development: falls back to Application Default Credentials (ADC) if
  // GOOGLE_APPLICATION_CREDENTIALS is set, or the service account JSON vars.
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined

  if (!process.env.FIREBASE_CLIENT_EMAIL || !privateKey) {
    console.warn(
      '[Firebase Admin] Missing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY in environment. Server-side token verification will fail.'
    )
  }

  const credential =
    process.env.FIREBASE_CLIENT_EMAIL && privateKey
      ? admin.credential.cert({
          projectId,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey,
        })
      : admin.credential.applicationDefault()

  return admin.initializeApp({ credential, projectId })
}

export const adminApp = getAdminApp()
export const adminAuth = admin.auth(adminApp)
export const adminFirestore = admin.firestore(adminApp)

// admin.firestore(adminApp) returns the same cached Firestore instance across
// module re-evaluations (e.g. Turbopack/webpack re-executing this module on
// every dev-server request), but Firestore throws if settings() is called
// twice on that instance. Swallow that specific error — it just means an
// earlier module evaluation in this process already configured it.
// Deployed (and `wrangler dev`) runs on Cloudflare Workers (via OpenNext),
// which doesn't support the long-lived gRPC/HTTP2 streams the Firestore SDK
// uses by default — falling back to plain HTTP REST avoids multi-second
// stalls on every query there. `next dev` runs on plain Node, where gRPC
// works fine and its built-in keepalive/retry rides out transient network
// blips (Wi-Fi roam, VPN reconnect, laptop sleep/wake) far better than a
// one-shot REST fetch, which just hangs for the full timeout and throws.
// So only force REST when actually inside the Workers runtime.
//
// `globalThis.navigator?.userAgent === 'Cloudflare-Workers'` alone was NOT
// reliable here (it didn't match in this OpenNext build), so CF_WORKER (an
// explicit [vars] entry in wrangler.toml) is checked too, deterministically.
//
// IMPORTANT — this setting does NOT fix Firestore reads on Workers by
// itself. `preferRest` only picks the wire transport; every call still goes
// through protobufjs to compile message encoders/decoders/verifiers
// (visible in error stacks as Codegen/Type.resolveAll/Namespace.resolveAll),
// and protobufjs does that with `new Function(source)` — a dynamic code-eval
// call Cloudflare Workers' V8 isolates block by policy, with no
// compatibility flag to opt back in. So *any* @google-cloud/firestore call,
// gRPC or REST, throws the same opaque error here. That's why
// isAdminUser()'s Firestore document check below no longer uses this SDK
// client at all — see platformAdminDocExistsViaRest().
const isCloudflareWorkers =
  process.env.CF_WORKER === 'true' || globalThis.navigator?.userAgent === 'Cloudflare-Workers'
if (isCloudflareWorkers) {
  try {
    // Must be set before any other Firestore call.
    adminFirestore.settings({ preferRest: true })
  } catch (err) {
    if (!(err instanceof Error && err.message.includes('already been initialized'))) {
      throw err
    }
  }
}

export const adminStorage = admin.storage(adminApp).bucket('neuraltale-mali-up.firebasestorage.app')

/**
 * Verify a Firebase ID token and return the decoded claims.
 * Throws if the token is invalid or expired.
 */
export async function verifyIdToken(idToken: string) {
  const projectId =
    process.env.FIREBASE_PROJECT_ID ??
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ??
    'neuraltale-mali-up'

  try {
    return await adminAuth.verifyIdToken(idToken)
  } catch (err: any) {
    const errStr = String(err?.message ?? err)
    // Fallback for Cloudflare Workers (unenv) where Node's `https.request` is not implemented:
    // Verify using standard Web Crypto + Google JWKS via `jose`
    if (errStr.includes('https.request') || errStr.includes('unenv') || errStr.includes('argument-error')) {
      const { payload } = await jwtVerify(idToken, GOOGLE_JWKS, {
        issuer: `https://securetoken.google.com/${projectId}`,
        audience: projectId,
      })
      return {
        uid: payload.sub as string,
        email: (payload.email as string) ?? '',
        name: (payload.name as string) ?? (payload.email as string) ?? '',
        admin: payload.admin === true,
        ...payload,
      } as any
    }
    throw err
  }
}

// Self-signed JWT for calling Google APIs directly, without the
// @google-cloud/firestore SDK. Google accepts a service account's own RS256
// JWT as a Bearer token (no token-endpoint round trip) when `aud` names the
// full gRPC service — see https://developers.google.com/identity/protocols/oauth2/service-account#jwt-auth.
// Cached per-isolate and refreshed a minute before expiry.
let cachedFirestoreJwt: { token: string; exp: number } | null = null

async function getFirestoreBearerToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedFirestoreJwt && cachedFirestoreJwt.exp - 60 > now) {
    return cachedFirestoreJwt.token
  }

  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL
  const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY
  if (!clientEmail || !rawPrivateKey) {
    throw new Error(
      'Missing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY — required for the Firestore REST admin check.'
    )
  }

  const privateKey = await importPKCS8(rawPrivateKey.replace(/\\n/g, '\n'), 'RS256')
  const exp = now + 3600
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience('https://firestore.googleapis.com/google.firestore.v1.Firestore')
    .setIssuedAt(now)
    .setExpirationTime(exp)
    .sign(privateKey)

  cachedFirestoreJwt = { token, exp }
  return token
}

/**
 * Whether /platform_admins/{uid} exists — via a plain `fetch()` against the
 * Firestore REST API (JSON in, JSON out), not the @google-cloud/firestore
 * SDK. The SDK's own `.get()`/getAll() always goes through protobufjs
 * codegen (`new Function(...)`), which Cloudflare Workers blocks outright —
 * see the long comment above `isCloudflareWorkers`. This function has no
 * such dependency and works identically in Workers and plain Node.
 */
async function platformAdminDocExistsViaRest(uid: string): Promise<boolean> {
  const projectId = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
  const token = await getFirestoreBearerToken()

  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/platform_admins/${uid}`,
    { headers: { Authorization: `Bearer ${token}` } }
  )

  if (res.status === 404) return false
  if (!res.ok) {
    throw new Error(`Firestore REST admin-doc check failed: ${res.status} ${await res.text()}`)
  }
  return true
}

/**
 * Check whether a Firebase UID is a platform admin.
 * We use two independent gates so you can choose either:
 *   1. Custom claim:  token.admin === true   (set via the provisioning script)
 *   2. Firestore:     /platform_admins/{uid} document exists
 * Both must pass in production. In local dev the Firestore check is skipped
 * when SKIP_FIRESTORE_ADMIN_CHECK=true so you can test without a real
 * Firestore admin document.
 */
export async function isAdminUser(uid: string, decodedToken?: any): Promise<boolean> {
  // Custom-claim check
  let hasClaim = false
  if (decodedToken && typeof decodedToken === 'object' && decodedToken.admin === true) {
    hasClaim = true
  } else {
    try {
      const userRecord = await adminAuth.getUser(uid)
      const claims = userRecord.customClaims as Record<string, unknown> | undefined
      hasClaim = claims?.admin === true
    } catch (err: any) {
      const errStr = String(err?.message ?? err)
      if (errStr.includes('https.request') || errStr.includes('unenv')) {
        hasClaim = decodedToken?.admin === true
      } else {
        throw err
      }
    }
  }

  if (!hasClaim) return false

  // Firestore document check (belt-and-suspenders)
  if (process.env.SKIP_FIRESTORE_ADMIN_CHECK === 'true') return true
  return await platformAdminDocExistsViaRest(uid)
}
