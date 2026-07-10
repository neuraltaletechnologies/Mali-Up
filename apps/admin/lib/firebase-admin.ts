import admin from 'firebase-admin'

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
try {
  // This app runs on Cloudflare Workers (via OpenNext), which doesn't support
  // the long-lived gRPC/HTTP2 streams the Firestore SDK uses by default —
  // falling back to plain HTTP REST avoids multi-second stalls/retries on
  // every query. Must be set before any other Firestore call.
  adminFirestore.settings({ preferRest: true })
} catch (err) {
  if (!(err instanceof Error && err.message.includes('already been initialized'))) {
    throw err
  }
}

export const adminStorage = admin.storage(adminApp).bucket('neuraltale-mali-up.firebasestorage.app')

/**
 * Verify a Firebase ID token and return the decoded claims.
 * Throws if the token is invalid or expired.
 */
export async function verifyIdToken(idToken: string) {
  return adminAuth.verifyIdToken(idToken, /* checkRevoked= */ true)
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
export async function isAdminUser(uid: string): Promise<boolean> {
  // Custom-claim check
  const userRecord = await adminAuth.getUser(uid)
  const claims = userRecord.customClaims as Record<string, unknown> | undefined
  if (claims?.admin !== true) return false

  // Firestore document check (belt-and-suspenders)
  if (process.env.SKIP_FIRESTORE_ADMIN_CHECK === 'true') return true
  const doc = await adminFirestore.collection('platform_admins').doc(uid).get()
  return doc.exists
}
