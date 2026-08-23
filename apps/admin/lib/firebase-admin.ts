import admin from 'firebase-admin'
import { createRemoteJWKSet, jwtVerify } from 'jose'
import { restFirestore } from './firestore-rest'

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
export const adminStorage = admin.storage(adminApp).bucket('neuraltale-mali-up.firebasestorage.app')

// NOTE: there is deliberately no `adminFirestore` export here anymore.
// @google-cloud/firestore (the SDK backing admin.firestore()) always routes
// reads/writes through protobufjs to compile message encoders/decoders
// (visible in error stacks as Codegen/Type.resolveAll/Namespace.resolveAll),
// and protobufjs does that with `new Function(source)` — dynamic code-eval
// that Cloudflare Workers' V8 isolates block outright, with no compatibility
// flag to opt back in. That's true for gRPC *and* REST transport, so no
// `.settings()` on that SDK can fix it. Every Firestore read/write in this
// app now goes through `./firestore-rest`'s plain-fetch REST client instead
// — see that file for the full explanation and the supported API surface.

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
  const doc = await restFirestore.collection('platform_admins').doc(uid).get()
  return doc.exists
}
