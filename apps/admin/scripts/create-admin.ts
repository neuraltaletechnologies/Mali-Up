/**
 * Bootstrap script — creates the very first admin user when none exists yet.
 * For every subsequent admin, prefer `pnpm run provision:admin` (set-admin-claim.ts),
 * which only grants the claim to an already-existing Firebase Auth user.
 *
 * Usage:
 *   pnpm exec tsx --env-file=.env.local scripts/create-admin.ts --email you@example.com
 *   pnpm exec tsx --env-file=.env.local scripts/create-admin.ts --email you@example.com --password 'a-strong-password'
 *
 * If --password is omitted, a random one is generated and printed once — sign
 * in immediately and change it, since it is not stored anywhere after this
 * process exits.
 */

import 'dotenv/config'
import crypto from 'crypto'
import admin from 'firebase-admin'

const projectId     = process.env.FIREBASE_PROJECT_ID ?? 'neuraltale-mali-up'
const clientEmail   = process.env.FIREBASE_CLIENT_EMAIL
const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY

if (!clientEmail || !rawPrivateKey) {
  console.error(
    '\nMissing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY in .env.local\n'
  )
  process.exit(1)
}

const args = process.argv.slice(2)
const emailFlag = args.indexOf('--email')
const passwordFlag = args.indexOf('--password')

if (emailFlag === -1 || !args[emailFlag + 1]) {
  console.error(
    '\nUsage:\n' +
    '  pnpm exec tsx --env-file=.env.local scripts/create-admin.ts --email you@example.com [--password <password>]\n'
  )
  process.exit(1)
}

const EMAIL = args[emailFlag + 1]
const PASS = passwordFlag !== -1 && args[passwordFlag + 1]
  ? args[passwordFlag + 1]
  : crypto.randomBytes(18).toString('base64url')
const generatedPassword = passwordFlag === -1

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

const authClient = admin.auth()
const db         = admin.firestore()

async function run() {
  let uid: string

  try {
    const existing = await authClient.getUserByEmail(EMAIL)
    uid = existing.uid
    console.log('User already exists, uid:', uid)
  } catch {
    const created = await authClient.createUser({
      email:         EMAIL,
      password:      PASS,
      emailVerified: true,
    })
    uid = created.uid
    console.log('Created user, uid:', uid)
  }

  const existing = await authClient.getUser(uid)
  const claims   = (existing.customClaims ?? {}) as Record<string, unknown>
  await authClient.setCustomUserClaims(uid, { ...claims, admin: true })

  await db.collection('platform_admins').doc(uid).set({
    uid,
    email:       EMAIL,
    grantedAt:   admin.firestore.FieldValue.serverTimestamp(),
    grantedBy:   'create-admin-script',
  }, { merge: true })

  console.log('\n✓ Admin access granted')
  console.log('  Email: ', EMAIL)
  console.log('  UID:   ', uid)
  if (generatedPassword) {
    console.log('  Password (generated, shown once — change it after first sign-in):', PASS)
  }
  console.log('\nSign in at http://localhost:3001/login\n')
}

run().catch((err) => {
  console.error('Failed:', err.message)
  process.exit(1)
})
