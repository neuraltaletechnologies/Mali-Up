/**
 * Provisioning script — run once per admin user you want to grant access to.
 *
 * Usage:
 *   pnpm run provision:admin --email user@example.com
 *   pnpm run provision:admin --uid abc123
 *
 * Prerequisites:
 *   - .env.local must contain FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL,
 *     and FIREBASE_PRIVATE_KEY (or GOOGLE_APPLICATION_CREDENTIALS must be set)
 *   - The user must already exist in Firebase Authentication
 *
 * What this does:
 *   1. Looks up the user by email or UID
 *   2. Sets { admin: true } as a custom claim on their Firebase Auth record
 *   3. Creates a /platform_admins/{uid} document in Firestore as a second gate
 */

import 'dotenv/config'
import admin from 'firebase-admin'

const projectId      = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const clientEmail    = process.env.FIREBASE_CLIENT_EMAIL
const rawPrivateKey  = process.env.FIREBASE_PRIVATE_KEY

if (!clientEmail || !rawPrivateKey) {
  console.error(
    '\nMissing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY in .env.local\n' +
    'Download a service account key from:\n' +
    '  Firebase Console → Project settings → Service accounts → Generate new private key\n'
  )
  process.exit(1)
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: rawPrivateKey.replace(/\\n/g, '\n'),
    }),
    projectId,
  })
}

const authClient      = admin.auth()
const firestoreClient = admin.firestore()

async function grantAdminAccess(identifier: string, byEmail: boolean) {
  let userRecord: admin.auth.UserRecord

  if (byEmail) {
    userRecord = await authClient.getUserByEmail(identifier)
  } else {
    userRecord = await authClient.getUser(identifier)
  }

  const { uid, email, displayName } = userRecord

  // 1. Set custom claim
  const existingClaims = (userRecord.customClaims ?? {}) as Record<string, unknown>
  await authClient.setCustomUserClaims(uid, { ...existingClaims, admin: true })

  // 2. Create Firestore document
  await firestoreClient.collection('platform_admins').doc(uid).set({
    uid,
    email:       email ?? null,
    displayName: displayName ?? null,
    grantedAt:   admin.firestore.FieldValue.serverTimestamp(),
    grantedBy:   'provisioning-script',
  }, { merge: true })

  console.log(`\n✓ Admin access granted`)
  console.log(`  UID:   ${uid}`)
  console.log(`  Email: ${email ?? '(no email)'}`)
  console.log(`  Name:  ${displayName ?? '(no display name)'}`)
  console.log(`\nThe user must sign out and back in for the new claim to take effect.\n`)
}

async function revokeAdminAccess(identifier: string, byEmail: boolean) {
  let userRecord: admin.auth.UserRecord

  if (byEmail) {
    userRecord = await authClient.getUserByEmail(identifier)
  } else {
    userRecord = await authClient.getUser(identifier)
  }

  const { uid } = userRecord
  const existingClaims = { ...(userRecord.customClaims ?? {}) } as Record<string, unknown>
  delete existingClaims['admin']
  await authClient.setCustomUserClaims(uid, existingClaims)
  await authClient.revokeRefreshTokens(uid)

  await firestoreClient.collection('platform_admins').doc(uid).delete()

  console.log(`\n✓ Admin access revoked for UID: ${uid}\n`)
}

// ─── Argument parsing ──────────────────────────────────────────────────────────

const args = process.argv.slice(2)
const emailFlag  = args.indexOf('--email')
const uidFlag    = args.indexOf('--uid')
const revokeFlag = args.includes('--revoke')

let identifier: string
let byEmail: boolean

if (emailFlag !== -1 && args[emailFlag + 1]) {
  identifier = args[emailFlag + 1]
  byEmail = true
} else if (uidFlag !== -1 && args[uidFlag + 1]) {
  identifier = args[uidFlag + 1]
  byEmail = false
} else {
  console.error(
    '\nUsage:\n' +
    '  pnpm run provision:admin --email user@example.com\n' +
    '  pnpm run provision:admin --uid <firebase-uid>\n' +
    '  pnpm run provision:admin --email user@example.com --revoke\n'
  )
  process.exit(1)
}

const action = revokeFlag
  ? revokeAdminAccess(identifier, byEmail)
  : grantAdminAccess(identifier, byEmail)

action.catch((err) => {
  console.error('\nFailed:', err.message ?? err)
  process.exit(1)
})
