import admin from 'firebase-admin'
import { createRemoteJWKSet, jwtVerify } from 'jose'

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
// `globalThis.navigator?.userAgent === 'Cloudflare-Workers'` alone is NOT
// reliable here: under this OpenNext build it did not match in production,
// preferRest silently never got applied, Firestore fell back to gRPC, and
// every admin-check Firestore read threw deep inside protobufjs schema
// resolution (Codegen/Type.resolveAll/Namespace.resolveAll) — which
// isAdminUser() has no special handling for, so it propagated up and made
// every admin login fail with "no admin access" regardless of the account's
// actual claim/Firestore-doc state. CF_WORKER is an explicit [vars] entry in
// wrangler.toml (populated into process.env via nodejs_compat_populate_process_env)
// and is therefore deterministic, unlike sniffing a runtime global.
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
  const doc = await adminFirestore.collection('platform_admins').doc(uid).get()
  return doc.exists
}
